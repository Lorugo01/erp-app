/*
  Warnings:

  - Added the required column `evaluationModel` to the `Class` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Class" ADD COLUMN     "evaluationModel" TEXT;

-- Atualiza as turmas existentes para o valor padrão 'NUMERIC'
UPDATE "Class" SET "evaluationModel" = 'NUMERIC' WHERE "evaluationModel" IS NULL;

-- Agora torna o campo obrigatório
ALTER TABLE "Class" ALTER COLUMN "evaluationModel" SET NOT NULL;
