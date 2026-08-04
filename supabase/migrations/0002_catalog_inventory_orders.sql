-- =============================================================
-- Migration 0002: Catalog · Inventory · Orders
-- نفِّذ هذا الملف من Supabase Dashboard → SQL Editor
-- لا تعدّل ملف 0001 أو 0003
-- =============================================================

-- ─────────────────────────────────────────
-- 1. جدول المنتجات (كتالوج مركزي موحّد)
-- ─────────────────────────────────────────
create table if not exists public.products (
  id           uuid        primary key default gen_random_uuid(),
  name         text        not null,
  name_en      text,
  description  text,
  category     text        not null,
  manufacturer text,
  dosage_form  text,
  unit         text        not null default 'علبة',
  unit_price   numeric(10,2) not null,
  image_url    text,
  is_active    boolean     not null default true,
  created_at   timestamptz not null default now()
);

alter table public.products enable row level security;

-- أي مستخدم مُصادَق عليه يقرأ المنتجات النشطة
create policy "products_select_active_authenticated" on public.products
  for select using (is_active = true and auth.role() = 'authenticated');

-- فقط المدير العام يُنشئ / يُعدّل / يحذف
create policy "products_director_manage" on public.products
  for all using (public.current_user_role() = 'company_director');

-- ─────────────────────────────────────────
-- 2. جدول المخزون (كمية لكل فرع × منتج)
-- ─────────────────────────────────────────
create table if not exists public.inventory (
  id         uuid        primary key default gen_random_uuid(),
  branch_id  uuid        not null references public.branches(id)  on delete cascade,
  product_id uuid        not null references public.products(id)  on delete cascade,
  quantity   int         not null default 0 check (quantity >= 0),
  updated_at timestamptz not null default now(),
  unique (branch_id, product_id)
);

alter table public.inventory enable row level security;

-- العملاء يرون المخزون (بدون كميات تفصيلية)؛ المدير ومدير الفرع يرون كل شيء
create policy "inventory_select_authenticated" on public.inventory
  for select using (auth.role() = 'authenticated');

create policy "inventory_branch_manager_update" on public.inventory
  for update using (
    public.current_user_role() in ('branch_manager', 'company_director')
    and (
      public.current_user_role() = 'company_director'
      or branch_id = public.current_user_branch_id()
    )
  );

create policy "inventory_director_insert_delete" on public.inventory
  for all using (public.current_user_role() = 'company_director');

-- ─────────────────────────────────────────
-- 3. جدول العروض الترويجية
-- ─────────────────────────────────────────
create table if not exists public.promotional_offers (
  id                 uuid        primary key default gen_random_uuid(),
  title              text        not null,
  description        text,
  image_url          text,
  discount_text      text,
  start_date         date,
  end_date           date,
  target_governorate text,
  is_active          boolean     not null default true,
  created_at         timestamptz not null default now()
);

alter table public.promotional_offers enable row level security;

create policy "offers_select_active" on public.promotional_offers
  for select using (
    (is_active = true and auth.role() = 'authenticated')
    or public.current_user_role() = 'company_director'
  );

create policy "offers_director_manage" on public.promotional_offers
  for all using (public.current_user_role() = 'company_director');

-- ─────────────────────────────────────────
-- 4. جدول عناوين العميل
-- ─────────────────────────────────────────
create table if not exists public.client_addresses (
  id           uuid        primary key default gen_random_uuid(),
  client_id    uuid        not null references public.users(id) on delete cascade,
  label        text        not null,
  address_text text        not null,
  latitude     double precision,
  longitude    double precision,
  is_default   boolean     not null default false,
  created_at   timestamptz not null default now()
);

alter table public.client_addresses enable row level security;

create policy "addresses_select_own" on public.client_addresses
  for select using (
    client_id = auth.uid()
    or public.current_user_role() in ('branch_manager', 'company_director', 'driver')
  );

create policy "addresses_insert_own" on public.client_addresses
  for insert with check (client_id = auth.uid());

create policy "addresses_update_own" on public.client_addresses
  for update using (client_id = auth.uid());

create policy "addresses_delete_own" on public.client_addresses
  for delete using (client_id = auth.uid());

-- ─────────────────────────────────────────
-- 5. جدول الطلبات
-- ─────────────────────────────────────────
create table if not exists public.orders (
  id                    uuid          primary key default gen_random_uuid(),
  client_id             uuid          not null references public.users(id),
  branch_id             uuid          references public.branches(id),
  parent_order_id       uuid          references public.orders(id),
  target_branches       uuid[],
  status                text          not null default 'pending'
    check (status in ('pending','assigned','in_progress','delivered','cancelled')),
  delivery_address_id   uuid          references public.client_addresses(id),
  assigned_driver_id    uuid          references public.users(id),
  total_amount          numeric(10,2) not null default 0,
  scheduled_delivery_at timestamptz,
  notes                 text,
  created_at            timestamptz   not null default now()
);

alter table public.orders enable row level security;

-- العميل يرى طلباته فقط
create policy "orders_client_select" on public.orders
  for select using (
    client_id = auth.uid()
    or public.current_user_role() in ('branch_manager', 'company_director')
    or assigned_driver_id = auth.uid()
  );

create policy "orders_client_insert" on public.orders
  for insert with check (client_id = auth.uid());

-- مدير الفرع والمدير العام يُعدّلون
create policy "orders_manager_update" on public.orders
  for update using (
    public.current_user_role() in ('branch_manager', 'company_director')
    or assigned_driver_id = auth.uid()
  );

-- ─────────────────────────────────────────
-- 6. جدول بنود الطلب
-- ─────────────────────────────────────────
create table if not exists public.order_items (
  id         uuid          primary key default gen_random_uuid(),
  order_id   uuid          not null references public.orders(id)   on delete cascade,
  product_id uuid          not null references public.products(id),
  quantity   int           not null check (quantity > 0),
  unit_price numeric(10,2) not null,
  is_bonus   boolean       not null default false,
  created_at timestamptz   not null default now()
);

alter table public.order_items enable row level security;

create policy "order_items_select" on public.order_items
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (
          o.client_id = auth.uid()
          or public.current_user_role() in ('branch_manager', 'company_director')
          or o.assigned_driver_id = auth.uid()
        )
    )
  );

create policy "order_items_insert" on public.order_items
  for insert with check (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.client_id = auth.uid()
    )
  );
