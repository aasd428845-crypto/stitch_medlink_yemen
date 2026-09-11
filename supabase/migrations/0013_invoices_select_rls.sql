drop policy if exists "invoices_branch_manager_select" on public.invoices;
create policy "invoices_branch_manager_select" on public.invoices
  for select
  using (
    public.current_user_role() = 'branch_manager'
    and branch_id = public.current_user_branch_id()
  );

</content>