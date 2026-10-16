-- Migration: 20260810013019_0007_remove_keepalive_token_rpc.sql
-- Descricao: Remocao estrita de funcao RPC de fallback e segredos legados do keep-alive

drop function if exists public.get_keepalive_token();
