import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class SchoolController {
  // Criar uma nova escola
  static async create(req: Request, res: Response) {
    try {
      const { name, address, phone, email, website, logo } = req.body;

      if (!name) {
        return res.status(400).json({ error: 'Nome da escola é obrigatório' });
      }

      const school = await prisma.school.create({
        data: {
          name,
          address,
          phone,
          email,
          website,
          logo,
        },
      });

      res.status(201).json(school);
    } catch (error) {
      console.error('Erro ao criar escola:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Listar todas as escolas
  static async list(req: Request, res: Response) {
    try {
      const schools = await prisma.school.findMany({
        orderBy: { name: 'asc' },
      });

      res.json(schools);
    } catch (error) {
      console.error('Erro ao listar escolas:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar escola por ID
  static async findById(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const school = await prisma.school.findUnique({
        where: { id },
        include: {
          users: {
            select: {
              id: true,
              email: true,
              role: true,
              createdAt: true,
            },
          },
          students: {
            select: {
              id: true,
              name: true,
              email: true,
              createdAt: true,
            },
          },
          teachers: {
            select: {
              id: true,
              name: true,
              email: true,
              createdAt: true,
            },
          },
          classes: {
            select: {
              id: true,
              name: true,
              grade: true,
              academicYear: true,
              shift: true,
            },
          },
        },
      });

      if (!school) {
        return res.status(404).json({ error: 'Escola não encontrada' });
      }

      res.json(school);
    } catch (error) {
      console.error('Erro ao buscar escola:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Atualizar escola
  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { name, address, phone, email, website, logo } = req.body;

      if (!name) {
        return res.status(400).json({ error: 'Nome da escola é obrigatório' });
      }

      const school = await prisma.school.update({
        where: { id },
        data: {
          name,
          address,
          phone,
          email,
          website,
          logo,
          updatedAt: new Date(),
        },
      });

      res.json(school);
    } catch (error) {
      console.error('Erro ao atualizar escola:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Deletar escola
  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { force } = req.query; // Novo parâmetro para forçar exclusão

      // Verificar se a escola existe
      const school = await prisma.school.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              users: true,
              students: true,
              teachers: true,
              classes: true,
              subjects: true,
              events: true,
              chats: true,
              configs: true,
              gradePeriods: true,
              gradeTypes: true,
            },
          },
        },
      });

      if (!school) {
        return res.status(404).json({ error: 'Escola não encontrada' });
      }

      // Se force=true, deletar tudo. Se não, verificar se pode deletar
      if (force === 'true') {
        // Deletar todos os dados associados em ordem (devido às constraints)
        await prisma.$transaction(async (tx) => {
          // Deletar em ordem para respeitar as foreign keys
          await tx.gradeType.deleteMany({ where: { schoolId: id } });
          await tx.gradePeriod.deleteMany({ where: { schoolId: id } });
          await tx.config.deleteMany({ where: { schoolId: id } });
          await tx.chat.deleteMany({ where: { schoolId: id } });
          await tx.event.deleteMany({ where: { schoolId: id } });
          await tx.subject.deleteMany({ where: { schoolId: id } });
          await tx.class.deleteMany({ where: { schoolId: id } });
          await tx.teacher.deleteMany({ where: { schoolId: id } });
          await tx.student.deleteMany({ where: { schoolId: id } });
          await tx.user.deleteMany({ where: { schoolId: id } });
          
          // Por último, deletar a escola
          await tx.school.delete({ where: { id } });
        });

        res.json({ 
          message: 'Escola e todos os dados associados foram deletados com sucesso',
          deletedData: school._count
        });
      } else {
        // Verificar se pode deletar sem forçar
        if (school._count.users > 0 || 
            school._count.students > 0 || 
            school._count.teachers > 0 || 
            school._count.classes > 0) {
          return res.status(400).json({ 
            error: 'Não é possível deletar uma escola que possui dados associados',
            suggestion: 'Use ?force=true para deletar tudo, ou remova os dados primeiro',
            dataCount: school._count
          });
        }

        await prisma.school.delete({ where: { id } });
        res.json({ message: 'Escola deletada com sucesso' });
      }
    } catch (error) {
      console.error('Erro ao deletar escola:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Obter estatísticas da escola
  static async getStats(req: Request, res: Response) {
    try {
      const { id } = req.params;

      // Buscar todas as contagens em paralelo para melhor performance
      const [
        usersCount,
        studentsCount,
        teachersCount,
        adminsCount,
        classesCount,
        subjectsCount,
        eventsCount,
        chatsCount,
        configsCount,
        gradePeriodsCount,
        gradeTypesCount,
      ] = await Promise.all([
        prisma.user.count({ where: { schoolId: id } }),
        prisma.student.count({ where: { schoolId: id } }),
        prisma.teacher.count({ where: { schoolId: id } }),
        prisma.user.count({ where: { schoolId: id, role: 'ADMIN' } }),
        prisma.class.count({ where: { schoolId: id } }),
        prisma.subject.count({ where: { schoolId: id } }),
        prisma.event.count({ where: { schoolId: id } }),
        prisma.chat.count({ where: { schoolId: id } }),
        prisma.config.count({ where: { schoolId: id } }),
        prisma.gradePeriod.count({ where: { schoolId: id } }),
        prisma.gradeType.count({ where: { schoolId: id } }),
      ]);

      const stats = {
        totalUsers: usersCount,
        totalStudents: studentsCount,
        totalTeachers: teachersCount,
        totalAdmins: adminsCount,
        totalClasses: classesCount,
        totalSubjects: subjectsCount,
        totalEvents: eventsCount,
        totalChats: chatsCount,
        totalConfigs: configsCount,
        totalGradePeriods: gradePeriodsCount,
        totalGradeTypes: gradeTypesCount,
      };

      res.json(stats);
    } catch (error) {
      console.error('Erro ao obter estatísticas da escola:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }
}
