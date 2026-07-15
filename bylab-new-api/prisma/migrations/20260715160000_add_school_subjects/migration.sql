-- Required for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- CreateTable
CREATE TABLE IF NOT EXISTS "school_subjects" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "type" "SubjectType" NOT NULL,
    "schoolId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "school_subjects_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "school_subjects_schoolId_type_key" ON "school_subjects"("schoolId", "type");

-- AddForeignKey (safe if re-run after partial apply)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'school_subjects_schoolId_fkey'
  ) THEN
    ALTER TABLE "school_subjects"
      ADD CONSTRAINT "school_subjects_schoolId_fkey"
      FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

-- AlterTable
ALTER TABLE "Subject" ADD COLUMN IF NOT EXISTS "schoolSubjectId" TEXT;

-- Backfill catalog from existing subjects (one per school + type)
INSERT INTO "school_subjects" ("id", "name", "description", "type", "schoolId", "createdAt", "updatedAt")
SELECT
  gen_random_uuid()::text,
  CASE s."type"
    WHEN 'LINGUA_INGLESA' THEN 'Língua Inglesa'
    WHEN 'ARTE' THEN 'Arte'
    WHEN 'EDUCACAO_FISICA' THEN 'Educação Física'
    WHEN 'MATEMATICA' THEN 'Matemática'
    WHEN 'CIENCIAS' THEN 'Ciências'
    WHEN 'HISTORIA' THEN 'História'
    WHEN 'GEOGRAFIA' THEN 'Geografia'
    WHEN 'ENSINO_RELIGIOSO' THEN 'Ensino Religioso'
    WHEN 'BIOLOGIA' THEN 'Biologia'
    WHEN 'FISICA' THEN 'Física'
    WHEN 'QUIMICA' THEN 'Química'
    WHEN 'FILOSOFIA' THEN 'Filosofia'
    WHEN 'SOCIOLOGIA' THEN 'Sociologia'
    WHEN 'CONTEUDO_INTERDISCIPLINAR' THEN 'Conteúdo Interdisciplinar'
    ELSE s."type"::text
  END,
  NULL,
  s."type",
  s."schoolId",
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM (
  SELECT DISTINCT "schoolId", "type"
  FROM "Subject"
) s
ON CONFLICT ("schoolId", "type") DO NOTHING;

-- Link offerings to catalog
UPDATE "Subject" sub
SET "schoolSubjectId" = ss."id",
    "name" = ss."name"
FROM "school_subjects" ss
WHERE ss."schoolId" = sub."schoolId"
  AND ss."type" = sub."type"
  AND (sub."schoolSubjectId" IS NULL OR sub."schoolSubjectId" <> ss."id");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Subject_schoolSubjectId_fkey'
  ) THEN
    ALTER TABLE "Subject"
      ADD CONSTRAINT "Subject_schoolSubjectId_fkey"
      FOREIGN KEY ("schoolSubjectId") REFERENCES "school_subjects"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Remover offerings duplicados (mesmo classId + type) sem dados vinculados,
-- mantendo o mais antigo. Necessário antes do índice único.
DELETE FROM "Subject" AS dup
WHERE EXISTS (
  SELECT 1
  FROM "Subject" AS keep
  WHERE keep."classId" = dup."classId"
    AND keep."type" = dup."type"
    AND keep."createdAt" < dup."createdAt"
)
AND NOT EXISTS (SELECT 1 FROM "Lesson" l WHERE l."subjectId" = dup."id")
AND NOT EXISTS (SELECT 1 FROM "Grade" g WHERE g."subjectId" = dup."id")
AND NOT EXISTS (SELECT 1 FROM "Assignment" a WHERE a."subjectId" = dup."id");

-- Se ainda houver duplicatas com dados, funde FKs para o registro mais antigo e remove o resto
DO $$
DECLARE
  r RECORD;
  keeper_id TEXT;
  loser_id TEXT;
BEGIN
  FOR r IN
    SELECT "classId", "type"
    FROM "Subject"
    GROUP BY "classId", "type"
    HAVING COUNT(*) > 1
  LOOP
    SELECT id INTO keeper_id
    FROM "Subject"
    WHERE "classId" = r."classId" AND "type" = r."type"
    ORDER BY "createdAt" ASC
    LIMIT 1;

    FOR loser_id IN
      SELECT id FROM "Subject"
      WHERE "classId" = r."classId" AND "type" = r."type" AND id <> keeper_id
    LOOP
      UPDATE "Lesson" SET "subjectId" = keeper_id WHERE "subjectId" = loser_id;
      UPDATE "Grade" SET "subjectId" = keeper_id WHERE "subjectId" = loser_id;
      UPDATE "Assignment" SET "subjectId" = keeper_id WHERE "subjectId" = loser_id;
      DELETE FROM "Subject" WHERE id = loser_id;
    END LOOP;
  END LOOP;
END $$;

-- Create unique offering per class + type
CREATE UNIQUE INDEX IF NOT EXISTS "Subject_classId_type_key" ON "Subject"("classId", "type");
