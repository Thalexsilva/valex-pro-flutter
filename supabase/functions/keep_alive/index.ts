// Supabase Edge Function: Keep-Alive Service
// Endpoint estrito com Fonte Unica de Segredo Server-Side (sem Vault, sem RPC, sem Anon Key)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Comparacao timing-safe de strings via SHA-256 para evitar side-channel timing attacks
async function timingSafeEqual(a: string, b: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const aBuf = await crypto.subtle.digest('SHA-256', encoder.encode(a));
  const bBuf = await crypto.subtle.digest('SHA-256', encoder.encode(b));
  const aBytes = new Uint8Array(aBuf);
  const bBytes = new Uint8Array(bBuf);

  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff === 0;
}

serve(async (req: Request) => {
  // 1. Restricao Estrita de Metodo HTTP: Apenas GET e permitido
  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ ok: false }),
      { status: 405, headers: { 'Content-Type': 'application/json', 'Allow': 'GET' } }
    );
  }

  try {
    // 2. Conexao Server-side Segura com Service Role (Fail-closed se ausente)
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      console.error('keep_alive configuration error: missing service role key or supabase url');
      return new Response(
        JSON.stringify({ ok: false }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 3. Obter Token Esperado EXCLUSIVAMENTE do Ambiente Edge Secret (Fonte Unica Server-Side)
    const expectedToken = Deno.env.get('VALEX_KEEPALIVE_TOKEN');

    if (!expectedToken) {
      console.error('keep_alive configuration error: missing VALEX_KEEPALIVE_TOKEN environment secret');
      return new Response(
        JSON.stringify({ ok: false }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 4. Autenticacao Estrita via Header 'x-keepalive-token' com comparacao timing-safe (prevencao de ataque de tempo)
    const incomingToken = req.headers.get('x-keepalive-token');
    if (!incomingToken || !(await timingSafeEqual(incomingToken, expectedToken))) {
      return new Response(
        JSON.stringify({ ok: false }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // 5. Consulta Read-only minima ao Postgres (head: true nao transfere dados)
    const { error } = await supabase
      .from('students')
      .select('id', { count: 'exact', head: true });

    if (error) {
      console.error('keep_alive database query error');
      return new Response(
        JSON.stringify({ ok: false }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Log sanitizado sem expor segredos ou metadados
    console.log("keep_alive database query: success");

    // 6. Resposta Sanitizada de Sucesso
    return new Response(
      JSON.stringify({ ok: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (_err) {
    return new Response(
      JSON.stringify({ ok: false }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
