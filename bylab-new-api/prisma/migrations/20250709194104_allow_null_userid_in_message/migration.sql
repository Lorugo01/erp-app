-- DropForeignKey
ALTER TABLE "message" DROP CONSTRAINT "message_user_id_fkey";

-- AlterTable
ALTER TABLE "message" ALTER COLUMN "user_id" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
