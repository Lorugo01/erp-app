# Script PowerShell para testar APIs de Attendance
Write-Host "🧪 TESTANDO APIs DE ATTENDANCE/LESSON" -ForegroundColor Green
Write-Host "Base URL: http://localhost:3000" -ForegroundColor Cyan

# Testar health check primeiro
Write-Host "`n=== TESTANDO HEALTH CHECK ===" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET -ErrorAction Stop
    Write-Host "✅ Health check OK: $healthResponse" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check falhou: $($_.Exception.Message)" -ForegroundColor Red
}

# Dados de teste
$testData = @{
    classId = "test-class-id"
    subjectId = "test-subject-id"
    teacherId = "test-teacher-id"
    date = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Testar lesson get-or-create sem auth
Write-Host "`n=== TESTANDO LESSON GET-OR-CREATE (SEM AUTH) ===" -ForegroundColor Yellow
try {
    $lessonResponse = Invoke-RestMethod -Uri "http://localhost:3000/lessons/get-or-create" -Method POST -Body ($testData | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ Lesson criada/encontrada: $($lessonResponse | ConvertTo-Json)" -ForegroundColor Green
    $lessonId = $lessonResponse.id
} catch {
    Write-Host "❌ Erro ao criar/buscar lesson:" -ForegroundColor Red
    Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "   Message: $($_.Exception.Message)" -ForegroundColor Red
    $lessonId = $null
}

# Se lesson foi criada, testar attendance
if ($lessonId) {
    Write-Host "`n=== TESTANDO ATTENDANCE BULK ===" -ForegroundColor Yellow
    
    $attendanceData = @{
        lessonId = $lessonId
        presences = @(
            @{
                studentId = "student-1"
                status = "PRESENT"
                justification = $null
                present = $true
            },
            @{
                studentId = "student-2"
                status = "ABSENT"
                justification = $null
                present = $false
            }
        )
    }
    
    try {
        $attendanceResponse = Invoke-RestMethod -Uri "http://localhost:3000/attendances/bulk" -Method POST -Body ($attendanceData | ConvertTo-Json -Depth 3) -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ Frequência salva em bulk: $($attendanceResponse | ConvertTo-Json)" -ForegroundColor Green
        
        # Testar get attendance by lesson
        Write-Host "`n=== TESTANDO GET ATTENDANCE BY LESSON ===" -ForegroundColor Yellow
        try {
            $getAttendanceResponse = Invoke-RestMethod -Uri "http://localhost:3000/attendances/lesson/$lessonId" -Method GET -ErrorAction Stop
            Write-Host "✅ Frequência carregada: $($getAttendanceResponse | ConvertTo-Json)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Erro ao carregar frequência:" -ForegroundColor Red
            Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            Write-Host "   Message: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ Erro ao salvar frequência bulk:" -ForegroundColor Red
        Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "   Message: $($_.Exception.Message)" -ForegroundColor Red
        
        # Verificar detalhes do erro
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Response Body: $responseBody" -ForegroundColor Red
        }
    }
}

Write-Host "`n🏁 TESTES CONCLUÍDOS" -ForegroundColor Green

