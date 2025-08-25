# Teste minimo
Write-Host "Testing lesson API..."

$data = @{
    classId = "test"
    subjectId = "test"
    teacherId = "test"
    date = "2024-01-01T12:00:00.000Z"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/lessons/get-or-create" -Method POST -Body ($data | ConvertTo-Json) -ContentType "application/json"
    Write-Host "Success: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Status: $($_.Exception.Response.StatusCode)"
    
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $content = $reader.ReadToEnd()
        Write-Host "Body: $content"
    }
}

