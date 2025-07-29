# Sistema de Atualização Automática de Dados

Este documento explica como usar a funcionalidade de atualização automática de dados implementada no sistema ByLAB ERP.

## 🎯 Funcionalidades Implementadas

### 1. **AuthProvider** - Atualização de Dados do Usuário
- `refreshUserData()`: Busca dados atualizados do usuário atual do backend
- `updateUserData()`: Atualiza dados do usuário após edição
- Sincronização automática com SharedPreferences

### 2. **DataProvider** - Gerenciamento de Dados Atualizáveis
- `refreshCurrentTeacher()`: Atualiza dados do professor atual
- `refreshCurrentStudent()`: Atualiza dados do aluno atual
- `refreshTeachers()`: Atualiza lista de professores
- `refreshStudents()`: Atualiza lista de alunos
- `updateTeacherData()`: Atualiza dados do professor após edição
- `updateTeacherPhoto()`: Atualiza foto do professor
- `updateUserData()`: Atualiza dados do usuário
- `updateUserPhoto()`: Atualiza foto do usuário

### 3. **Widgets de Atualização**
- `DataRefreshWidget`: Widget wrapper para atualização automática
- `SpecificDataRefreshWidget`: Widget para atualização específica
- `DataRefreshMixin`: Mixin para facilitar atualização em StatefulWidgets
- `AutoRefreshWidget`: Widget para atualização automática simples
- `AutoRefreshMixin`: Mixin alternativo para atualizações
- `LoadingOverlay`: Widget para mostrar loading durante atualizações
- `AutoRefreshDataWidget`: Widget para dados com atualização automática

## 🚀 Como Usar

### 1. **Configuração no main.dart**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => DataProvider()),
  ],
  child: MaterialApp(...),
)
```

### 2. **Usando o DataRefreshWidget**
```dart
DataRefreshWidget(
  onDataRefreshed: () {
    // Callback executado após atualização
    print('Dados atualizados!');
  },
  child: Scaffold(
    // Sua tela aqui
  ),
)
```

### 3. **Usando o AutoRefreshWidget (Mais Simples)**
```dart
AutoRefreshWidget(
  teacherId: 'teacher-id',
  onDataRefreshed: () {
    print('Professor atualizado!');
  },
  child: Scaffold(
    // Sua tela aqui
  ),
)
```

### 4. **Usando o DataRefreshMixin**
```dart
class _MyScreenState extends State<MyScreen> with DataRefreshMixin {
  
  Future<void> _updateData() async {
    // Atualizar dados do usuário
    await refreshUserData();
    
    // Atualizar dados específicos
    await refreshTeacherData('teacher-id');
    await refreshStudentData('student-id');
    
    // Atualizar todos os dados
    await refreshAllData();
    
    // Mostrar feedback
    showRefreshSnackBar('Dados atualizados!');
  }
}
```

### 5. **Usando o AutoRefreshMixin (Alternativo)**
```dart
class _MyScreenState extends State<MyScreen> with AutoRefreshMixin {
  
  Future<void> _updateData() async {
    await refreshTeacherData('teacher-id');
    showSuccessMessage('Dados atualizados!');
  }
}
```

### 6. **Exemplo de Tela com Atualização Completa**
```dart
class TeacherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  
  const TeacherDetailScreen({super.key, required this.teacher});
  
  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen>
    with DataRefreshMixin {
  
  Future<void> _updateTeacherData(Map<String, dynamic> updatedData) async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Atualizar dados do professor no DataProvider
      await dataProvider.updateTeacherData(widget.teacher['id'], updatedData);

      // Atualizar dados do usuário se necessário
      if (authProvider.user != null) {
        await authProvider.refreshUserData();
      }

      // Atualizar dados locais da tela
      setState(() {
        widget.teacher['name'] = updatedData['name'];
        widget.teacher['email'] = updatedData['email'];
        if (updatedData['photoUrl'] != null) {
          widget.teacher['photoUrl'] = updatedData['photoUrl'];
        }
      });

      showRefreshSnackBar('Professor atualizado com sucesso!');
    } catch (e) {
      showErrorSnackBar('Erro ao atualizar professor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataRefreshWidget(
      onDataRefreshed: () {
        // Recarregar dados da tela
        _fetchTeacherDetails();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Professor: ${widget.teacher['name']}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await refreshTeacherData(widget.teacher['id']);
                _fetchTeacherDetails();
              },
            ),
          ],
        ),
        body: // Sua interface aqui
      ),
    );
  }
}
```

### 7. **Usando LoadingOverlay**
```dart
LoadingOverlay(
  isLoading: _isLoading,
  message: 'Atualizando dados...',
  child: Scaffold(
    // Sua tela aqui
  ),
)
```

### 8. **Usando AutoRefreshDataWidget**
```dart
AutoRefreshDataWidget<Map<String, dynamic>>(
  dataLoader: () => TeacherService.getTeacherById('teacher-id'),
  builder: (teacher) => TeacherCard(teacher: teacher),
  errorBuilder: (error) => ErrorWidget(error: error),
  loadingWidget: const Center(child: CircularProgressIndicator()),
)
```

## 📋 Serviços Atualizados

### **UserService**
- `updateUser()`: Atualiza dados do usuário
- `updateUserPhoto()`: Atualiza foto do usuário
- `getUserById()`: Busca usuário por ID

### **TeacherService**
- `getTeacherById()`: Busca professor por ID
- `updateTeacher()`: Atualiza dados do professor
- `updateTeacherPhoto()`: Atualiza foto do professor
- `refreshTeacherData()`: Busca dados atualizados do professor

## 🔄 Fluxo de Atualização

1. **Usuário faz alteração** (nome, foto, etc.)
2. **Chamada para API** via Service
3. **Atualização do Provider** com novos dados
4. **Notificação dos Widgets** via notifyListeners()
5. **Atualização da UI** automaticamente
6. **Feedback visual** via SnackBar

## 🎨 Exemplos de Uso

### **Atualizar Nome do Professor**
```dart
// No TeacherService
await TeacherService.updateTeacher(teacherId, {
  'name': 'Novo Nome do Professor'
});

// No DataProvider
await dataProvider.updateTeacherData(teacherId, {
  'name': 'Novo Nome do Professor'
});
```

### **Atualizar Foto do Usuário**
```dart
// No UserService
await UserService.updateUserPhoto(userId, '/uploads/nova-foto.jpg');

// No AuthProvider
await authProvider.refreshUserData();
```

### **Atualizar Dados do Aluno**
```dart
// No DataProvider
await dataProvider.refreshCurrentStudent(studentId);
await dataProvider.refreshStudents(); // Atualizar lista
```

## ⚡ Benefícios

1. **Sincronização Automática**: Dados sempre atualizados
2. **Feedback Visual**: SnackBars informativos
3. **Tratamento de Erros**: Mensagens de erro claras
4. **Performance**: Atualização seletiva de dados
5. **Reutilização**: Widgets e Mixins reutilizáveis
6. **Consistência**: Dados consistentes entre telas
7. **Flexibilidade**: Múltiplas opções de implementação

## 🔧 Configuração

### **Adicionar ao pubspec.yaml**
```yaml
dependencies:
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  http: ^1.1.0
```

### **Importar nos arquivos**
```dart
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'widgets/data_refresh_widget.dart';
import 'widgets/auto_refresh_widget.dart';
```

## 📝 Notas Importantes

1. **Sempre use try-catch** para tratar erros de rede
2. **Mostre feedback visual** para o usuário
3. **Atualize dados relacionados** quando necessário
4. **Use o DataRefreshWidget** para telas que precisam de atualização automática
5. **Implemente o DataRefreshMixin** para facilitar atualizações em StatefulWidgets
6. **Use AutoRefreshWidget** para atualizações simples
7. **Use LoadingOverlay** para mostrar loading durante atualizações

## 🚨 Tratamento de Erros

```dart
try {
  await dataProvider.updateTeacherData(teacherId, data);
  showRefreshSnackBar('Dados atualizados!');
} catch (e) {
  showErrorSnackBar('Erro ao atualizar: $e');
}
```

## 🆕 Novidades Implementadas

### **TeacherDetailScreen Atualizada**
- ✅ Integração com DataProvider e AuthProvider
- ✅ Atualização automática após edição
- ✅ Botão de refresh manual
- ✅ Feedback visual de sucesso/erro
- ✅ Sincronização com outras telas

### **Widgets Adicionais**
- ✅ `AutoRefreshWidget`: Atualização simples
- ✅ `AutoRefreshMixin`: Mixin alternativo
- ✅ `LoadingOverlay`: Loading durante atualizações
- ✅ `AutoRefreshDataWidget`: Dados com atualização automática

Esta implementação garante que os dados sejam sempre atualizados automaticamente quando houver mudanças no backend, proporcionando uma experiência de usuário fluida e consistente.