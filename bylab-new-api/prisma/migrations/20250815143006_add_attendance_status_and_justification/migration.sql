/*
  Warnings:

  - Added the required column `updatedAt` to the `Attendance` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'ABSENT', 'JUSTIFIED_ABSENT');

-- AlterTable
ALTER TABLE "Attendance" ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "justification" TEXT,
ADD COLUMN     "status" "AttendanceStatus" NOT NULL DEFAULT 'PRESENT',
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "present" SET DEFAULT true;
