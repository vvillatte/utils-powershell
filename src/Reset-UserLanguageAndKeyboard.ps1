Write-Host "Starting per-user language + keyboard cleanup..." -ForegroundColor Cyan

# ============================================================
# 1. REMOVE ALL INSTALLED LEPs FOR CURRENT USER
# ============================================================
Write-Host "`nRemoving installed Local Experience Packs (current user only)..." -ForegroundColor Yellow

Get-AppxPackage *LanguageExperiencePack* |
    ForEach-Object {
        Write-Host "Removing LEP: $($_.PackageFullName)"
        Remove-AppxPackage -Package $_.PackageFullName
    }

# ============================================================
# 2. SET USER LANGUAGE LIST TO EN-AU + EN-GB
# ============================================================
Write-Host "`nSetting user language list to EN-AU + EN-GB..." -ForegroundColor Yellow

$LangList = New-WinUserLanguageList en-AU
$LangList.Add("en-GB")
Set-WinUserLanguageList $LangList -Force

# ============================================================
# 3. REMOVE ALL KEYBOARDS (MODERN + LEGACY + SUBSTITUTES)
# ============================================================
Write-Host "`nRemoving all keyboard layouts (modern + legacy + substitutes)..." -ForegroundColor Yellow

# Remove modern TIPs
$LangList = Get-WinUserLanguageList
foreach ($lang in $LangList) {
    $lang.InputMethodTips.Clear()
}
Set-WinUserLanguageList $LangList -Force

# Remove legacy keyboards (HKCU)
reg delete "HKCU\Keyboard Layout\Preload" /f | Out-Null

# Remove legacy substitutes (critical)
reg delete "HKCU\Keyboard Layout\Substitutes" /v 00000c09 /f | Out-Null

# ============================================================
# 4. DISABLE LANGUAGE DETECTION + KEYBOARD AUTO-SWITCHING
# ============================================================
Write-Host "`nDisabling language detection + keyboard auto-switching..." -ForegroundColor Yellow

# Disable automatic language detection
reg add "HKCU\Software\Microsoft\Input\Settings" /v EnableLanguageDetection /t REG_DWORD /d 0 /f | Out-Null

# Disable automatic keyboard switching based on app window
reg add "HKCU\Software\Microsoft\Input\Settings" /v EnableAutokeyboardSwitch /t REG_DWORD /d 0 /f | Out-Null

# Disable TSF automatic profile switching
reg add "HKCU\Software\Microsoft\CTF\LangBar" /v ExtraIconsOnMinimized /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\Software\Microsoft\CTF\LangBar" /v ShowStatus /t REG_DWORD /d 0 /f | Out-Null

# Disable text input profile sync (cloud sync resurrects keyboards)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CPSS" /v SyncLanguageSettings /t REG_DWORD /d 0 /f | Out-Null

# ============================================================
# 5. ADD ONLY US-INTERNATIONAL KEYBOARD (USER ONLY)
# ============================================================
Write-Host "`nAdding US-International keyboard..." -ForegroundColor Yellow

$USIntl = "00020409"

# Add TIP to modern language list (AU language code = 0C09)
$LangList = Get-WinUserLanguageList
foreach ($lang in $LangList) {
    $lang.InputMethodTips.Add("0C09:$USIntl")
}
Set-WinUserLanguageList $LangList -Force

# Add legacy keyboard (HKCU)
reg add "HKCU\Keyboard Layout\Preload" /v 1 /t REG_SZ /d $USIntl /f | Out-Null

# ============================================================
# 6. FINAL MESSAGE
# ============================================================
Write-Host "`nAll per-user tasks complete. You may log off and back on." -ForegroundColor Green
