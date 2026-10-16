-- Dados FICTÍCIOS para o ambiente local (supabase start / supabase db reset).
-- Nenhuma informação real de alunos é usada aqui.
--
-- Conta de demonstração (somente no Supabase local):
--   e-mail: treinador@valex.local
--   senha : Valex@2026

create extension if not exists pgcrypto with schema extensions;

do $$
declare
  v_trainer uuid := 'a0000000-0000-4000-8000-000000000001';
  v_ana     uuid := 'b0000000-0000-4000-8000-000000000001';
  v_bruno   uuid := 'b0000000-0000-4000-8000-000000000002';
  v_camila  uuid := 'b0000000-0000-4000-8000-000000000003';
  v_diego   uuid := 'b0000000-0000-4000-8000-000000000004';
  v_eduarda uuid := 'b0000000-0000-4000-8000-000000000005';
  v_felipe  uuid := 'b0000000-0000-4000-8000-000000000006';
  v_gabriela uuid := 'b0000000-0000-4000-8000-000000000007';
  v_heitor  uuid := 'b0000000-0000-4000-8000-000000000008';
  v_plan_mensal uuid := 'c0000000-0000-4000-8000-000000000001';
  v_plan_trimestral uuid := 'c0000000-0000-4000-8000-000000000002';
  v_plan_online uuid := 'c0000000-0000-4000-8000-000000000003';
  v_month text := (array['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto',
                          'Setembro','Outubro','Novembro','Dezembro'])[extract(month from current_date)::int]
                   || '/' || to_char(current_date, 'YYYY');
begin
  -- Usuário treinador (Supabase Auth local)
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', v_trainer, 'authenticated', 'authenticated',
    'treinador@valex.local', extensions.crypt('Valex@2026', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Rafael Moreira","phone":"(16) 99876-5432"}',
    now() - interval '90 days', now(),
    '', '', '', '', '', '', '', ''
  );

  insert into auth.identities (
    provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    v_trainer::text, v_trainer,
    jsonb_build_object('sub', v_trainer::text, 'email', 'treinador@valex.local', 'email_verified', true),
    'email', now(), now(), now()
  );

  -- Alunos
  insert into public.students
    (id, trainer_id, name, date, teacher, status, phone, email, academia, mes,
     needs_reassessment, anamnese_pending, created_at, updated_at)
  values
    (v_ana, v_trainer, 'Ana Beatriz Souza', current_date - 60, 'Rafael Moreira', 'active',
     '(16) 99111-2233', 'ana.souza@exemplo.com', 'Academia Ribeirão Fit', v_month, false, false,
     now() - interval '60 days', now() - interval '2 days'),
    (v_bruno, v_trainer, 'Bruno Carvalho Lima', current_date - 45, 'Rafael Moreira', 'active',
     '(16) 99222-3344', 'bruno.lima@exemplo.com', 'Academia Ribeirão Fit', v_month, true, false,
     now() - interval '45 days', now() - interval '5 days'),
    (v_camila, v_trainer, 'Camila Ferreira Rocha', current_date - 38, 'Rafael Moreira', 'active',
     '(16) 99333-4455', 'camila.rocha@exemplo.com', 'Studio Movimento', v_month, false, true,
     now() - interval '38 days', now() - interval '1 day'),
    (v_diego, v_trainer, 'Diego Martins Alves', current_date - 30, 'Rafael Moreira', 'active',
     '(16) 99444-5566', 'diego.alves@exemplo.com', 'Academia Ribeirão Fit', v_month, false, false,
     now() - interval '30 days', now() - interval '3 days'),
    (v_eduarda, v_trainer, 'Eduarda Nogueira Prado', current_date - 21, 'Rafael Moreira', 'active',
     '(16) 99555-6677', 'eduarda.prado@exemplo.com', 'Studio Movimento', v_month, false, false,
     now() - interval '21 days', now() - interval '4 days'),
    (v_felipe, v_trainer, 'Felipe Andrade Costa', current_date - 14, 'Rafael Moreira', 'active',
     '(16) 99666-7788', 'felipe.costa@exemplo.com', 'Academia Ribeirão Fit', v_month, false, false,
     now() - interval '14 days', now() - interval '6 days'),
    (v_gabriela, v_trainer, 'Gabriela Teixeira Melo', current_date - 9, 'Rafael Moreira', 'active',
     '(16) 99777-8899', 'gabriela.melo@exemplo.com', 'Consultoria Online', v_month, false, true,
     now() - interval '9 days', now() - interval '1 day'),
    (v_heitor, v_trainer, 'Heitor Ramos Vieira', current_date - 120, 'Rafael Moreira', 'archived',
     '(16) 99888-9900', 'heitor.vieira@exemplo.com', 'Academia Ribeirão Fit', v_month, false, false,
     now() - interval '120 days', now() - interval '40 days');

  -- Fichas de treino
  insert into public.workout_sheets
    (trainer_id, student_id, student_name, gym_name, month, instructor_notes, status,
     days, cardio_options, general_notes, created_at, updated_at)
  values
    (v_trainer, v_ana, 'Ana Beatriz Souza', 'Academia Ribeirão Fit', v_month,
     'Foco em hipertrofia de membros inferiores. Evitar impacto no joelho esquerdo.', 'active',
     '[
       {"dow":"Treino A","muscle":"Quadríceps e Glúteos","exercises":[
         {"title":"Agachamento Livre","muscle":"Pernas","cue":"Joelhos alinhados com a ponta dos pés.","loadKg":"40","restSeconds":90,
          "sets":["[warm]Aquecimento: 15 reps","[work]Série de trabalho: 10-12 reps","[work]Série de trabalho: 10-12 reps","[work]Série de trabalho: 8-10 reps"]},
         {"title":"Leg Press 45°","muscle":"Pernas","cue":"Desça até 90° sem tirar o quadril do banco.","loadKg":"120","restSeconds":90,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]},
         {"title":"Elevação Pélvica","muscle":"Glúteos","cue":"Contraia o glúteo 1s no topo.","loadKg":"60","restSeconds":60,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps"]},
         {"title":"Cadeira Extensora","muscle":"Quadríceps","cue":"Controle a fase excêntrica.","loadKg":"35","restSeconds":60,
          "sets":["[work]Série de trabalho: 15 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]}
       ]},
       {"dow":"Treino B","muscle":"Costas e Bíceps","exercises":[
         {"title":"Puxada Frontal","muscle":"Costas","cue":"Leve a barra até a parte alta do peito.","loadKg":"35","restSeconds":75,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps","[work]Série de trabalho: 10 reps"]},
         {"title":"Remada Baixa","muscle":"Costas","cue":"Escápulas retraídas ao final.","loadKg":"30","restSeconds":75,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]},
         {"title":"Rosca Direta com Barra","muscle":"Bíceps","cue":"Cotovelos fixos ao lado do corpo.","loadKg":"12","restSeconds":60,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps","[work]Série de trabalho: 10 reps"]}
       ]},
       {"dow":"Treino C","muscle":"Peitoral, Ombros e Tríceps","exercises":[
         {"title":"Supino Reto com Barra","muscle":"Peito","cue":"Escápulas retraídas, descida controlada.","loadKg":"25","restSeconds":90,
          "sets":["[work]Série de trabalho: 10-12 reps","[work]Série de trabalho: 10-12 reps","[work]Série de trabalho: 8-10 reps"]},
         {"title":"Desenvolvimento com Halteres","muscle":"Ombros","cue":"Não trave os cotovelos no topo.","loadKg":"8","restSeconds":75,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps","[work]Série de trabalho: 10 reps"]},
         {"title":"Tríceps Corda na Polia","muscle":"Tríceps","cue":"Abra a corda no final do movimento.","loadKg":"15","restSeconds":60,
          "sets":["[work]Série de trabalho: 15 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps"]}
       ]}
     ]'::jsonb,
     '["Esteira: 20 min em ritmo moderado","Bicicleta: 15 min intervalado"]'::jsonb,
     '["Hidrate-se durante o treino","Registre as cargas no aplicativo"]'::jsonb,
     now() - interval '20 days', now() - interval '2 days'),
    (v_trainer, v_bruno, 'Bruno Carvalho Lima', 'Academia Ribeirão Fit', v_month,
     'Reavaliação pendente. Manter volume moderado.', 'active',
     '[
       {"dow":"Treino A","muscle":"Peitoral e Tríceps","exercises":[
         {"title":"Supino Reto com Barra","muscle":"Peito","cue":"Pés firmes no chão.","loadKg":"60","restSeconds":90,
          "sets":["[work]Série de trabalho: 10 reps","[work]Série de trabalho: 8 reps","[work]Série de trabalho: 8 reps"]},
         {"title":"Crucifixo Inclinado com Halteres","muscle":"Peito","cue":"Amplitude controlada.","loadKg":"16","restSeconds":60,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]}
       ]},
       {"dow":"Treino B","muscle":"Pernas","exercises":[
         {"title":"Agachamento Livre","muscle":"Pernas","cue":"Coluna neutra.","loadKg":"80","restSeconds":120,
          "sets":["[work]Série de trabalho: 8 reps","[work]Série de trabalho: 8 reps","[work]Série de trabalho: 6 reps"]}
       ]}
     ]'::jsonb,
     '["Esteira: 25 min"]'::jsonb, '["Dormir pelo menos 7 horas"]'::jsonb,
     now() - interval '15 days', now() - interval '5 days'),
    (v_trainer, v_diego, 'Diego Martins Alves', 'Academia Ribeirão Fit', v_month,
     'Preparação para corrida de rua.', 'active',
     '[
       {"dow":"Treino A","muscle":"Corpo inteiro","exercises":[
         {"title":"Levantamento Terra","muscle":"Posterior","cue":"Barra próxima ao corpo.","loadKg":"70","restSeconds":120,
          "sets":["[work]Série de trabalho: 8 reps","[work]Série de trabalho: 8 reps","[work]Série de trabalho: 6 reps"]},
         {"title":"Afundo com Halteres","muscle":"Pernas","cue":"Tronco estável.","loadKg":"12","restSeconds":60,
          "sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps"]}
       ]}
     ]'::jsonb,
     '["Corrida: 5 km leve"]'::jsonb, '[]'::jsonb,
     now() - interval '10 days', now() - interval '3 days');

  -- Anamneses
  insert into public.student_anamneses
    (id, student_id, trainer_id, name, gender, age, phone, email, weight_kg, height_cm, bmi,
     body_fat_percent, target_weight_kg, main_goal, specific_goals, gym_name,
     training_days_per_week, session_duration, preferred_shift, experience_level,
     sleep_hours, water_intake_liters, stress_level, risk_level, is_draft, consent_accepted,
     created_at, updated_at)
  values
    ('an-ana', v_ana::text, v_trainer, 'Ana Beatriz Souza', 'Feminino', 27, '(16) 99111-2233',
     'ana.souza@exemplo.com', 63.5, 168, 22.5, 24.0, 60.0, 'Hipertrofia',
     'Fortalecer glúteos e pernas', 'Academia Ribeirão Fit', 4, '60 min', 'Noite', 'Intermediário',
     7.5, 2.5, 3, 'Baixo', false, true, now() - interval '58 days', now() - interval '58 days'),
    ('an-bruno', v_bruno::text, v_trainer, 'Bruno Carvalho Lima', 'Masculino', 34, '(16) 99222-3344',
     'bruno.lima@exemplo.com', 88.0, 180, 27.2, 22.0, 82.0, 'Emagrecimento',
     'Reduzir gordura abdominal', 'Academia Ribeirão Fit', 3, '50 min', 'Manhã', 'Iniciante',
     6.0, 2.0, 6, 'Moderado', false, true, now() - interval '44 days', now() - interval '44 days'),
    ('an-diego', v_diego::text, v_trainer, 'Diego Martins Alves', 'Masculino', 29, '(16) 99444-5566',
     'diego.alves@exemplo.com', 74.0, 176, 23.9, 15.0, 72.0, 'Condicionamento',
     'Completar uma meia maratona', 'Academia Ribeirão Fit', 5, '45 min', 'Manhã', 'Avançado',
     8.0, 3.0, 2, 'Baixo', false, true, now() - interval '28 days', now() - interval '28 days');

  -- Sessões de treino registradas pelos alunos
  insert into public.student_workout_sessions
    (student_id, trainer_id, kind, workout_day, completed_sets, duration_seconds, rpe, feedback, created_at)
  values
    (v_ana, v_trainer, 'session', 'Treino A', '{"0":[0,1,2,3],"1":[0,1,2]}', 3300, 8,
     'Agachamento pesado hoje, mas sem dor no joelho.', now() - interval '1 day'),
    (v_ana, v_trainer, 'session', 'Treino B', '{"0":[0,1,2],"1":[0,1,2]}', 2900, 7,
     'Treino rendeu bem.', now() - interval '3 days'),
    (v_ana, v_trainer, 'comment', null, '{}', 0, null,
     'Posso trocar o treino C por corrida no sábado?', now() - interval '6 hours'),
    (v_diego, v_trainer, 'session', 'Treino A', '{"0":[0,1,2]}', 2400, 9,
     'Terra muito puxado, aumentar descanso?', now() - interval '2 days');

  -- Linha do tempo
  insert into public.student_timeline (trainer_id, student_id, timestamp, title, description, reference_type)
  values
    (v_trainer, v_ana, now() - interval '58 days', 'Anamnese concluída', 'Objetivo: hipertrofia', 'anamnese'),
    (v_trainer, v_ana, now() - interval '20 days', 'Nova ficha de treino', 'Treinos A, B e C', 'workout'),
    (v_trainer, v_bruno, now() - interval '15 days', 'Ficha atualizada', 'Ajuste de cargas', 'workout');

  -- Modelos (presets) de ficha
  insert into public.custom_presets (trainer_id, preset_title, description, sheet_data, created_at)
  values
    (v_trainer, 'Hipertrofia Iniciante', 'Divisão ABC para os primeiros 3 meses',
     '{"studentId":"preset_custom","studentName":"Hipertrofia Iniciante","days":[
        {"dow":"Treino A","muscle":"Corpo inteiro","exercises":[
          {"title":"Agachamento Livre","muscle":"Pernas","loadKg":"","sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]},
          {"title":"Supino Reto com Barra","muscle":"Peito","loadKg":"","sets":["[work]Série de trabalho: 12 reps","[work]Série de trabalho: 10 reps"]}
        ]}]}'::jsonb, now() - interval '30 days'),
    (v_trainer, 'Emagrecimento 3x/semana', 'Circuito metabólico com cardio',
     '{"studentId":"preset_custom","studentName":"Emagrecimento 3x/semana","days":[
        {"dow":"Treino A","muscle":"Circuito","exercises":[
          {"title":"Afundo com Halteres","muscle":"Pernas","loadKg":"","sets":["[work]Série de trabalho: 15 reps","[work]Série de trabalho: 15 reps"]},
          {"title":"Remada Baixa","muscle":"Costas","loadKg":"","sets":["[work]Série de trabalho: 15 reps","[work]Série de trabalho: 15 reps"]}
        ]}]}'::jsonb, now() - interval '25 days'),
    (v_trainer, 'Força Avançado', 'Foco nos levantamentos básicos',
     '{"studentId":"preset_custom","studentName":"Força Avançado","days":[
        {"dow":"Treino A","muscle":"Básicos","exercises":[
          {"title":"Levantamento Terra","muscle":"Posterior","loadKg":"","sets":["[work]Série de trabalho: 5 reps","[work]Série de trabalho: 5 reps","[work]Série de trabalho: 5 reps"]}
        ]}]}'::jsonb, now() - interval '12 days');

  -- Funil de vendas (CRM)
  insert into public.leads
    (id, trainer_id, name, phone, instagram, email, objective, origin_channel, target_plan_name,
     estimated_value, score, status, priority, notes, utm_source, follow_up_step,
     scheduled_follow_up_date, scheduled_follow_up_note, last_contact_at, created_at, updated_at)
  values
    ('lead-larissa', v_trainer, 'Larissa Campos', '16991234567', '@larissacampos', 'larissa@exemplo.com',
     'Hipertrofia', 'Instagram', 'Consultoria Mensal', 220, 82, 'negotiating', 'hot', '[]', 'instagram', 2,
     now() + interval '1 day', 'Enviar proposta final', now() - interval '1 day', now() - interval '6 days', now() - interval '1 day'),
    ('lead-marcos', v_trainer, 'Marcos Pereira', '16992345678', '@marcosp', 'marcos@exemplo.com',
     'Emagrecimento', 'Indicação', 'Plano Trimestral', 540, 64, 'proposal_sent', 'warm', '[]', 'indicacao', 1,
     now() + interval '2 days', 'Confirmar horário da avaliação', now() - interval '2 days', now() - interval '8 days', now() - interval '2 days'),
    ('lead-patricia', v_trainer, 'Patrícia Oliveira', '16993456789', '@patioliveira', '',
     'Condicionamento', 'Google', 'Consultoria Online', 150, 48, 'anamnese_sent', 'warm', '[]', 'google', 1,
     null, null, now() - interval '3 days', now() - interval '4 days', now() - interval '3 days'),
    ('lead-renato', v_trainer, 'Renato Souza', '16994567890', '', '',
     'Saúde', 'WhatsApp', 'Consultoria Mensal', 220, 30, 'new', 'cold', '[]', 'whatsapp', 0,
     null, null, null, now() - interval '1 day', now() - interval '1 day'),
    ('lead-tatiane', v_trainer, 'Tatiane Ribeiro', '16995678901', '@tatiribeiro', 'tatiane@exemplo.com',
     'Hipertrofia', 'Instagram', 'Plano Trimestral', 540, 77, 'new', 'hot', '[]', 'instagram', 0,
     now(), 'Primeiro contato', null, now() - interval '5 hours', now() - interval '5 hours');

  -- Financeiro: planos
  insert into public.plans (id, trainer_id, name, description, category, type, price, interval, active, status, created_at)
  values
    (v_plan_mensal, v_trainer, 'Consultoria Mensal', 'Treino presencial + ajustes semanais', 'Consultoria', 'subscription', 220, 'Mensal', true, 'active', now() - interval '90 days'),
    (v_plan_trimestral, v_trainer, 'Plano Trimestral', 'Acompanhamento por 3 meses com desconto', 'Consultoria', 'subscription', 540, 'Trimestral', true, 'active', now() - interval '90 days'),
    (v_plan_online, v_trainer, 'Consultoria Online', 'Treino on-line com feedback pelo app', 'Online', 'subscription', 150, 'Mensal', true, 'active', now() - interval '90 days');

  -- Assinaturas
  insert into public.subscriptions (id, trainer_id, student_id, plan_id, status, contracted_value, discount, readjustment, cycle, start_date, auto_renew, created_at, updated_at)
  values
    ('d0000000-0000-4000-8000-000000000001', v_trainer, v_ana, v_plan_mensal, 'active', 220, 0, 0, 'Mensal', current_date - 60, true, now() - interval '60 days', now() - interval '60 days'),
    ('d0000000-0000-4000-8000-000000000002', v_trainer, v_bruno, v_plan_trimestral, 'active', 540, 0, 0, 'Trimestral', current_date - 45, true, now() - interval '45 days', now() - interval '45 days'),
    ('d0000000-0000-4000-8000-000000000003', v_trainer, v_diego, v_plan_mensal, 'active', 220, 20, 0, 'Mensal', current_date - 30, true, now() - interval '30 days', now() - interval '30 days'),
    ('d0000000-0000-4000-8000-000000000004', v_trainer, v_gabriela, v_plan_online, 'active', 150, 0, 0, 'Mensal', current_date - 9, true, now() - interval '9 days', now() - interval '9 days');

  -- Faturas
  insert into public.invoices (id, trainer_id, student_id, subscription_id, plan_id, type,
    plan_snapshot, student_snapshot, original_amount, discount, fine, interest, final_amount,
    due_date, status, created_at, updated_at)
  select v.id::uuid, v.trainer_id, v.student_id, v.subscription_id::uuid, v.plan_id, v.type,
    jsonb_build_object('id', plan.id, 'name', plan.name),
    jsonb_build_object('id', student.id, 'name', student.name),
    v.original_amount, v.discount, v.fine, v.interest, v.final_amount, v.due_date,
    v.status::public.invoice_status, v.created_at, v.updated_at
  from (values
    ('e0000000-0000-4000-8000-000000000001', v_trainer, v_ana, 'd0000000-0000-4000-8000-000000000001', v_plan_mensal, 'subscription', 220, 0, 0, 0, 220, current_date - 30, 'pending', now() - interval '35 days', now() - interval '35 days'),
    ('e0000000-0000-4000-8000-000000000002', v_trainer, v_ana, 'd0000000-0000-4000-8000-000000000001', v_plan_mensal, 'subscription', 220, 0, 0, 0, 220, current_date + 5, 'pending', now() - interval '3 days', now() - interval '3 days'),
    ('e0000000-0000-4000-8000-000000000003', v_trainer, v_bruno, 'd0000000-0000-4000-8000-000000000002', v_plan_trimestral, 'subscription', 540, 0, 0, 0, 540, current_date - 40, 'pending', now() - interval '45 days', now() - interval '45 days'),
    ('e0000000-0000-4000-8000-000000000004', v_trainer, v_diego, 'd0000000-0000-4000-8000-000000000003', v_plan_mensal, 'subscription', 220, 20, 0, 0, 200, current_date - 3, 'overdue', now() - interval '30 days', now() - interval '3 days'),
    ('e0000000-0000-4000-8000-000000000005', v_trainer, v_gabriela, 'd0000000-0000-4000-8000-000000000004', v_plan_online, 'subscription', 150, 0, 0, 0, 150, current_date + 12, 'pending', now() - interval '9 days', now() - interval '9 days')
  ) as v(id, trainer_id, student_id, subscription_id, plan_id, type, original_amount,
         discount, fine, interest, final_amount, due_date, status, created_at, updated_at)
  join public.plans as plan on plan.id = v.plan_id
  join public.students as student on student.id = v.student_id;

  -- Pagamentos confirmados (faturas pagas exigem pagamento registrado)
  insert into public.payments (trainer_id, invoice_id, student_id, amount, payment_date, payment_method, status, notes, created_at)
  values
    (v_trainer, 'e0000000-0000-4000-8000-000000000001', v_ana, 220, current_date - 31, 'pix', 'confirmed', '', now() - interval '31 days'),
    (v_trainer, 'e0000000-0000-4000-8000-000000000003', v_bruno, 540, current_date - 41, 'credit_card', 'confirmed', '', now() - interval '41 days');

  update public.invoices set status = 'paid', updated_at = now()
   where id in ('e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000003');

  -- Fluxo de caixa
  insert into public.cash_flow (trainer_id, type, amount, date, category, description, invoice_id, created_at)
  values
    (v_trainer, 'inflow', 220, current_date - 31, 'Mensalidade', 'Pagamento Ana Beatriz Souza', 'e0000000-0000-4000-8000-000000000001', now() - interval '31 days'),
    (v_trainer, 'inflow', 540, current_date - 41, 'Mensalidade', 'Pagamento Bruno Carvalho Lima', 'e0000000-0000-4000-8000-000000000003', now() - interval '41 days'),
    (v_trainer, 'outflow', 89.9, current_date - 10, 'Ferramentas', 'Assinatura de software de avaliação', null, now() - interval '10 days'),
    (v_trainer, 'outflow', 150, current_date - 6, 'Marketing', 'Impulsionamento no Instagram', null, now() - interval '6 days');
end
$$;
