# Teste completo da funcionalidade de attendance
Write-Host "🧪 TESTE COMPLETO DE ATTENDANCE" -ForegroundColor Green

# 1. Criar lesson
Write-Host "`n=== CRIANDO LESSON ===" -ForegroundColor Yellow
$lessonData = @{
    classId = "test"
    subjectId = "test"
    teacherId = "test"
    date = "2024-01-01T12:00:00.000Z"
}

$lesson = Invoke-RestMethod -Uri "http://localhost:3000/lessons/get-or-create" -Method POST -Body ($lessonData | ConvertTo-Json) -ContentType "application/json"
Write-Host "✅ Lesson criada: $($lesson.id)" -ForegroundColor Green

# 2. Criar attendance
Write-Host "`n=== CRIANDO ATTENDANCE ===" -ForegroundColor Yellow
$attendanceData = @{
    lessonId = $lesson.id
    presences = @(
        @{
            studentId = "test-student-1"
            status = "PRESENT"
            justification = $null
            present = $true
        },
        @{
            studentId = "test-student-2"
            status = "ABSENT"
            justification = $null
            present = $false
        }
    )
}

try {
    $attendance = Invoke-RestMethod -Uri "http://localhost:3000/attendances/bulk" -Method POST -Body ($attendanceData | ConvertTo-Json -Depth 3) -ContentType "application/json"
    Write-Host "✅ Attendance criada: $($attendance.Count) registros" -ForegroundColor Green
    
    # 3. Buscar attendance
    Write-Host "`n=== BUSCANDO ATTENDANCE ===" -ForegroundColor Yellow
    $getAttendance = Invoke-RestMethod -Uri "http://localhost:3000/attendances/lesson/$($lesson.id)" -Method GET
    Write-Host "✅ Attendance encontrada: $($getAttendance.Count) registros" -ForegroundColor Green
    
    foreach ($att in $getAttendance) {
        Write-Host "   - Student: $($att.student.name), Status: $($att.status)" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Erro no attendance: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $content = $reader.ReadToEnd()
        Write-Host "Body: $content" -ForegroundColor Red
    }
}

Write-Host "`n🏁 TESTE COMPLETO CONCLUÍDO" -ForegroundColor Green

