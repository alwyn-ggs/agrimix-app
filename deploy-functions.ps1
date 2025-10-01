# AgriMix Cloud Functions Deployment Script
Write-Host "Setting up AgriMix Cloud Functions..." -ForegroundColor Green

# Navigate to functions directory
Set-Location functions

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install

# Build the functions
Write-Host "Building functions..." -ForegroundColor Yellow
npm run build

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORTANT: Configure your email settings!" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "For Gmail (testing):" -ForegroundColor White
Write-Host 'firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"' -ForegroundColor Gray
Write-Host ""
Write-Host "For SendGrid (production):" -ForegroundColor White
Write-Host 'firebase functions:config:set email.user="apikey" email.password="your-sendgrid-api-key"' -ForegroundColor Gray
Write-Host ""
Write-Host "After configuring email, run:" -ForegroundColor White
Write-Host "firebase deploy --only functions" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
