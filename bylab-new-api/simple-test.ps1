# Teste simples das APIs
Write-Host "🧪 TESTE SIMPLES DAS APIs" -ForegroundColor Green

# 1. Testar rota básica
Write-Host "`n=== TESTANDO ROTA BÁSICA ===" -ForegroundColor Yellow
try {
    $basicResponse = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET -ErrorAction Stop
    Write-Host "✅ Rota básica OK: $basicResponse" -ForegroundColor Green
} catch {
    Write-Host "❌ Rota básica falhou: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Testar GET attendances (vazio)
Write-Host "`n=== TESTANDO GET ATTENDANCES ===" -ForegroundColor Yellow
try {
    $attendancesResponse = Invoke-RestMethod -Uri "http://localhost:3000/attendances" -Method GET -ErrorAction Stop
    Write-Host "✅ GET attendances OK: $($attendancesResponse.Count) items" -ForegroundColor Green
} catch {
    Write-Host "❌ GET attendances falhou: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response Body: $responseBody" -ForegroundColor Red
    }
}

# 3. Testar com dados válidos conhecidos do banco
Write-Host "`n=== TESTANDO COM DADOS REAIS DO BANCO ===" -ForegroundColor Yellow

# Primeiro buscar classes existentes
try {
    $classesResponse = Invoke-RestMethod -Uri "http://localhost:3000/classes" -Method GET -ErrorAction Stop
    Write-Host "✅ Classes encontradas: $($classesResponse.Count)" -ForegroundColor Green
    
    if ($classesResponse.Count -gt 0) {
        $firstClass = $classesResponse[0]
        Write-Host "   Primeira classe: $($firstClass.name) (ID: $($firstClass.id))" -ForegroundColor Cyan
        
        # Buscar professores
        $teachersResponse = Invoke-RestMethod -Uri "http://localhost:3000/teachers" -Method GET -ErrorAction Stop
        Write-Host "✅ Professores encontrados: $($teachersResponse.Count)" -ForegroundColor Green
        
        if ($teachersResponse.Count -gt 0) {
            $firstTeacher = $teachersResponse[0]
            Write-Host "   Primeiro professor: $($firstTeacher.name) (ID: $($firstTeacher.id))" -ForegroundColor Cyan
            
            # Buscar subjects
            $subjectsResponse = Invoke-RestMethod -Uri "http://localhost:3000/subjects" -Method GET -ErrorAction Stop
            Write-Host "✅ Subjects encontrados: $($subjectsResponse.Count)" -ForegroundColor Green
            
            if ($subjectsResponse.Count -gt 0) {
                $firstSubject = $subjectsResponse[0]
                Write-Host "   Primeira subject: $($firstSubject.name) (ID: $($firstSubject.id))" -ForegroundColor Cyan
                
                # Agora testar lesson get-or-create com dados reais
                $realLessonData = @{
                    classId = $firstClass.id
                    subjectId = $firstSubject.id
                    teacherId = $firstTeacher.id
                    date = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
                
                Write-Host "`n   Testando lesson com dados reais..." -ForegroundColor Cyan
                try {
                    $realLessonResponse = Invoke-RestMethod -Uri "http://localhost:3000/lessons/get-or-create" -Method POST -Body ($realLessonData | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
                    Write-Host "✅ Lesson criada com dados reais: $($realLessonResponse.id)" -ForegroundColor Green
                    
                    # Buscar students da classe
                    $studentsResponse = Invoke-RestMethod -Uri "http://localhost:3000/students" -Method GET -ErrorAction Stop
                    Write-Host "✅ Students encontrados: $($studentsResponse.Count)" -ForegroundColor Green
                    
                    if ($studentsResponse.Count -gt 0) {
                        $firstStudent = $studentsResponse[0]
                        Write-Host "   Primeiro student: $($firstStudent.name) (ID: $($firstStudent.id))" -ForegroundColor Cyan
                        
                        # Testar attendance bulk com dados reais
                        $realAttendanceData = @{
                            lessonId = $realLessonResponse.id
                            presences = @(
                                @{
                                    studentId = $firstStudent.id
                                    status = "PRESENT"
                                    justification = $null
                                    present = $true
                                }
                            )
                        }
                        
                        Write-Host "`n   Testando attendance bulk com dados reais..." -ForegroundColor Cyan
                        try {
                            $realAttendanceResponse = Invoke-RestMethod -Uri "http://localhost:3000/attendances/bulk" -Method POST -Body ($realAttendanceData | ConvertTo-Json -Depth 3) -ContentType "application/json" -ErrorAction Stop
                            Write-Host "✅ Attendance bulk criada com dados reais!" -ForegroundColor Green
                            Write-Host "   Created: $($realAttendanceResponse.Count) attendances" -ForegroundColor Cyan
                        } catch {
                            Write-Host "❌ Attendance bulk falhou: $($_.Exception.Message)" -ForegroundColor Red
                            if ($_.Exception.Response) {
                                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                                $responseBody = $reader.ReadToEnd()
                                Write-Host "   Response Body: $responseBody" -ForegroundColor Red
                            }
                        }
                    }
                } catch {
                    Write-Host "❌ Lesson com dados reais falhou: $($_.Exception.Message)" -ForegroundColor Red
                    if ($_.Exception.Response) {
                        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                        $responseBody = $reader.ReadToEnd()
                        Write-Host "   Response Body: $responseBody" -ForegroundColor Red
                    }
                }
            }
        }
    }
} catch {
    Write-Host "❌ Erro ao buscar dados do banco: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 TESTE SIMPLES CONCLUÍDO" -ForegroundColor Green

