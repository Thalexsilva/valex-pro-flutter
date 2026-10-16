-- ==============================================================================
-- 0015_add_student_reassessment_and_bioimpedance.sql
-- Adiciona suporte no Supabase para Reavaliação 360°, Flags de Primeiro Acesso e Bioimpedância OCR
-- ==============================================================================

-- 1. Criação da tabela student_anamneses (caso ainda não exista)
CREATE TABLE IF NOT EXISTS public.student_anamneses (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    trainer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lead_id TEXT,
    name TEXT NOT NULL,
    gender TEXT DEFAULT 'Não informado',
    birth_date TEXT,
    age INT DEFAULT 0,
    phone TEXT,
    email TEXT,
    cpf TEXT,
    address TEXT,
    
    -- Antropometria & Metas
    weight_kg NUMERIC(5,2) DEFAULT 0,
    height_cm NUMERIC(5,2) DEFAULT 0,
    bmi NUMERIC(4,1) DEFAULT 0,
    body_fat_percent NUMERIC(4,1),
    target_weight_kg NUMERIC(5,2),
    main_goal TEXT DEFAULT 'Hipertrofia',
    specific_goals TEXT,
    gym_name TEXT,
    
    -- Bioimpedância Completa (Dados OCR e Métricas Estruturadas)
    bioimpedance JSONB DEFAULT NULL,
    
    -- Rotina & Treino
    training_days_per_week INT DEFAULT 4,
    session_duration TEXT DEFAULT '45 a 60 minutos',
    preferred_shift TEXT DEFAULT 'Manhã',
    experience_level TEXT DEFAULT 'Intermediário',
    has_trained_with_coach BOOLEAN DEFAULT FALSE,
    other_sports TEXT,
    
    -- Biomecânica & Estrutura JSONB
    target_muscles JSONB DEFAULT '[]'::jsonb,
    body_perception TEXT,
    favorite_exercises TEXT,
    disliked_exercises TEXT,
    parq_answers JSONB DEFAULT '{}'::jsonb,
    parq_details JSONB DEFAULT '{}'::jsonb,
    joint_pains JSONB DEFAULT '[]'::jsonb,
    movement_pain_details TEXT,
    medical_history TEXT,
    surgeries TEXT,
    medications TEXT,
    supplements TEXT,
    
    -- Hábitos
    sleep_hours NUMERIC(3,1) DEFAULT 7.0,
    water_intake_liters NUMERIC(3,1) DEFAULT 2.5,
    stress_level INT DEFAULT 3,
    diet_habit TEXT,
    alcohol_habit TEXT DEFAULT 'Não',
    smoking_habit TEXT DEFAULT 'Não',
    
    -- Risco Clínico & Arquivos
    risk_level TEXT DEFAULT 'low',
    posture_photos JSONB DEFAULT '[]'::jsonb,
    documents JSONB DEFAULT '[]'::jsonb,
    
    -- Auditoria
    is_draft BOOLEAN DEFAULT FALSE,
    consent_accepted BOOLEAN DEFAULT TRUE,
    instructor_notes TEXT,
    prontuario_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adiciona colunas em student_anamneses se a tabela já existia
ALTER TABLE public.student_anamneses
    ADD COLUMN IF NOT EXISTS bioimpedance JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS body_perception TEXT,
    ADD COLUMN IF NOT EXISTS favorite_exercises TEXT,
    ADD COLUMN IF NOT EXISTS disliked_exercises TEXT;

-- 2. Expansão da Tabela public.students para controle de Reavaliação 360° e 1º Acesso
ALTER TABLE public.students
    ADD COLUMN IF NOT EXISTS needs_reassessment BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS anamnese_pending BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS last_anamnese_date TEXT,
    ADD COLUMN IF NOT EXISTS reassessment_requested_at TIMESTAMPTZ;

-- Índices de Performance
CREATE INDEX IF NOT EXISTS idx_student_anamneses_student_id ON public.student_anamneses(student_id);
CREATE INDEX IF NOT EXISTS idx_student_anamneses_trainer_id ON public.student_anamneses(trainer_id);
CREATE INDEX IF NOT EXISTS idx_students_reassessment ON public.students(needs_reassessment, anamnese_pending);

-- Habilitação de RLS
ALTER TABLE public.student_anamneses ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para Treinador Autenticado e Aluno
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'student_anamneses' AND policyname = 'Treinador e aluno podem visualizar anamneses'
    ) THEN
        CREATE POLICY "Treinador e aluno podem visualizar anamneses"
            ON public.student_anamneses
            FOR SELECT
            TO authenticated
            USING (auth.uid() = trainer_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'student_anamneses' AND policyname = 'Treinador e aluno podem inserir/atualizar anamneses'
    ) THEN
        CREATE POLICY "Treinador e aluno podem inserir/atualizar anamneses"
            ON public.student_anamneses
            FOR ALL
            TO authenticated
            USING (auth.uid() = trainer_id)
            WITH CHECK (auth.uid() = trainer_id);
    END IF;
END $$;

-- 3. Configuração do Bucket de Storage: student-documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('student-documents', 'student-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Acesso ao Storage de Fotos e Bioimpedância
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' AND policyname = 'Permitir upload de fotos e laudos de bioimpedancia'
    ) THEN
        CREATE POLICY "Permitir upload de fotos e laudos de bioimpedancia"
            ON storage.objects
            FOR INSERT
            TO authenticated
            WITH CHECK (bucket_id = 'student-documents' AND EXISTS (
                SELECT 1 FROM public.students
                WHERE students.id::text = (storage.foldername(objects.name))[1]
                  AND students.trainer_id = auth.uid()
            ));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' AND policyname = 'Permitir visualizacao de fotos e laudos de bioimpedancia'
    ) THEN
        CREATE POLICY "Permitir visualizacao de fotos e laudos de bioimpedancia"
            ON storage.objects
            FOR SELECT
            TO authenticated
            USING (bucket_id = 'student-documents' AND EXISTS (
                SELECT 1 FROM public.students
                WHERE students.id::text = (storage.foldername(objects.name))[1]
                  AND students.trainer_id = auth.uid()
            ));
    END IF;
END $$;
