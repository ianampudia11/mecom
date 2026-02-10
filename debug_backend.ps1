
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:NODE_ENV = "development"
npx tsx server/dev-server.ts > backend_output.txt 2>&1
