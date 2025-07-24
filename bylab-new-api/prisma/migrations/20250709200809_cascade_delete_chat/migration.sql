-- DropForeignKey
ALTER TABLE "File" DROP CONSTRAINT "File_message_id_fkey";

-- DropForeignKey
ALTER TABLE "chatparticipant" DROP CONSTRAINT "chatparticipant_chat_id_fkey";

-- DropForeignKey
ALTER TABLE "chatparticipant" DROP CONSTRAINT "chatparticipant_user_id_fkey";

-- DropForeignKey
ALTER TABLE "message" DROP CONSTRAINT "message_chat_id_fkey";

-- DropForeignKey
ALTER TABLE "message" DROP CONSTRAINT "message_user_id_fkey";

-- AddForeignKey
ALTER TABLE "chatparticipant" ADD CONSTRAINT "chatparticipant_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chatparticipant" ADD CONSTRAINT "chatparticipant_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "File" ADD CONSTRAINT "File_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message"("id") ON DELETE CASCADE ON UPDATE CASCADE;
