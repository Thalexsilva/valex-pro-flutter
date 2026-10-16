import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Content-Type": "application/json",
};

function response(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers });
}

function limited(value: unknown, maxLength: number): string | null {
  return typeof value === "string" && value.trim()
    ? value.trim().slice(0, maxLength)
    : null;
}

function clientIp(request: Request): string | null {
  const candidate = request.headers.get("cf-connecting-ip") ??
    request.headers.get("x-real-ip") ??
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  if (!candidate) return null;
  const ipv4 = candidate.split(".");
  if (
    ipv4.length === 4 &&
    ipv4.every((part) => /^\d{1,3}$/.test(part) && Number(part) <= 255)
  ) {
    return candidate;
  }
  if (
    (candidate.match(/:/g)?.length ?? 0) >= 2 &&
    /^[0-9a-f:.]+$/i.test(candidate) && candidate.length <= 45
  ) {
    try {
      new URL(`http://[${candidate}]/`);
      return candidate;
    } catch {
      return null;
    }
  }
  return null;
}

async function networkLocation(request: Request) {
  // The client body never chooses the IP or location. Gateway geo headers may
  // be absent, so resolve the network IP through a short server-side lookup.
  const ip = clientIp(request);
  const fallback = {
    ip_address: ip,
    city: limited(request.headers.get("cf-ipcity"), 100),
    region: limited(request.headers.get("cf-region"), 100),
    country: limited(request.headers.get("cf-ipcountry"), 2),
  };
  if (!ip) return fallback;
  try {
    const result = await fetch(`https://ipwho.is/${encodeURIComponent(ip)}`, {
      signal: AbortSignal.timeout(1800),
      redirect: "error",
    });
    if (!result.ok) return fallback;
    const geo = await result.json();
    if (geo?.success !== true) return fallback;
    return {
      ...fallback,
      city: limited(geo.city, 100) ?? fallback.city,
      region: limited(geo.region, 100) ?? fallback.region,
      country: limited(geo.country_code, 2) ?? fallback.country,
    };
  } catch {
    return fallback;
  }
}

serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") {
    return response(405, { error: "Método inválido." });
  }

  const token = request.headers.get("authorization")?.replace(
    /^Bearer\s+/i,
    "",
  );
  if (!token) return response(401, { error: "Sessão ausente." });

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceKey) {
    return response(503, { error: "Serviço indisponível." });
  }

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: identity, error: authError } = await userClient.auth.getUser(
    token,
  );
  if (authError || !identity.user) {
    return response(401, { error: "Sessão inválida." });
  }

  const signInAt = Date.parse(identity.user.last_sign_in_at ?? "");
  const ageMs = Date.now() - signInAt;
  if (!Number.isFinite(signInAt) || ageMs < -60_000 || ageMs > 5 * 60_000) {
    return response(409, {
      error: "Este acesso não corresponde a um login recente.",
    });
  }

  const { data: student, error: studentError } = await userClient
    .from("students")
    .select("id, trainer_id")
    .eq("student_user_id", identity.user.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();
  if (studentError) {
    return response(500, { error: "Falha ao localizar aluno." });
  }
  if (!student) return response(403, { error: "Aluno não vinculado." });

  let body: Record<string, unknown> = {};
  try {
    body = await request.json();
  } catch {
    return response(400, { error: "Dados inválidos." });
  }

  const admin = createClient(url, serviceKey);
  const authSignInAt = new Date(signInAt).toISOString();
  const { data: existing, error: existingError } = await admin
    .from("student_login_events")
    .select("id")
    .eq("student_user_id", identity.user.id)
    .eq("auth_sign_in_at", authSignInAt)
    .maybeSingle();
  if (existingError) {
    return response(500, { error: "Falha ao consultar acesso." });
  }
  if (existing) return response(200, { recorded: false });

  const { error } = await admin.from("student_login_events").insert({
    student_id: student.id,
    trainer_id: student.trainer_id,
    student_user_id: identity.user.id,
    auth_sign_in_at: authSignInAt,
    ...await networkLocation(request),
    platform: limited(body.platform, 30),
    time_zone: limited(body.time_zone, 80),
  });
  if (error?.code === "23505") return response(200, { recorded: false });
  if (error) {
    return response(500, { error: "Não foi possível registrar o acesso." });
  }
  return response(200, { recorded: true });
});
