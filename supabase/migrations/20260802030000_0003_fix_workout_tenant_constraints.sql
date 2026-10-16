-- Migration: 20260802030000_0003_fix_workout_tenant_constraints.sql
-- Descrição: Ajustes explícitos de FKs compostas por tenant (trainer_id, student_id) e vínculo de versões à ficha de treino (workout_sheet_id)

-- 1. Ajuste da tabela workout_sheets
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'workout_sheets_trainer_id_student_id_fkey'
    ) THEN
        ALTER TABLE public.workout_sheets
            ALTER COLUMN student_id TYPE UUID USING student_id::uuid,
            ADD CONSTRAINT uq_workout_sheets_tenant UNIQUE (id, trainer_id);

        ALTER TABLE public.workout_sheets
            ADD CONSTRAINT fk_workout_sheets_student_tenant
            FOREIGN KEY (student_id, trainer_id) REFERENCES public.students (id, trainer_id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Ajuste da tabela sheet_versions (Adição de workout_sheet_id e FK composta)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sheet_versions' AND column_name = 'workout_sheet_id'
    ) THEN
        ALTER TABLE public.sheet_versions
            ADD COLUMN workout_sheet_id UUID,
            ALTER COLUMN student_id TYPE UUID USING student_id::uuid;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_sheet_versions_student_tenant'
    ) THEN
        ALTER TABLE public.sheet_versions
            ADD CONSTRAINT fk_sheet_versions_student_tenant
            FOREIGN KEY (student_id, trainer_id) REFERENCES public.students (id, trainer_id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_sheet_versions_workout_sheet_tenant'
    ) THEN
        ALTER TABLE public.sheet_versions
            ADD CONSTRAINT fk_sheet_versions_workout_sheet_tenant
            FOREIGN KEY (workout_sheet_id, trainer_id) REFERENCES public.workout_sheets (id, trainer_id) ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Ajuste da tabela student_records (Adição de colunas semânticas e FK composta)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_student_records_student_tenant'
    ) THEN
        ALTER TABLE public.student_records
            ALTER COLUMN student_id TYPE UUID USING student_id::uuid,
            ADD COLUMN IF NOT EXISTS has_professional_assistance TEXT,
            ADD COLUMN IF NOT EXISTS student_additional_notes TEXT,
            ADD COLUMN IF NOT EXISTS target_muscles TEXT,
            ADD COLUMN IF NOT EXISTS birth_date DATE;

        -- Garante unicidade por tenant
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint WHERE conname = 'uq_student_records_tenant'
        ) THEN
            ALTER TABLE public.student_records ADD CONSTRAINT uq_student_records_tenant UNIQUE (student_id, trainer_id);
        END IF;

        ALTER TABLE public.student_records
            ADD CONSTRAINT fk_student_records_student_tenant
            FOREIGN KEY (student_id, trainer_id) REFERENCES public.students (id, trainer_id) ON DELETE CASCADE;
    END IF;
END $$;
