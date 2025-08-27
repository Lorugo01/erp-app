import { Request, Response } from 'express';
import prisma from '../prisma/client';

export class SubjectsController {
  // Buscar todas as disciplinas
  async getAllSubjectTypes(req: Request, res: Response) {
    try {
      const subjects = await (prisma as any).subjectType.findMany({
        orderBy: { createdAt: 'desc' },
      });

      // Calcular estatísticas reais para cada tipo de disciplina
      const subjectsWithStats = await Promise.all(
        subjects.map(async (s: any) => {
          // Contar turmas que usam este tipo de disciplina
          const classCount = await (prisma as any).subject.count({
            where: { subjectTypeId: s.id },
          });

          // Contar professores únicos que lecionam este tipo de disciplina
          const teachers = await (prisma as any).subject.findMany({
            where: { subjectTypeId: s.id },
            select: { teacherId: true },
          });
          const teacherCount = teachers.map((t: any) => t.teacherId).filter((value: any, index: any, self: any) => self.indexOf(value) === index).length;

          // Contar alunos únicos que estudam este tipo de disciplina
          const enrollments = await (prisma as any).enrollment.findMany({
            where: {
              class: {
                subjects: {
                  some: {
                    subjectTypeId: s.id,
                  },
                },
              },
              current: true,
            },
            select: { studentId: true },
          });
          const studentCount = enrollments.map((e: any) => e.studentId).filter((value: any, index: any, self: any) => self.indexOf(value) === index).length;

          return {
            id: s.id,
            type: s.name,
            description: s.description ?? '',
            isEvaluative: s.isEvaluative,
            classCount,
            teacherCount,
            studentCount,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
          };
        })
      );

      res.json(subjectsWithStats);
    } catch (error) {
      console.error('❌ Controller: Erro ao buscar disciplinas:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar disciplina por ID
  async getSubjectTypeById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const subject = await (prisma as any).subjectType.findUnique({ where: { id } });
      if (!subject) return res.status(404).json({ error: 'Disciplina não encontrada' });

      // Calcular estatísticas reais para este tipo de disciplina
      const classCount = await (prisma as any).subject.count({
        where: { subjectTypeId: id },
      });

      const teachers = await (prisma as any).subject.findMany({
        where: { subjectTypeId: id },
        select: { teacherId: true },
      });
      const teacherCount = teachers.map((t: any) => t.teacherId).filter((value: any, index: any, self: any) => self.indexOf(value) === index).length;

      const enrollments = await (prisma as any).enrollment.findMany({
        where: {
          class: {
            subjects: {
              some: {
                subjectTypeId: id,
              },
            },
          },
          current: true,
        },
        select: { studentId: true },
      });
      const studentCount = enrollments.map((e: any) => e.studentId).filter((value: any, index: any, self: any) => self.indexOf(value) === index).length;

      res.json({
        id: subject.id,
        type: subject.name,
        description: subject.description ?? '',
        isEvaluative: subject.isEvaluative,
        classCount,
        teacherCount,
        studentCount,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
      });
    } catch (error) {
      console.error('Erro ao buscar disciplina:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Criar nova disciplina
  async createSubjectType(req: Request, res: Response) {
    try {
      const { name, description, isEvaluative } = req.body;

      if (!name) {
        return res.status(400).json({ error: 'Nome da disciplina é obrigatório' });
      }

      const created = await (prisma as any).subjectType.create({
        data: {
          name: name,
          description: description ?? '',
          isEvaluative: isEvaluative ?? true,
        },
      });

      res.status(201).json(created);
    } catch (error: any) {
      console.error('Erro ao criar disciplina:', error);
      if (error?.code === 'P2002') {
        return res.status(409).json({ error: 'Já existe uma matéria com esse nome' });
      }
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Atualizar disciplina
  async updateSubjectType(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { name, description, isEvaluative } = req.body;

      if (!name) {
        return res.status(400).json({ error: 'Nome da disciplina é obrigatório' });
      }

      const updated = await (prisma as any).subjectType.update({
        where: { id },
        data: {
          name: name,
          description: description ?? '',
          isEvaluative: isEvaluative ?? true,
        },
      });

      res.json(updated);
    } catch (error: any) {
      console.error('Erro ao atualizar disciplina:', error);
      if (error?.code === 'P2025') {
        return res.status(404).json({ error: 'Disciplina não encontrada' });
      }
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Excluir disciplina
  async deleteSubjectType(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await (prisma as any).subjectType.delete({ where: { id } });
      res.json({ success: true, message: 'Disciplina removida com sucesso' });
    } catch (error: any) {
      console.error('Erro ao excluir disciplina:', error);
      if (error?.code === 'P2025') {
        return res.status(404).json({ error: 'Disciplina não encontrada' });
      }
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar disciplinas por turma
  async getSubjectsByClass(req: Request, res: Response) {
    try {
      const { classId } = req.params;
      
      // Buscar disciplinas da turma usando o service correto
      const subjects = await (prisma as any).subject.findMany({
        where: { classId },
        include: {
          teacher: true,
          subjectType: true,
        },
      });

      // Formatar dados para compatibilidade com o frontend
      const formattedSubjects = subjects.map((subject: any) => ({
        id: subject.id,
        name: subject.name,
        teacherId: subject.teacherId,
        teacher: subject.teacher,
        subjectType: subject.subjectType,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
      }));

      res.json(formattedSubjects);
    } catch (error) {
      console.error('Erro ao buscar disciplinas da turma:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Adicionar disciplina a uma turma
  async addSubjectToClass(req: Request, res: Response) {
    try {
      const { classId } = req.params;
      const { subjectTypeId, teacherId } = req.body;

      if (!subjectTypeId || !teacherId) {
        return res.status(400).json({ 
          error: 'subjectTypeId e teacherId são obrigatórios' 
        });
      }

      // Buscar o tipo de disciplina e a turma
      const subjectType = await (prisma as any).subjectType.findUnique({
        where: { id: subjectTypeId },
      });

      const classData = await (prisma as any).class.findUnique({
        where: { id: classId },
      });

      if (!subjectType) {
        return res.status(400).json({ error: 'Tipo de disciplina não encontrado' });
      }

      if (!classData) {
        return res.status(400).json({ error: 'Turma não encontrada' });
      }

      // Criar a disciplina
      const newSubject = await (prisma as any).subject.create({
        data: {
          name: '${subjectType.name} - ${classData.name}',
          classId,
          teacherId,
          subjectTypeId,
        },
        include: {
          teacher: true,
          subjectType: true,
        },
      });

      res.status(201).json(newSubject);
    } catch (error) {
      console.error('Erro ao adicionar disciplina à turma:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Remover disciplina de uma turma
  async removeSubjectFromClass(req: Request, res: Response) {
    try {
      const { classId, subjectId } = req.params;
      
      // Verificar se a disciplina existe e pertence à turma
      const subject = await (prisma as any).subject.findFirst({
        where: { 
          id: subjectId,
          classId: classId,
        },
      });

      if (!subject) {
        return res.status(404).json({ error: 'Disciplina não encontrada' });
      }

      // Remover a disciplina
      await (prisma as any).subject.delete({
        where: { id: subjectId },
      });

      res.json({ success: true, message: 'Disciplina removida com sucesso' });
    } catch (error) {
      console.error('Erro ao remover disciplina da turma:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar disciplinas por professor
  async getSubjectsByTeacher(req: Request, res: Response) {
    try {
      const { teacherId } = req.params;
      
      // Buscar disciplinas do professor
      const subjects = await (prisma as any).subject.findMany({
        where: { teacherId },
        include: {
          class: true,
          subjectType: true,
        },
      });

      // Formatar dados para compatibilidade com o frontend
      const formattedSubjects = subjects.map((subject: any) => ({
        id: subject.id,
        name: subject.name,
        classId: subject.classId,
        class: subject.class,
        subjectType: subject.subjectType,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
      }));

      res.json(formattedSubjects);
    } catch (error) {
      console.error('Erro ao buscar disciplinas do professor:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }
}
