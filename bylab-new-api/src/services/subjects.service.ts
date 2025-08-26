export class SubjectsService {
  // Buscar todos os tipos de disciplinas
  async getAllSubjectTypes() {
    try {
      console.log('🔍 Service: Iniciando busca de disciplinas...');
      
      // Como SubjectType é um enum, vamos criar uma lista baseada nos valores do enum
      const subjectTypes = [
        'LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS',
        'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA',
        'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR'
      ];

      console.log('🔍 Service: Criando lista de disciplinas...');
      
      // Versão simplificada - sem consultas complexas por enquanto
      const subjectsWithStats = subjectTypes.map((type) => {
        console.log(`🔍 Service: Processando disciplina ${type}`);
        
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

      console.log(`✅ Service: Processadas ${subjectsWithStats.length} disciplinas`);
      return subjectsWithStats;
    } catch (error) {
      console.error('❌ Service: Erro ao buscar tipos de disciplinas:', error);
      throw error;
    }
  }

  // Buscar tipo de disciplina por ID
  async getSubjectTypeById(id: string) {
    try {
      // Como SubjectType é um enum, vamos verificar se o ID é um valor válido
      const validTypes = [
        'LINGUA_INGLESA', 'ARTE', 'EDUCACAO_FISICA', 'MATEMATICA', 'CIENCIAS',
        'HISTORIA', 'GEOGRAFIA', 'ENSINO_RELIGIOSO', 'BIOLOGIA', 'FISICA',
        'QUIMICA', 'FILOSOFIA', 'SOCIOLOGIA', 'CONTEUDO_INTERDISCIPLINAR'
      ];
      
      if (!validTypes.includes(id)) {
        return null;
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
      
      return {
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
    } catch (error) {
      console.error('Erro ao buscar tipo de disciplina por ID:', error);
      throw error;
    }
  }

  // Criar novo tipo de disciplina
  async createSubjectType(data: {
    type: string;
    description: string;
    isEvaluative: boolean;
  }) {
    try {
      // Como SubjectType é um enum, não podemos criar novos tipos
      // Apenas retornar os dados para compatibilidade
      return {
        id: data.type,
        type: data.type,
        description: data.description,
        isEvaluative: data.isEvaluative,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    } catch (error) {
      console.error('Erro ao criar tipo de disciplina:', error);
      throw error;
    }
  }

  // Atualizar tipo de disciplina
  async updateSubjectType(
    id: string,
    data: {
      type: string;
      description: string;
      isEvaluative: boolean;
    }
  ) {
    try {
      // Como SubjectType é um enum, não podemos atualizar tipos
      // Apenas retornar os dados para compatibilidade
      return {
        id: id,
        type: data.type,
        description: data.description,
        isEvaluative: data.isEvaluative,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    } catch (error) {
      console.error('Erro ao atualizar tipo de disciplina:', error);
      throw error;
    }
  }

  // Verificar se o tipo de disciplina está sendo usado
  async isSubjectTypeInUse(id: string): Promise<boolean> {
    try {
      // Temporariamente retornar false para compatibilidade
      return false;
    } catch (error) {
      console.error('Erro ao verificar se disciplina está em uso:', error);
      throw error;
    }
  }

  // Excluir tipo de disciplina
  async deleteSubjectType(id: string) {
    try {
      // Como SubjectType é um enum, não podemos excluir tipos
      // Apenas retornar true para compatibilidade
      return true;
    } catch (error) {
      console.error('Erro ao excluir tipo de disciplina:', error);
      throw error;
    }
  }

  // Buscar disciplinas de uma turma
  async getSubjectsByClass(classId: string) {
    try {
      // Temporariamente retornar array vazio para compatibilidade
      return [];
    } catch (error) {
      console.error('Erro ao buscar disciplinas da turma:', error);
      throw error;
    }
  }

  // Adicionar disciplina a uma turma
  async addSubjectToClass(
    classId: string,
    subjectTypeId: string,
    teacherId: string
  ) {
    try {
      // Temporariamente retornar objeto mock para compatibilidade
      return {
        id: 'mock-id',
        classId,
        type: subjectTypeId,
        teacherId,
        name: subjectTypeId,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    } catch (error) {
      console.error('Erro ao adicionar disciplina à turma:', error);
      throw error;
    }
  }

  // Remover disciplina de uma turma
  async removeSubjectFromClass(classId: string, subjectId: string) {
    try {
      // Temporariamente retornar true para compatibilidade
      return true;
    } catch (error) {
      console.error('Erro ao remover disciplina da turma:', error);
      throw error;
    }
  }

  // Buscar disciplinas por professor
  async getSubjectsByTeacher(teacherId: string) {
    try {
      // Temporariamente retornar array vazio para compatibilidade
      return [];
    } catch (error) {
      console.error('Erro ao buscar disciplinas do professor:', error);
      throw error;
    }
  }
}
