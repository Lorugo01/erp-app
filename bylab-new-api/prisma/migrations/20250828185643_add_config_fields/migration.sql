/*
  Warnings:

  - Added the required column `updatedAt` to the `Config` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "public"."Config" ADD COLUMN     "autoBackupEnabled" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "backupFrequency" TEXT NOT NULL DEFAULT 'DIARIO',
ADD COLUMN     "currentAcademicYear" TEXT NOT NULL DEFAULT '2024',
ADD COLUMN     "enableDebugLogs" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "enrollmentPeriodEnd" TEXT NOT NULL DEFAULT '31/01/2025',
ADD COLUMN     "enrollmentPeriodStart" TEXT NOT NULL DEFAULT '01/12/2024',
ADD COLUMN     "evaluationPeriods" TEXT NOT NULL DEFAULT '4 Bimestres',
ADD COLUMN     "evaluationType" TEXT NOT NULL DEFAULT 'NUMERICO',
ADD COLUMN     "maxClassCapacity" INTEGER NOT NULL DEFAULT 35,
ADD COLUMN     "maxLoginAttempts" INTEGER NOT NULL DEFAULT 3,
ADD COLUMN     "operatingHoursEnd" TEXT NOT NULL DEFAULT '18:00',
ADD COLUMN     "operatingHoursStart" TEXT NOT NULL DEFAULT '07:00',
ADD COLUMN     "passingGrade" DOUBLE PRECISION NOT NULL DEFAULT 7.0,
ADD COLUMN     "requirePasswordChange" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "retentionDays" INTEGER NOT NULL DEFAULT 30,
ADD COLUMN     "sessionTimeout" INTEGER NOT NULL DEFAULT 30,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "validateSSLCert" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "weeklyWorkload" INTEGER NOT NULL DEFAULT 25,
ALTER COLUMN "evaluationModel" SET DEFAULT 'TRADICIONAL';
