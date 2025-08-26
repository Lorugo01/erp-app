-- CreateTable
CREATE TABLE "SubjectType" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "description" TEXT,
    "isEvaluative" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SubjectType_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subject" (
    "id" TEXT NOT NULL,
    "classId" TEXT NOT NULL,
    "subjectTypeId" TEXT NOT NULL,
    "teacherId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Subject_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SubjectType_type_key" ON "SubjectType"("type");

-- CreateIndex
CREATE UNIQUE INDEX "Subject_classId_subjectTypeId_key" ON "Subject"("classId", "subjectTypeId");

-- AddForeignKey
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_classId_fkey" FOREIGN KEY ("classId") REFERENCES "Class"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_subjectTypeId_fkey" FOREIGN KEY ("subjectTypeId") REFERENCES "SubjectType"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subject" ADD CONSTRAINT "Subject_teacherId_fkey" FOREIGN KEY ("teacherId") REFERENCES "Teacher"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Insert default subject types
INSERT INTO "SubjectType" ("id", "type", "description", "isEvaluative") VALUES
('1', 'MATEMATICA', 'Matemática básica e avançada', true),
('2', 'PORTUGUES', 'Língua Portuguesa e Literatura', true),
('3', 'CIENCIAS', 'Ciências Naturais', true),
('4', 'HISTORIA', 'História Geral e do Brasil', true),
('5', 'GEOGRAFIA', 'Geografia Física e Humana', true),
('6', 'EDUCACAO_FISICA', 'Atividades físicas e esportes', false),
('7', 'LINGUA_INGLESA', 'Língua Inglesa', true),
('8', 'ARTE', 'Arte e Cultura', false),
('9', 'ENSINO_RELIGIOSO', 'Ensino Religioso', false),
('10', 'BIOLOGIA', 'Biologia', true),
('11', 'FISICA', 'Física', true),
('12', 'QUIMICA', 'Química', true),
('13', 'FILOSOFIA', 'Filosofia', true),
('14', 'SOCIOLOGIA', 'Sociologia', true),
('15', 'CONTEUDO_INTERDISCIPLINAR', 'Conteúdo Interdisciplinar', true);
