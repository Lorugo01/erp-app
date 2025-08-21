/*
  Warnings:

  - The primary key for the `Config` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - A unique constraint covering the columns `[schoolId]` on the table `Config` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[email,schoolId]` on the table `Student` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[registrationNumber,schoolId]` on the table `Student` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[email,schoolId]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `schoolId` to the `Class` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `Config` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `Event` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `GradePeriod` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `GradeType` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `Student` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `Subject` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `Teacher` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `schoolId` to the `chat` table without a default value. This is not possible if the table is not empty.

*/

-- Primeiro, criar a tabela de escolas
CREATE TABLE "schools" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "website" TEXT,
    "logo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "schools_pkey" PRIMARY KEY ("id")
);

-- Inserir uma escola padrão
INSERT INTO "schools" ("id", "name", "address", "phone", "email", "website", "logo", "createdAt", "updatedAt") 
VALUES (
    'default-school-id',
    'Escola Padrão ByLAB',
    'Endereço da Escola',
    '(11) 99999-9999',
    'escola@bylab.com',
    'https://bylab.com',
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Adicionar colunas schoolId com valor padrão
ALTER TABLE "User" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Student" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Teacher" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Class" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Subject" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Event" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "chat" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "GradePeriod" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "GradeType" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';

-- Modificar a tabela Config
ALTER TABLE "Config" DROP CONSTRAINT "Config_pkey";
ALTER TABLE "Config" ADD COLUMN "schoolId" TEXT NOT NULL DEFAULT 'default-school-id';
ALTER TABLE "Config" ALTER COLUMN "id" DROP DEFAULT;
ALTER TABLE "Config" ALTER COLUMN "id" SET DATA TYPE TEXT;
ALTER TABLE "Config" ADD CONSTRAINT "Config_pkey" PRIMARY KEY ("id");

-- Remover os valores padrão das colunas schoolId
ALTER TABLE "User" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Student" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Teacher" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Class" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Subject" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Event" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "chat" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "GradePeriod" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "GradeType" ALTER COLUMN "schoolId" DROP DEFAULT;
ALTER TABLE "Config" ALTER COLUMN "schoolId" DROP DEFAULT;

-- DropIndex
DROP INDEX "Student_email_key";
DROP INDEX "Student_registrationNumber_key";

-- CreateIndex
CREATE UNIQUE INDEX "Config_schoolId_key" ON "Config"("schoolId");
CREATE UNIQUE INDEX "Student_email_schoolId_key" ON "Student"("email", "schoolId");
CREATE UNIQUE INDEX "Student_registrationNumber_schoolId_key" ON "Student"("registrationNumber", "schoolId");
CREATE UNIQUE INDEX "User_email_schoolId_key" ON "User"("email", "schoolId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Student" ADD CONSTRAINT "Student_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "chat" ADD CONSTRAINT "chat_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Class" ADD CONSTRAINT "Class_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Teacher" ADD CONSTRAINT "Teacher_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GradePeriod" ADD CONSTRAINT "GradePeriod_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GradeType" ADD CONSTRAINT "GradeType_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Config" ADD CONSTRAINT "Config_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Event" ADD CONSTRAINT "Event_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
