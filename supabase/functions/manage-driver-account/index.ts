// Supabase Edge Function: manage-driver-account
// Allows an active branch_manager to create, activate/suspend, and reset
// passwords for driver accounts in their own branch — without signing out.
//
// Deploy with: supabase functions deploy manage-driver-account
// Required env vars (auto-provided by Supabase): SUPABASE_URL,
//   SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const respond = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return respond({ error: "Missing Authorization header" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Verify the caller's JWT
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) return respond({ error: "Unauthorized" }, 401);

    // Admin client for all privileged operations
    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Fetch the manager's row from public.users
    const { data: mgr, error: mgrErr } = await admin
      .from("users")
      .select("role, branch_id, account_status")
      .eq("id", user.id)
      .single();
    if (mgrErr || !mgr) return respond({ error: "Manager profile not found" }, 403);
    if (mgr.role !== "branch_manager" || mgr.account_status !== "active") {
      return respond({ error: "Forbidden: only active branch managers can call this function" }, 403);
    }
    const branchId: string = mgr.branch_id;
    if (!branchId) return respond({ error: "Manager has no branch assigned" }, 400);

    const body = await req.json();
    const { action } = body as { action: string };

    // ── CREATE ────────────────────────────────────────────────────────────
    if (action === "create") {
      const { name, email, phone, password } = body as {
        name: string;
        email: string;
        phone?: string;
        password: string;
      };
      if (!name || !email || !password) {
        return respond({ error: "name, email, and password are required" }, 400);
      }
      if (password.length < 6) {
        return respond({ error: "Password must be at least 6 characters" }, 400);
      }

      // Create auth user — handle_new_user trigger will insert into public.users
      const { data: created, error: createErr } = await admin.auth.admin.createUser({
        email,
        password,
        user_metadata: { name, phone: phone ?? "", role: "driver" },
        email_confirm: true,
      });
      if (createErr) return respond({ error: createErr.message }, 400);

      const driverId = created.user!.id;

      // Small delay so the trigger row is ready before we update it
      await new Promise((r) => setTimeout(r, 600));

      // Set branch, activate immediately, and flag password change
      const { error: updErr } = await admin
        .from("users")
        .update({
          branch_id: branchId,
          account_status: "active",
          requires_password_change: true,
        })
        .eq("id", driverId);

      if (updErr) {
        // Best-effort rollback
        await admin.auth.admin.deleteUser(driverId);
        return respond({ error: updErr.message }, 500);
      }

      return respond({ success: true, userId: driverId });
    }

    // ── UPDATE STATUS (activate / suspend) ───────────────────────────────
    if (action === "update_status") {
      const { driverId, status } = body as { driverId: string; status: string };
      if (!driverId || !["active", "suspended"].includes(status)) {
        return respond({ error: "driverId and status (active|suspended) required" }, 400);
      }

      // Verify driver belongs to this branch
      const { data: drv, error: drvErr } = await admin
        .from("users")
        .select("role, branch_id")
        .eq("id", driverId)
        .single();
      if (drvErr || drv?.role !== "driver" || drv?.branch_id !== branchId) {
        return respond({ error: "Driver not found in your branch" }, 403);
      }

      const { error: updErr } = await admin
        .from("users")
        .update({ account_status: status })
        .eq("id", driverId);
      if (updErr) return respond({ error: updErr.message }, 500);

      return respond({ success: true });
    }

    // ── RESET PASSWORD ────────────────────────────────────────────────────
    if (action === "reset_password") {
      const { driverId, newPassword } = body as {
        driverId: string;
        newPassword: string;
      };
      if (!driverId || !newPassword || newPassword.length < 6) {
        return respond(
          { error: "driverId and newPassword (≥6 chars) required" },
          400,
        );
      }

      // Verify driver belongs to this branch
      const { data: drv, error: drvErr } = await admin
        .from("users")
        .select("role, branch_id")
        .eq("id", driverId)
        .single();
      if (drvErr || drv?.role !== "driver" || drv?.branch_id !== branchId) {
        return respond({ error: "Driver not found in your branch" }, 403);
      }

      const { error: resetErr } = await admin.auth.admin.updateUserById(
        driverId,
        { password: newPassword },
      );
      if (resetErr) return respond({ error: resetErr.message }, 500);

      const { error: flagErr } = await admin
        .from("users")
        .update({ requires_password_change: true })
        .eq("id", driverId);
      if (flagErr) return respond({ error: flagErr.message }, 500);

      return respond({ success: true });
    }

    return respond({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    return respond({ error: String(err) }, 500);
  }
});
