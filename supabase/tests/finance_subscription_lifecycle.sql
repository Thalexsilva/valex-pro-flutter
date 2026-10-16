-- Run as postgres after migrations. All fixtures are rolled back.
begin;
select set_config('valex_test.trainer', gen_random_uuid()::text, true);
select set_config('valex_test.other_trainer', gen_random_uuid()::text, true);
select set_config('valex_test.student', gen_random_uuid()::text, true);
select set_config('valex_test.plan_a', gen_random_uuid()::text, true);
select set_config('valex_test.plan_b', gen_random_uuid()::text, true);
select set_config('valex_test.subscription', gen_random_uuid()::text, true);
select set_config('valex_test.invoice', gen_random_uuid()::text, true);

insert into auth.users (id) values
  (current_setting('valex_test.trainer')::uuid),
  (current_setting('valex_test.other_trainer')::uuid);
insert into public.students (id, trainer_id, name) values
  (current_setting('valex_test.student')::uuid,
   current_setting('valex_test.trainer')::uuid, 'Lifecycle fixture');
insert into public.plans (id, trainer_id, name, type, price, interval) values
  (current_setting('valex_test.plan_a')::uuid,
   current_setting('valex_test.trainer')::uuid, 'Monthly', 'subscription', 100, 'Mensal'),
  (current_setting('valex_test.plan_b')::uuid,
   current_setting('valex_test.trainer')::uuid, 'Quarterly', 'subscription', 250, 'Trimestral');
insert into public.subscriptions (
  id, trainer_id, student_id, plan_id, status, contracted_value, cycle, auto_renew
) values (
  current_setting('valex_test.subscription')::uuid,
  current_setting('valex_test.trainer')::uuid,
  current_setting('valex_test.student')::uuid,
  current_setting('valex_test.plan_a')::uuid,
  'active', 100, 'Mensal', true
);
insert into public.invoices (
  id, trainer_id, student_id, subscription_id, plan_id, type,
  plan_snapshot, student_snapshot, original_amount, final_amount, due_date,
  status
) values (
  current_setting('valex_test.invoice')::uuid,
  current_setting('valex_test.trainer')::uuid,
  current_setting('valex_test.student')::uuid,
  current_setting('valex_test.subscription')::uuid,
  current_setting('valex_test.plan_a')::uuid,
  'subscription', '{"name":"Monthly"}', '{"name":"Lifecycle fixture"}',
  100, 100, current_date, 'pending'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('valex_test.trainer'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.trainer'), 'role', 'authenticated')::text, true);

do $$
begin
  begin
    perform public.finance_apply_operation('create_subscription', jsonb_build_object(
      'studentId', current_setting('valex_test.student'),
      'planId', current_setting('valex_test.plan_b'),
      'amount', 250, 'startDate', current_date
    ));
    raise exception 'FAIL: duplicate active subscription accepted';
  exception when unique_violation then null;
  end;
end $$;

select public.finance_apply_operation('change_subscription_plan', jsonb_build_object(
  'subscriptionId', current_setting('valex_test.subscription'),
  'planId', current_setting('valex_test.plan_b')
));
select public.finance_apply_operation('change_subscription_plan', jsonb_build_object(
  'subscriptionId', current_setting('valex_test.subscription'),
  'planId', current_setting('valex_test.plan_b')
));
select public.finance_apply_operation('cancel_subscription', jsonb_build_object(
  'subscriptionId', current_setting('valex_test.subscription')
));
select public.finance_apply_operation('cancel_subscription', jsonb_build_object(
  'subscriptionId', current_setting('valex_test.subscription')
));

do $$
begin
  if not exists (
    select 1 from public.subscriptions
    where id = current_setting('valex_test.subscription')::uuid
      and plan_id = current_setting('valex_test.plan_b')::uuid
      and contracted_value = 250 and cycle = 'Trimestral'
      and status = 'cancelled' and auto_renew = false
  ) then
    raise exception 'FAIL: final subscription state';
  end if;
  if not exists (
    select 1 from public.invoices
    where id = current_setting('valex_test.invoice')::uuid
      and plan_id = current_setting('valex_test.plan_a')::uuid
      and original_amount = 100 and status = 'pending'
  ) then
    raise exception 'FAIL: prior invoice was rewritten';
  end if;
  if (select count(*) from public.subscription_history
      where subscription_id = current_setting('valex_test.subscription')::uuid) <> 2 then
    raise exception 'FAIL: transition history missing or duplicated';
  end if;
end $$;

rollback;
