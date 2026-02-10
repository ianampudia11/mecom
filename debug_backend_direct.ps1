
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:NODE_ENV = "development"
npm run dev:no-build > backend_direct.log 2>&1
