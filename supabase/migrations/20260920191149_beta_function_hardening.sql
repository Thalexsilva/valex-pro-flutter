-- Preserve trigger behavior while removing public access to administration.
alter function public.check_paid_invoice_has_payment()
  set search_path = public, pg_temp;

-- rls_auto_enable() is installed by the hosted project; local stacks may not have it.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    revoke execute on function public.rls_auto_enable()
      from public, anon, authenticated;
  end if;
end
$$;
