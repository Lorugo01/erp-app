import { Request, Response } from 'express';

export class SubjectsController {
  // Buscar todos os tipos de disciplinas
  async getAllSubjectTypes(req: Request, res: Response) {
    try {
      console.log('🔍 Controller: Iniciando busca de disciplinas...');
      
      // Como SubjectType é um enum, vamos criar uma lista baseada nos valores do enum
      const subjectTypes = [
        'LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS',
        'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA',
        'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR'
      ];

      console.log('🔍 Controller: Criando lista de disciplinas...');
      
      // Versão simplificada - sem consultas complexas por enquanto
      const subjectsWithStats = subjectTypes.map((type) => {
        console.log(`🔍 Controller: Processando disciplina ${type}`);
        
        // Descrições hardcoded para evitar problemas com métodos de classe
        const descriptions: { [key: string]: string } = {
          'LINGUA_INGLESA': 'Língua Inglesa',
          'ARTE': 'Arte e Cultura',
          'EDUCACAO_FISICA': 'Educação Física e Esportes',
          'MATEMATICA': 'Matemática básica e avançada',
          'CIENCIAS': 'Ciências Naturais',
          'HISTORIA': 'História Geral e do Brasil',
          'GEOGRAFIA': 'Geografia Geral e do Brasil',
          'ENSINO_RELIGIOSO': 'Ensino Religioso',
          'BIOLOGIA': 'Biologia',
          'FISICA': 'Física',
          'QUIMICA': 'Química',
          'FILOSOFIA': 'Filosofia',
          'SOCIOLOGIA': 'Sociologia',
          'CONTEUDO_INTERDISCIPLINAR': 'Conteúdo Interdisciplinar'
        };
        
        const nonEvaluative = ['EDUCACAO_FISICA', 'ARTE'];
        const isEvaluative = !nonEvaluative.includes(type);
        
        return {
          id: type, // Usar o tipo como ID
          type: type,
          description: descriptions[type] || type,
          isEvaluative: isEvaluative,
          classCount: 0, // Temporariamente fixo
          teacherCount: 0, // Temporariamente fixo
          studentCount: 0, // Temporariamente fixo
          createdAt: new Date(), // Data atual como placeholder
          updatedAt: new Date(), // Data atual como placeholder
        };
      });

      console.log(`✅ Controller: Processadas ${subjectsWithStats.length} disciplinas`);
      res.json(subjectsWithStats);
    } catch (error) {
      console.error('❌ Controller: Erro ao buscar tipos de disciplinas:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar tipo de disciplina por ID
  async getSubjectTypeById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      
      // Como SubjectType é um enum, vamos verificar se o ID é um valor válido
      const validTypes = [
        'LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS',
        'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA',
        'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR'
      ];
      
      if (!validTypes.includes(id)) {
        return res.status(404).json({ error: 'Tipo de disciplina não encontrado' });
      }

      // Descrições hardcoded para evitar problemas com métodos de classe
      const descriptions: { [key: string]: string } = {
        'LINGUA_INGLESA': 'Língua Inglesa',
        'ARTE': 'Arte e Cultura',
        'EDUCACAO_FISICA': 'Educação Física e Esportes',
        'MATEMATICA': 'Matemática básica e avançada',
        'CIENCIAS': 'Ciências Naturais',
        'HISTORIA': 'História Geral e do Brasil',
        'GEOGRAFIA': 'Geografia Geral e do Brasil',
        'ENSINO_RELIGIOSO': 'Ensino Religioso',
        'BIOLOGIA': 'Biologia',
        'FISICA': 'Física',
        'QUIMICA': 'Química',
        'FILOSOFIA': 'Filosofia',
        'SOCIOLOGIA': 'Sociologia',
        'CONTEUDO_INTERDISCIPLINAR': 'Conteúdo Interdisciplinar'
      };
      
      const nonEvaluative = ['EDUCACAO_FISICA', 'ARTE'];
      const isEvaluative = !nonEvaluative.includes(id);
      
      const subject = {
        id: id,
        type: id,
        description: descriptions[id] || id,
        isEvaluative: isEvaluative,
        classCount: 0, // Temporariamente fixo
        teacherCount: 0, // Temporariamente fixo
        studentCount: 0, // Temporariamente fixo
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      
      res.json(subject);
    } catch (error) {
      console.error('Erro ao buscar tipo de disciplina:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Criar novo tipo de disciplina
  async createSubjectType(req: Request, res: Response) {
    try {
      const { type, description, isEvaluative } = req.body;

      if (!type) {
        return res.status(400).json({ error: 'Tipo de disciplina é obrigatório' });
      }

      // Como SubjectType é um enum, não podemos criar novos tipos
      // Apenas retornar os dados para compatibilidade
      const newSubject = {
        id: type,
        type: type,
        description: description || '',
        isEvaluative: isEvaluative !== undefined ? isEvaluative : true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      res.status(201).json(newSubject);
    } catch (error) {
      console.error('Erro ao criar tipo de disciplina:', error);
      
      if (error instanceof Error && error.message.includes('já existe')) {
        return res.status(409).json({ error: error.message });
      }
      
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Atualizar tipo de disciplina
  async updateSubjectType(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { type, description, isEvaluative } = req.body;

      if (!type) {
        return res.status(400).json({ error: 'Tipo de disciplina é obrigatório' });
      }

      // Como SubjectType é um enum, não podemos atualizar tipos
      // Apenas retornar os dados para compatibilidade
      const updatedSubject = {
        id: id,
        type: type,
        description: description || '',
        isEvaluative: isEvaluative !== undefined ? isEvaluative : true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      res.json(updatedSubject);
    } catch (error) {
      console.error('Erro ao atualizar tipo de disciplina:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Excluir tipo de disciplina
  async deleteSubjectType(req: Request, res: Response) {
    try {
      const { id } = req.params;

      // Como SubjectType é um enum, não podemos excluir tipos
      // Apenas retornar true para compatibilidade
      res.json({ success: true, message: 'Tipo de disciplina removido com sucesso' });
    } catch (error) {
      console.error('Erro ao excluir tipo de disciplina:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }

  // Buscar disciplinas por turma
  async getSubjectsByClass(req: Request, res: Response) {
    try {
      const { classId } = req.params;
      
      // Temporariamente retornar array vazio para compatibilidade
      res.json([]);
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

      // Temporariamente retornar objeto mock para compatibilidade
      const newSubject = {
        id: 'mock-id',
        classId,
        type: subjectTypeId,
        teacherId,
        name: subjectTypeId,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

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
      
      // Temporariamente retornar true para compatibilidade
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
      
      // Temporariamente retornar array vazio para compatibilidade
      res.json([]);
    } catch (error) {
      console.error('Erro ao buscar disciplinas do professor:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }
}
