import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-trainer-id',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const jsonResponse = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  try {
    const authorization = req.headers.get('Authorization');
    if (!authorization) {
      return jsonResponse({ error: 'Autenticação obrigatória.' }, 401);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authorization } } },
    );
    const token = authorization.replace(/^Bearer\s+/i, '');
    const { data: authData, error: authError } = await supabase.auth.getUser(token);
    if (authError || !authData.user) {
      return jsonResponse({ error: 'Sessão inválida ou expirada.' }, 401);
    }

    const claimedTrainer = req.headers.get('x-trainer-id');
    if (claimedTrainer && claimedTrainer !== authData.user.id) {
      return jsonResponse({ error: 'Treinador não autorizado.' }, 403);
    }

    const body = await req.json();
    const action = typeof body?.action === 'string' ? body.action : '';
    const payload = body?.payload && typeof body.payload === 'object'
      ? body.payload
      : {};
    if (!action) {
      return jsonResponse({ error: 'Ação financeira ausente.' }, 400);
    }

    const { data, error } = await supabase.rpc('finance_apply_operation', {
      p_action: action,
      p_payload: payload,
    });
    if (error) {
      return jsonResponse({ error: error.message }, 400);
    }

    return jsonResponse({ success: true, action, result: data }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Erro interno';
    return jsonResponse({ error: message }, 500);
  }
});
