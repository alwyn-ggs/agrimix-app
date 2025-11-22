# Paano Ayusin ang Google Sign-In Error Code 10

Ang error code 10 (DEVELOPER_ERROR) sa Google Sign-In ay nangyayari kapag may problema sa Firebase configuration. Narito ang step-by-step guide para maayos ito:

## 🔍 Mga Dahilan ng Error Code 10

1. **Walang SHA-1/SHA-256 fingerprint** na naka-configure sa Firebase Console
2. **Walang OAuth client** na naka-setup para sa Android app
3. **Package name mismatch** sa pagitan ng app at Firebase project
4. **Maling google-services.json** file

## ✅ Solusyon: Step-by-Step

### Step 1: Kunin ang SHA-1 at SHA-256 Fingerprints

#### Para sa Debug Build (RECOMMENDED - Direct Method):
```powershell
# Sa PowerShell, i-run ang command na ito:
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**O kung hindi gumana ang $env:USERPROFILE, gamitin:**
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Hanapin sa output ang:**
- `SHA1: XX:XX:XX:...` - Ito ang SHA-1 fingerprint
- `SHA256: XX:XX:XX:...` - Ito ang SHA-256 fingerprint

#### Alternative: Gamit ang Gradle (kung may Java setup):
```powershell
cd android
.\gradlew signingReport
```

#### Para sa Release Build:
Kung may release keystore ka:
```powershell
keytool -list -v -keystore "path\to\your\release.keystore" -alias your-key-alias
```

**Kopyahin ang SHA-1 at SHA-256 fingerprints** mula sa output.

---

## 📋 **YOUR CURRENT FINGERPRINTS** (Debug Build):

**SHA-1:** `0A:0C:BC:AE:36:94:17:F2:D7:C5:07:15:98:42:A2:7E:2A:85:13:A3`

**SHA-256:** `E5:12:A5:2B:C6:5A:10:B3:87:C9:E7:6A:02:47:2F:E5:23:E1:08:50:C6:7E:D1:CC:F4:C0:C2:48:DC:17:C5:4D`

**I-copy ang dalawang fingerprints na ito at i-add sa Firebase Console!**

---

### Step 2: I-configure sa Firebase Console

1. **Pumunta sa Firebase Console**: https://console.firebase.google.com/
2. **Piliin ang project mo** (storageapp-9a33b)
3. **Pumunta sa Project Settings** (gear icon sa sidebar)
4. **Scroll down sa "Your apps" section**
5. **Piliin ang Android app** (`com.example.agrimix`)
6. **I-click ang "Add fingerprint"** button
7. **I-paste ang SHA-1 fingerprint** na nakuha mo
8. **I-click "Add fingerprint" ulit** at i-paste ang **SHA-256 fingerprint**
9. **I-save ang changes**

### Step 3: I-download ang Bagong google-services.json

1. **Sa Firebase Console**, sa Project Settings
2. **Scroll down sa "Your apps" section**
3. **I-click ang "google-services.json"** download button
4. **I-replace ang lumang file** sa `android/app/google-services.json`
5. **Siguraduhin na may OAuth client** na naka-configure (hindi dapat empty ang `oauth_client` array)

### Step 4: I-verify ang OAuth Client Configuration

1. **Pumunta sa Google Cloud Console**: https://console.cloud.google.com/
2. **Piliin ang project mo** (storageapp-9a33b)
3. **Pumunta sa "APIs & Services" > "Credentials"**
4. **Hanapin ang "OAuth 2.0 Client IDs"**
5. **Dapat may Android client** na naka-configure para sa package name `com.example.agrimix`
6. **Kung wala, i-create:**
   - I-click "Create Credentials" > "OAuth client ID"
   - Piliin "Android"
   - Ilagay ang package name: `com.example.agrimix`
   - Ilagay ang SHA-1 fingerprint
   - I-click "Create"

### Step 5: I-clean at I-rebuild ang App

```powershell
# Sa project root directory
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
flutter run
```

## 🔧 Alternative: Manual Configuration ng GoogleSignIn

Kung hindi pa rin gumana, maaari mong i-configure manually ang GoogleSignIn sa code:

1. **Kunin ang Web Client ID** mula sa Firebase Console:
   - Pumunta sa Project Settings > Your apps
   - I-click ang Web app (kung wala, i-create muna)
   - Kopyahin ang "Web client ID"

2. **I-update ang `auth_provider.dart`**:

```dart
// Sa signInWithGoogle() method, palitan ang:
final googleUser = await GoogleSignIn().signIn();

// Ng:
final googleUser = await GoogleSignIn(
  scopes: ['email', 'profile'],
).signIn();
```

O kung may Web Client ID ka:
```dart
final googleUser = await GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
).signIn();
```

## ✅ Verification Checklist

- [ ] SHA-1 fingerprint naka-add sa Firebase Console
- [ ] SHA-256 fingerprint naka-add sa Firebase Console
- [ ] OAuth client naka-configure sa Google Cloud Console
- [ ] Bagong google-services.json na-download at naka-replace
- [ ] Package name match (`com.example.agrimix`)
- [ ] App na-clean at na-rebuild
- [ ] Google Sign-In enabled sa Firebase Authentication

## 🆘 Troubleshooting

### Kung hindi pa rin gumana:

1. **I-check ang logs**:
   ```powershell
   flutter run --verbose
   ```

2. **I-verify ang google-services.json**:
   - Dapat may `oauth_client` array na hindi empty
   - Dapat match ang `package_name` sa `build.gradle.kts`

3. **I-check ang Firebase Authentication**:
   - Pumunta sa Firebase Console > Authentication > Sign-in method
   - Siguraduhin na **Google** ay **Enabled**

4. **I-try ang Release Build**:
   - Minsan kailangan ng release keystore fingerprint din

## 📝 Notes

- **Important**: Pagkatapos mag-add ng fingerprint, maghintay ng 5-10 minutes bago mag-test ulit
- **Debug at Release**: Parehong kailangan ng fingerprints kung magde-deploy ka ng release build
- **Package Name**: Dapat consistent sa lahat ng lugar (build.gradle.kts, AndroidManifest.xml, Firebase)

