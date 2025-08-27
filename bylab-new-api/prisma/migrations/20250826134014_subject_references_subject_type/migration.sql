/*
  Warnings:

  - You are about to drop the column `type` on the `Subject` table. All the data in the column will be lost.
  - You are about to drop the `CustomSubjectType` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `subjectTypeId` to the `Subject` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "public"."Subject" DROP COLUMN "type",
ADD COLUMN     "subjectTypeId" TEXT NOT NULL;

-- DropTable
DROP TABLE "public"."CustomSubjectType";

-- DropEnum
DROP TYPE "public"."SubjectTypeEnum";

-- CreateTable
CREATE TABLE "public"."SubjectType" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "isEvaluative" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SubjectType_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SubjectType_name_key" ON "public"."SubjectType"("name");

-- AddForeignKey
ALTER TABLE "public"."Subject" ADD CONSTRAINT "Subject_subjectTypeId_fkey" FOREIGN KEY ("subjectTypeId") REFERENCES "public"."SubjectType"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
