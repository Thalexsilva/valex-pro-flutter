-- Atomic, tenant-scoped mutations used by the Flutter finance module.

create or replace function public.finance_apply_operation(
  p_action text,
  p_payload jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_trainer uuid := auth.uid();
  v_id uuid;
  v_student_id uuid;
  v_plan_id uuid;
  v_invoice public.invoices%rowtype;
  v_payment public.payments%rowtype;
  v_discount numeric(10, 2);
  v_fine numeric(10, 2);
  v_interest numeric(10, 2);
  v_final numeric(10, 2);
begin
  if v_trainer is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if p_action = 'create_plan' then
    v_id := coalesce(nullif(p_payload->>'id', '')::uuid, gen_random_uuid());
    insert into public.plans (
      id, trainer_id, name, description, category, type, price, interval,
      active, status
    ) values (
      v_id,
      v_trainer,
      trim(p_payload->>'name'),
      coalesce(p_payload->>'description', ''),
      coalesce(p_payload->>'category', ''),
      p_payload->>'type',
      (p_payload->>'price')::numeric,
      coalesce(p_payload->>'interval', 'Mensal'),
      coalesce((p_payload->>'active')::boolean, true),
      coalesce(p_payload->>'status', 'active')
    );

  elsif p_action = 'create_subscription' then
    v_id := coalesce(nullif(p_payload->>'id', '')::uuid, gen_random_uuid());
    v_student_id := (p_payload->>'studentId')::uuid;
    v_plan_id := (p_payload->>'planId')::uuid;
    insert into public.subscriptions (
      id, trainer_id, student_id, plan_id, status, contracted_value,
      cycle, start_date, auto_renew
    )
    select
      v_id,
      v_trainer,
      student.id,
      plan.id,
      'active'::public.subscription_status,
      (p_payload->>'amount')::numeric,
      coalesce(p_payload->>'cycle', plan.interval, 'Mensal'),
      (p_payload->>'startDate')::date,
      coalesce((p_payload->>'autoRenew')::boolean, true)
    from public.students as student
    join public.plans as plan
      on plan.id = v_plan_id
     and plan.trainer_id = v_trainer
     and plan.active
     and plan.status = 'active'
     and plan.type = 'subscription'
    where student.id = v_student_id
      and student.trainer_id = v_trainer
      and student.status = 'active';
    if not found then
      raise exception 'STUDENT_OR_PLAN_NOT_FOUND' using errcode = 'P0002';
    end if;

  elsif p_action = 'create_invoice' then
    v_id := coalesce(nullif(p_payload->>'id', '')::uuid, gen_random_uuid());
    v_student_id := (p_payload->>'studentId')::uuid;
    v_plan_id := (p_payload->>'planId')::uuid;
    insert into public.invoices (
      id, trainer_id, student_id, plan_id, type, plan_snapshot,
      student_snapshot, original_amount, final_amount, due_date, status
    )
    select
      v_id,
      v_trainer,
      student.id,
      plan.id,
      plan.type,
      jsonb_build_object('id', plan.id, 'name', plan.name),
      jsonb_build_object('id', student.id, 'name', student.name),
      (p_payload->>'amount')::numeric,
      (p_payload->>'amount')::numeric,
      (p_payload->>'dueDate')::date,
      case
        when (p_payload->>'dueDate')::date < current_date
          then 'overdue'::public.invoice_status
        else 'pending'::public.invoice_status
      end
    from public.students as student
    join public.plans as plan
      on plan.id = v_plan_id
     and plan.trainer_id = v_trainer
     and plan.active
     and plan.status = 'active'
    where student.id = v_student_id
      and student.trainer_id = v_trainer
      and student.status = 'active';
    if not found then
      raise exception 'STUDENT_OR_PLAN_NOT_FOUND' using errcode = 'P0002';
    end if;

  elsif p_action = 'process_payment' then
    select * into v_invoice
    from public.invoices
    where id = (p_payload->>'invoiceId')::uuid
      and trainer_id = v_trainer
      and status in ('pending', 'overdue')
    for update;
    if not found then
      raise exception 'INVOICE_NOT_PAYABLE' using errcode = 'P0002';
    end if;

    v_discount := coalesce((p_payload->>'discount')::numeric, 0);
    v_fine := coalesce((p_payload->>'fine')::numeric, 0);
    v_interest := coalesce((p_payload->>'interest')::numeric, 0);
    v_final := v_invoice.original_amount - v_discount + v_fine + v_interest;
    if v_discount < 0 or v_fine < 0 or v_interest < 0 or v_final < 0 then
      raise exception 'INVALID_PAYMENT_AMOUNTS' using errcode = '22003';
    end if;

    update public.invoices
    set discount = v_discount,
        fine = v_fine,
        interest = v_interest,
        final_amount = v_final,
        status = 'paid',
        updated_at = now()
    where id = v_invoice.id and trainer_id = v_trainer;

    insert into public.payments (
      trainer_id, invoice_id, student_id, amount, payment_date,
      payment_method, status, notes
    ) values (
      v_trainer,
      v_invoice.id,
      v_invoice.student_id,
      v_final,
      coalesce(nullif(p_payload->>'paymentDate', '')::date, current_date),
      coalesce(nullif(p_payload->>'paymentMethod', ''), 'pix'),
      'confirmed',
      nullif(p_payload->>'notes', '')
    ) returning * into v_payment;

    insert into public.cash_flow (
      trainer_id, type, amount, date, category, description,
      reference_id, invoice_id
    ) values (
      v_trainer,
      'inflow',
      v_final,
      v_payment.payment_date,
      'Mensalidade',
      'Recebimento de fatura',
      v_payment.id,
      v_invoice.id
    );

  elsif p_action = 'refund_payment' then
    select invoice.* into v_invoice
    from public.invoices as invoice
    where invoice.id = (p_payload->>'invoiceId')::uuid
      and invoice.trainer_id = v_trainer
      and invoice.status = 'paid'
    for update;
    if not found then
      raise exception 'INVOICE_NOT_REFUNDABLE' using errcode = 'P0002';
    end if;

    select payment.* into v_payment
    from public.payments as payment
    where payment.invoice_id = v_invoice.id
      and payment.trainer_id = v_trainer
      and payment.status = 'confirmed'
    order by payment.created_at desc
    limit 1
    for update;
    if not found then
      raise exception 'PAYMENT_NOT_FOUND' using errcode = 'P0002';
    end if;

    update public.payments
    set status = 'refunded'
    where id = v_payment.id and trainer_id = v_trainer;

    update public.invoices
    set status = case
          when due_date < current_date then 'overdue'::public.invoice_status
          else 'pending'::public.invoice_status
        end,
        updated_at = now()
    where id = v_invoice.id and trainer_id = v_trainer;

    insert into public.cash_flow (
      trainer_id, type, amount, date, category, description,
      reference_id, invoice_id
    ) values (
      v_trainer,
      'outflow',
      v_payment.amount,
      current_date,
      'Estorno',
      'Estorno de pagamento',
      v_payment.id,
      v_invoice.id
    );

  elsif p_action = 'cancel_subscription' then
    update public.subscriptions
    set status = 'cancelled', updated_at = now()
    where id = (p_payload->>'subscriptionId')::uuid
      and trainer_id = v_trainer
      and status <> 'cancelled';
    if not found then
      raise exception 'SUBSCRIPTION_NOT_FOUND' using errcode = 'P0002';
    end if;

  else
    raise exception 'UNKNOWN_FINANCE_ACTION' using errcode = '22023';
  end if;

  return jsonb_build_object('success', true, 'action', p_action);
end;
$$;

revoke all on function public.finance_apply_operation(text, jsonb) from public;
revoke all on function public.finance_apply_operation(text, jsonb) from anon;
grant execute on function public.finance_apply_operation(text, jsonb) to authenticated;
