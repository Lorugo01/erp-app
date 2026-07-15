-- CreateTable
CREATE TABLE "school_subjects" (
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
CREATE UNIQUE INDEX "school_subjects_schoolId_type_key" ON "school_subjects"("schoolId", "type");

-- AddForeignKey
ALTER TABLE "school_subjects" ADD CONSTRAINT "school_subjects_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "Subject" ADD COLUMN "schoolSubjectId" TEXT;

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
) s;

-- Link offerings to catalog
UPDATE "Subject" sub
SET "schoolSubjectId" = ss."id",
    "name" = ss."name"
FROM "school_subjects" ss
WHERE ss."schoolId" = sub."schoolId"
  AND ss."type" = sub."type";

-- AddForeignKey
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_schoolSubjectId_fkey" FOREIGN KEY ("schoolSubjectId") REFERENCES "school_subjects"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Create unique offering per class + type when possible
CREATE UNIQUE INDEX IF NOT EXISTS "Subject_classId_type_key" ON "Subject"("classId", "type");
