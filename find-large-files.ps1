Get-ChildItem -Recurse -File | 
Where-Object { 
    $_.FullName -notmatch 'node_modules' -and 
    $_.FullName -notmatch '\.git' -and 
    $_.Extension -match '\.(ts|js|tsx|jsx)$' 
} | 
Sort-Object Length -Descending | 
Select-Object -First 20 | 
ForEach-Object { 
    $sizeKB = [math]::Round($_.Length / 1KB, 1)
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Host ("{0,8} KB ({1,5} MB) - {2}" -f $sizeKB, $sizeMB, $_.FullName)
}
