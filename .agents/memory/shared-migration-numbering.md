---
name: Shared migration numbering
description: The workspace contains a shared root migration history plus an app-local migration with a conflicting number.
---

The root `supabase/migrations/` history is authoritative for the shared database. The app-local migration folder contains a notification migration whose number is already used by a different root migration.

**Why:** Applying the app-local file as the next shared migration could create out-of-order or duplicate migration history and break synchronization between clients.

**How to apply:** Before any schema change, inspect the root migration sequence first, choose the next unused shared number, and keep Flutter consumers aligned. Do not apply the app-local duplicate as-is.