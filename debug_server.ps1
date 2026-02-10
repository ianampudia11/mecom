
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:NODE_ENV="development"
npm run dev > debug_output.txt 2>&1
