@echo off
echo Setting up AgriMix Cloud Functions...

cd functions

echo Installing dependencies...
npm install

echo.
echo ========================================
echo IMPORTANT: Configure your email settings first!
echo ========================================
echo.
echo For Gmail (testing):
echo firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"
echo.
echo For SendGrid (production):
echo firebase functions:config:set email.user="apikey" email.password="your-sendgrid-api-key"
echo.
echo After configuring, run:
echo firebase deploy --only functions
echo.
pause
