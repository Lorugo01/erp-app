# Debug test para identificar o problema
Write-Host "🔍 DEBUG DAS APIs DE ATTENDANCE/LESSON" -ForegroundColor Green

# 1. Testar lesson get-or-create direto (sem auth)
Write-Host "`n=== TESTANDO LESSON GET-OR-CREATE DIRETO ===" -ForegroundColor Yellow

$testLessonData = @{
    classId = "test-class"
    subjectId = "test-subject"
    teacherId = "test-teacher"
    date = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

Write-Host "Dados para lesson: $($testLessonData | ConvertTo-Json)" -ForegroundColor Cyan

try {
    $lessonResponse = Invoke-RestMethod -Uri "http://localhost:3000/lessons/get-or-create" -Method POST -Body ($testLessonData | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ Lesson criada: $($lessonResponse | ConvertTo-Json)" -ForegroundColor Green
    $lessonId = $lessonResponse.id
} catch {
    Write-Host "❌ Erro ao criar lesson:" -ForegroundColor Red
    Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "   Message: $($_.Exception.Message)" -ForegroundColor Red
    
    # Capturar resposta de erro detalhada
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Response Body: $responseBody" -ForegroundColor Red
        } catch {
            Write-Host "   Não foi possível ler o response body" -ForegroundColor Red
        }
    }
    $lessonId = $null
}

# 2. Testar attendance bulk direto
if ($lessonId) {
    Write-Host "`n=== TESTANDO ATTENDANCE BULK DIRETO ===" -ForegroundColor Yellow
    
    $testAttendanceData = @{
        lessonId = $lessonId
        presences = @(
            @{
                studentId = "test-student"
                status = "PRESENT"
                justification = $null
                present = $true
            }
        )
    }
    
    Write-Host "Dados para attendance: $($testAttendanceData | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
    
    try {
        $attendanceResponse = Invoke-RestMethod -Uri "http://localhost:3000/attendances/bulk" -Method POST -Body ($testAttendanceData | ConvertTo-Json -Depth 3) -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ Attendance criada: $($attendanceResponse | ConvertTo-Json)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao criar attendance:" -ForegroundColor Red
        Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "   Message: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "   Response Body: $responseBody" -ForegroundColor Red
            } catch {
                Write-Host "   Não foi possível ler o response body" -ForegroundColor Red
            }
        }
    }
}

# 3. Testar GET de attendances existentes (deve funcionar)
Write-Host "`n=== TESTANDO GET ATTENDANCES EXISTENTES ===" -ForegroundColor Yellow
try {
    $existingAttendances = Invoke-RestMethod -Uri "http://localhost:3000/attendances" -Method GET -ErrorAction Stop
    Write-Host "✅ Attendances existentes: $($existingAttendances.Count)" -ForegroundColor Green
    if ($existingAttendances.Count -gt 0) {
        $firstAttendance = $existingAttendances[0]
        Write-Host "   Primeira attendance: lesson=$($firstAttendance.lessonId), student=$($firstAttendance.studentId)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Erro ao buscar attendances: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 DEBUG CONCLUÍDO" -ForegroundColor Green

