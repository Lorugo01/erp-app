# 📚 Sistema de Logging Estruturado - Módulo Teacher

## 🎯 Visão Geral

Este documento descreve o sistema de logging estruturado implementado em todos os arquivos da pasta `teacher/` para facilitar o debug e entendimento de erros durante o desenvolvimento e produção.

## 🏗️ Arquitetura do Sistema

### Classes de Logging Implementadas

Cada tela possui sua própria classe de logging com prefixos únicos e métodos especializados:

- **`TeacherClassLogger`** - `🎓 [TeacherClass]` - Para `teacher_class_detail_screen.dart`
- **`TeacherDashboardLogger`** - `🏫 [TeacherDashboard]` - Para `teacher_dashboard_screen.dart`
- **`TeacherStudentDetailLogger`** - `👤 [TeacherStudentDetail]` - Para `teacher_student_detail_screen.dart`
- **`TaskSubmissionsLogger`** - `📝 [TaskSubmissions]` - Para `task_submissions_screen.dart`
- **`TeacherCalendarLogger`** - `📅 [TeacherCalendar]` - Para `teacher_calendar_screen.dart`
- **`TeacherProfileLogger`** - `👨‍🏫 [TeacherProfile]` - Para `teacher_profile_screen.dart`

## 🔧 Métodos Disponíveis

### 1. **`info(String message)`** - ℹ️
Para informações gerais sobre o fluxo da aplicação.

```dart
TeacherClassLogger.info('Inicializando tela de detalhes da turma');
```

### 2. **`success(String message)`** - ✅
Para operações que foram concluídas com sucesso.

```dart
TeacherClassLogger.success('Disciplinas carregadas com sucesso');
```

### 3. **`warning(String message)`** - ⚠️
Para situações que merecem atenção mas não são erros.

```dart
TeacherClassLogger.warning('Tentativa de buscar notas sem disciplina selecionada');
```

### 4. **`error(String message, [dynamic error, StackTrace? stackTrace])`** - ❌
Para erros com detalhes completos incluindo stack trace.

```dart
TeacherClassLogger.error('Erro ao carregar disciplinas', e, stackTrace);
```

### 5. **`debug(String message, [Map<String, dynamic>? data])`** - 🐛
Para informações detalhadas de debug com dados estruturados.

```dart
TeacherClassLogger.debug('Dados da turma recebidos', {
  'classId': widget.classData['id'],
  'className': widget.classData['name'],
  'selectedDate': _selectedDate.toIso8601String(),
});
```

### 6. **`api(String endpoint, String method, [Map<String, dynamic>? params])`** - 🌐
Para logs de chamadas de API.

```dart
TeacherClassLogger.api('/teachers/$teacherId/subjects/class/${widget.classData['id']}', 'GET', {
  'classId': widget.classData['id'],
  'teacherId': teacherId,
});
```

### 7. **`state(String message, [Map<String, dynamic>? state])`** - 🔄
Para mudanças de estado da aplicação.

```dart
TeacherClassLogger.state('Disciplina alterada', {
  'oldSubjectId': _selectedSubjectId,
  'newSubjectId': subjectId,
  'currentTab': _tabController.index,
});
```

### 8. **Métodos Especializados**
Algumas classes possuem métodos específicos para suas funcionalidades:

```dart
// TeacherDashboardLogger
TeacherDashboardLogger.armario('Construindo aba de armários');

// TaskSubmissionsLogger  
TaskSubmissionsLogger.submission('Submissão recebida');

// TeacherCalendarLogger
TeacherCalendarLogger.calendar('Carregando eventos da turma');

// TeacherProfileLogger
TeacherProfileLogger.profile('Atualizando dados do perfil');
```

## 📊 Exemplos de Uso

### Exemplo 1: Carregamento de Dados
```dart
Future<void> _fetchSubjects() async {
  TeacherClassLogger.info('Iniciando busca por disciplinas do professor');
  
  try {
    // ... lógica de busca ...
    
    TeacherClassLogger.success('Disciplinas carregadas com sucesso');
    TeacherClassLogger.debug('Disciplinas encontradas', {
      'count': subjects.length,
      'subjects': subjects.map((s) => {'id': s['id'], 'name': s['name']}).toList(),
    });
    
  } catch (e, stackTrace) {
    TeacherClassLogger.error('Erro ao carregar disciplinas', e, stackTrace);
  }
}
```

### Exemplo 2: Mudança de Estado
```dart
void _onSubjectChanged(String? subjectId) {
  TeacherClassLogger.info('Disciplina alterada');
  TeacherClassLogger.debug('Mudança de disciplina', {
    'oldSubjectId': _selectedSubjectId,
    'newSubjectId': subjectId,
    'currentTab': _tabController.index,
  });
  
  // ... lógica de mudança ...
}
```

### Exemplo 3: Chamada de API
```dart
TeacherClassLogger.api('/attendances/lesson', 'POST', {
  'classId': widget.classData['id'],
  'subjectId': _selectedSubjectId!,
  'teacherId': teacherId,
  'date': _selectedDate.toIso8601String(),
});

final response = await AttendanceService.getOrCreateLesson(/* ... */);
```

## 🎨 Formatação dos Logs

### Estrutura Padrão
```
🎓 [TeacherClass] ℹ️ Iniciando busca por disciplinas do professor
🎓 [TeacherClass] 🐛 Dados da turma recebidos
🎓 [TeacherClass] 📊 Dados: {classId: abc123, className: 3º Ano A}
🎓 [TeacherClass] 🌐 API: GET /teachers/123/subjects/class/abc123
🎓 [TeacherClass] ✅ Disciplinas carregadas com sucesso
🎓 [TeacherClass] ❌ Erro ao carregar disciplinas
🎓 [TeacherClass] 🔍 Erro detalhado: Connection timeout
🎓 [TeacherClass] 📍 Stack trace: StackTrace.current
```

### Cores e Símbolos
- **ℹ️** - Informações gerais (azul)
- **✅** - Sucessos (verde)
- **⚠️** - Avisos (amarelo)
- **❌** - Erros (vermelho)
- **🐛** - Debug (roxo)
- **🌐** - API (azul claro)
- **🔄** - Estado (laranja)
- **📊** - Dados (cinza)

## 🚀 Benefícios

### 1. **Debug Facilitado**
- Logs organizados por funcionalidade
- Informações estruturadas e legíveis
- Stack traces completos para erros

### 2. **Monitoramento em Produção**
- Identificação rápida de problemas
- Rastreamento de fluxo de usuário
- Métricas de performance

### 3. **Manutenção**
- Código mais legível
- Padrões consistentes
- Fácil localização de problemas

### 4. **Colaboração em Equipe**
- Logs padronizados
- Informações contextuais
- Debug remoto facilitado

## 🔍 Filtros e Busca

### Por Funcionalidade
```bash
# Logs de turmas
grep "🎓 \[TeacherClass\]" logs.txt

# Logs de dashboard
grep "🏫 \[TeacherDashboard\]" logs.txt

# Logs de API
grep "🌐 API:" logs.txt
```

### Por Tipo de Log
```bash
# Apenas erros
grep "❌" logs.txt

# Apenas sucessos
grep "✅" logs.txt

# Apenas debug
grep "🐛" logs.txt
```

## 📱 Uso no Flutter

### Console do Flutter
Os logs aparecem no console do Flutter com formatação colorida e organizada.

### DevTools
No Flutter DevTools, os logs são organizados por categoria e podem ser filtrados facilmente.

### Logs de Produção
Em produção, considere usar um sistema de logging mais robusto como:
- Firebase Crashlytics
- Sentry
- LogRocket
- Custom logging service

## 🛠️ Customização

### Adicionar Novos Métodos
```dart
class TeacherClassLogger {
  // ... métodos existentes ...
  
  static void performance(String message, [Duration? duration]) {
    debugPrint('🎓 [TeacherClass] ⚡ $message');
    if (duration != null) {
      debugPrint('🎓 [TeacherClass] ⏱️ Duração: ${duration.inMilliseconds}ms');
    }
  }
}
```

### Mudar Prefixos
```dart
class TeacherClassLogger {
  static const String _prefix = '🎯 [Turma]'; // Novo prefixo
  // ... resto da implementação ...
}
```

## 📋 Checklist de Implementação

- [x] Criar classe de logging para cada tela
- [x] Implementar métodos padrão (info, success, warning, error, debug)
- [x] Adicionar logs em operações críticas
- [x] Incluir dados estruturados nos logs de debug
- [x] Capturar stack traces em erros
- [x] Documentar padrões de uso
- [x] Testar logs em diferentes cenários

## 🔮 Próximos Passos

1. **Implementar em outros módulos** (admin, student, developer)
2. **Adicionar métricas de performance**
3. **Integrar com sistema de monitoramento**
4. **Criar dashboard de logs**
5. **Implementar filtros avançados**

---

**Desenvolvido para o ByLAB ERP**  
**Versão:** 1.0.0  
**Data:** Dezembro 2024
