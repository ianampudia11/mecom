$headers = @{
    "Content-Type" = "application/json"
    "Cookie" = "connect.sid=YOUR_SESSION_COOKIE_HERE"
}

$body = @{
    contactId = 1
    title = "Test Deal After Fix"
    stage = "1"
    value = 1000
    priority = "medium"
    tags = @()
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:9100/api/deals" -Method POST -Headers $headers -Body $body -UseBasicParsing
    Write-Host "Success! Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    Write-Host "Response: $($reader.ReadToEnd())"
}
