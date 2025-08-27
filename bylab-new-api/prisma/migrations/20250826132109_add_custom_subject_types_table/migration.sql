/*
  Warnings:

  - Changed the type of `type` on the `Subject` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "public"."SubjectTypeEnum" AS ENUM ('LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS', 'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA', 'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR');

-- AlterTable
ALTER TABLE "public"."Subject" DROP COLUMN "type",
ADD COLUMN     "type" "public"."SubjectTypeEnum" NOT NULL;

-- DropEnum
DROP TYPE "public"."SubjectType";

-- CreateTable
CREATE TABLE "public"."CustomSubjectType" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "description" TEXT,
    "isEvaluative" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CustomSubjectType_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CustomSubjectType_type_key" ON "public"."CustomSubjectType"("type");
