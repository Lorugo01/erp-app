/*
  Warnings:

  - Added the required column `type` to the `Subject` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Subject` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "SubjectType" AS ENUM ('LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS', 'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA', 'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR');

-- AlterTable
ALTER TABLE "Subject" ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "type" "SubjectType" NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;
