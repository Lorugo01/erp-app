/*
  Warnings:

  - You are about to drop the column `period` on the `Grade` table. All the data in the column will be lost.
  - Added the required column `periodId` to the `Grade` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Grade" DROP COLUMN "period",
ADD COLUMN     "concept" TEXT,
ADD COLUMN     "periodId" TEXT NOT NULL,
ALTER COLUMN "value" DROP NOT NULL;

-- AlterTable
ALTER TABLE "GradeType" ADD COLUMN     "isConcept" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "GradePeriod" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "order" INTEGER NOT NULL,

    CONSTRAINT "GradePeriod_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Config" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "evaluationModel" TEXT NOT NULL,
    "minGrade" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "minAttendance" DOUBLE PRECISION NOT NULL DEFAULT 75.0,

    CONSTRAINT "Config_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Grade" ADD CONSTRAINT "Grade_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "GradePeriod"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
