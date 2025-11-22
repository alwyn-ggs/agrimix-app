@echo off
echo ========================================
echo Getting SHA-1 and SHA-256 Fingerprints
echo ========================================
echo.

set KEYSTORE=%USERPROFILE%\.android\debug.keystore

if exist "%KEYSTORE%" (
    echo Debug keystore found!
    echo.
    echo Running keytool...
    echo.
    
    keytool -list -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android
    
    echo.
    echo ========================================
    echo Instructions:
    echo 1. Copy the SHA-1 and SHA-256 fingerprints above
    echo 2. Go to Firebase Console ^> Project Settings ^> Your apps
    echo 3. Select your Android app (com.example.agrimix)
    echo 4. Click 'Add fingerprint' and paste each fingerprint
    echo 5. Download the new google-services.json file
    echo 6. Replace android/app/google-services.json
    echo ========================================
) else (
    echo Debug keystore not found at: %KEYSTORE%
    echo.
    echo The debug keystore will be created automatically when you:
    echo 1. Run 'flutter run' for the first time, OR
    echo 2. Build the app in Android Studio
)

echo.
pause

