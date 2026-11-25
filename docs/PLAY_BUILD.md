# Google Play internal testing build

The Play package is com.abdulrahmanalsaeed.madaralhuda, separate from .dev and .preview. Never reuse the Obtainium signing key. Use Google Play App Signing with a separate upload key. Generate it once locally (JDK keytool), keep an encrypted offline backup and never commit the keystore or password.

```powershell
keytool -genkeypair -v -keystore "$HOME\madar-play-upload.p12" -storetype PKCS12 -alias madar-play -keyalg RSA -keysize 2048 -validity 10000
```

Add repository Actions secrets MADAR_PLAY_KEYSTORE_BASE64 (base64 of the entire file), MADAR_PLAY_KEYSTORE_PASSWORD (the PKCS12 password), MADAR_PLAY_KEY_ALIAS (madar-play). In PowerShell, copy the encoded file directly to clipboard with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\madar-play-upload.p12")) | Set-Clipboard
```

Clear the clipboard after saving. Do not paste secrets in chat or repository files. Existing public configuration variables MADAR_QURAN_API_URL and MADAR_SUPABASE_ANON_KEY must be set.

On main, Actions > Play Store AAB > Run workflow. First unused version code 1, increase for every subsequent upload. Download artifact madar-play-aab-1 and extract the .aab, verify SHA256SUMS, then manually upload to Internal testing. Choose Google-generated app signing key at first release. No publishing occurs in the workflow. Confirm the Play app-signing certificate for Android App Links. Test guest and Google sign-in, audio, reminders, location, feedback and privacy requests on the actual Play-distributed build, including a 16 KB device. Content rights, scholarly review, children policy and final Data Safety review remain separate gates; not approved for public release by this workflow.