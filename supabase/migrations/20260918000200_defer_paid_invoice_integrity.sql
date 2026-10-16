-- Payment and invoice status are written in one transaction. Validate the
-- cross-table invariant at transaction end, after both records exist.

drop trigger if exists trigger_check_paid_invoice_has_payment
  on public.invoices;

create constraint trigger trigger_check_paid_invoice_has_payment
after insert or update of status on public.invoices
deferrable initially deferred
for each row
execute function public.check_paid_invoice_has_payment();
