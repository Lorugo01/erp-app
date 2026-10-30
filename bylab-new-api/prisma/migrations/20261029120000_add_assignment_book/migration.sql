-- Livro do Alexandria compartilhado na tarefa
ALTER TABLE "Assignment" ADD COLUMN IF NOT EXISTS "bookId" TEXT;
ALTER TABLE "Assignment" ADD COLUMN IF NOT EXISTS "bookTitle" TEXT;
ALTER TABLE "Assignment" ADD COLUMN IF NOT EXISTS "bookCoverUrl" TEXT;
