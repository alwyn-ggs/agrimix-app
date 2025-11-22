# PowerShell script para makuha ang SHA-1 at SHA-256 fingerprints
# Para sa Android Debug Keystore
#
# KUNG MAY EXECUTION POLICY ERROR:
# I-run ang command na ito muna:
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
# O kaya i-run ang script gamit:
#   powershell -ExecutionPolicy Bypass -File .\get-sha1.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Getting SHA-1 and SHA-256 Fingerprints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    Write-Host "Debug keystore found at: $debugKeystore" -ForegroundColor Green
    Write-Host ""
    Write-Host "Running keytool..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get SHA-1 and SHA-256
    $output = & keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $output
        
        # Extract SHA-1
        $sha1Match = $output | Select-String -Pattern "SHA1:\s+([A-F0-9:]+)"
        if ($sha1Match) {
            $sha1 = $sha1Match.Matches[0].Groups[1].Value
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "SHA-1 Fingerprint:" -ForegroundColor Green
            Write-Host $sha1 -ForegroundColor White
            Write-Host "========================================" -ForegroundColor Green
        }
        
        # Extract SHA-256
        $sha256Match = $output | Select-String -Pattern "SHA256:\s+([A-F0-9:]+)"
        if ($sha256Match) {
            $sha256 = $sha256Match.Matches[0].Groups[1].Value
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "SHA-256 Fingerprint:" -ForegroundColor Green
            Write-Host $sha256 -ForegroundColor White
            Write-Host "========================================" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "Instructions:" -ForegroundColor Cyan
        Write-Host "1. Copy the SHA-1 and SHA-256 fingerprints above" -ForegroundColor Yellow
        Write-Host "2. Go to Firebase Console > Project Settings > Your apps" -ForegroundColor Yellow
        Write-Host "3. Select your Android app (com.example.agrimix)" -ForegroundColor Yellow
        Write-Host "4. Click 'Add fingerprint' and paste each fingerprint" -ForegroundColor Yellow
        Write-Host "5. Download the new google-services.json file" -ForegroundColor Yellow
        Write-Host "6. Replace android/app/google-services.json" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "Error running keytool. Make sure Java JDK is installed." -ForegroundColor Red
    }
} else {
    Write-Host "Debug keystore not found at: $debugKeystore" -ForegroundColor Red
    Write-Host ""
    Write-Host "The debug keystore will be created automatically when you:" -ForegroundColor Yellow
    Write-Host "1. Run 'flutter run' for the first time, OR" -ForegroundColor Yellow
    Write-Host "2. Build the app in Android Studio" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

