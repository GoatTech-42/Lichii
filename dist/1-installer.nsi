; SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
; SPDX-License-Identifier: GPL-3.0-or-later

; Usage:
;   get the latest nsis: https://nsis.sourceforge.io/Download

; Require these for makensis.
!ifndef PRODUCT_VERSION
  !error "PRODUCT_VERSION must be defined"
!endif

!ifndef ARCH
  !error "ARCH must be defined"
!endif

!ifndef VARIANT
  !error "VARIANT must be defined"
!endif

Unicode true
ManifestDPIAware true
; Per-user install: everything lands under the user's profile and HKCU, so no elevation prompt.
RequestExecutionLevel user

!define PRODUCT_NAME "Lichii"
!define PRODUCT_PUBLISHER "Lichii contributors"
!define PRODUCT_WEB_SITE "https://github.com/zortos293/Lichii"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

; Lists every payload file the install put down, relative to the install folder. The in-app
; updater keeps it current (UpdateInstaller::ManifestName), so uninstalls and updates agree on
; which files belong to the install.
!define MANIFEST_NAME "install-manifest.txt"

!ifndef BINARY_SOURCE_DIR
  !define BINARY_SOURCE_DIR "..\bin"
!endif

Name "${PRODUCT_NAME}"
OutFile "${PRODUCT_NAME}-Windows-${PRODUCT_VERSION}-${ARCH}-${VARIANT}-installer.exe"
SetCompressor /SOLID lzma
InstallDir "$LOCALAPPDATA\$(^Name)" 
ShowInstDetails show
ShowUnInstDetails show

!include "MUI2.nsh"
; Custom page plugin
!include "nsDialogs.nsh"

; MUI Settings
!define MUI_ICON "lichii.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE.txt"
; Desktop Shortcut page
Page custom desktopShortcutPageCreate desktopShortcutPageLeave
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\lichii.exe"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Variables
Var DesktopShortcutPageDialog
Var DesktopShortcutCheckbox
Var DesktopShortcut

; Language files
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Lithuanian"
!insertmacro MUI_LANGUAGE "Norwegian"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "Romanian"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "Swedish"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "Vietnamese"

; MUI end ------

Function .onInit
  StrCpy $DesktopShortcut 1

  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function desktopShortcutPageCreate
  ; Custom pages still run for a silent (/S) install; skip this one there.
  ${If} ${Silent}
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "Create Desktop Shortcut" "Would you like to create a desktop shortcut?"
  nsDialogs::Create 1018
  Pop $DesktopShortcutPageDialog
  ${If} $DesktopShortcutPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Create a desktop shortcut"
  Pop $DesktopShortcutCheckbox
  ${NSD_SetState} $DesktopShortcutCheckbox $DesktopShortcut

  nsDialogs::Show
FunctionEnd

Function desktopShortcutPageLeave
  ${NSD_GetState} $DesktopShortcutCheckbox $DesktopShortcut
FunctionEnd

Section "Base"
  ExecWait '"$INSTDIR\uninst.exe" /S _?=$INSTDIR'

  SectionIn RO

  SetOutPath "$INSTDIR"

  ; The binplaced build output will be included verbatim.
  File /r "${BINARY_SOURCE_DIR}\*"

  ; Create start menu and desktop shortcuts
  CreateShortCut "$SMPROGRAMS\$(^Name).lnk" "$INSTDIR\lichii.exe"
  ${If} $DesktopShortcut == 1
    CreateShortCut "$DESKTOP\$(^Name).lnk" "$INSTDIR\lichii.exe"
  ${EndIf}
SectionEnd

!include "FileFunc.nsh"

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\lichii.exe"

  ; Write metadata for add/remove programs applet
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\lichii.exe"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"

  WriteRegStr HKCU "Software\Classes\.nsp" "" "$(^Name)"
  WriteRegStr HKCU "Software\Classes\.xci" "" "$(^Name)"
  WriteRegStr HKCU "Software\Classes\.nro" "" "$(^Name)"
  WriteRegStr HKCU "Software\Classes\.kip" "" "$(^Name)"
  WriteRegStr HKCU "Software\Classes\$(^Name)\DefaultIcon" "" "$INSTDIR\lichii.exe,0"
  WriteRegStr HKCU "Software\Classes\$(^Name)\Shell\open\command" "" '"$INSTDIR\lichii.exe" %1'
SectionEnd

Section Uninstall
  Delete "$DESKTOP\$(^Name).lnk"
  Delete "$SMPROGRAMS\$(^Name).lnk"

  ; The manifest lists every payload file, including ones an in-app update added later, so the
  ; uninstall removes the whole payload instead of the handful of files once hardcoded here.
  ; Installs from before the manifest existed fall back to that hardcoded list.
  IfFileExists "$INSTDIR\${MANIFEST_NAME}" 0 legacy_payload
  FileOpen $0 "$INSTDIR\${MANIFEST_NAME}" r
  ${Do}
    FileRead $0 $1
    ${If} ${Errors}
      ${ExitDo}
    ${EndIf}
    ; The manifest is LF, but tolerate CRLF.
    StrCpy $2 $1 1 -1
    ${If} $2 == "$\r"
      StrCpy $1 $1 -1
    ${EndIf}
    ${If} $1 == ""
      ${Continue}
    ${EndIf}
    ; Manifest paths use '/'; NSIS path handling wants '\'.
    StrCpy $3 0
    ${Do}
      StrCpy $2 $1 1 $3
      ${If} $2 == ""
        ${ExitDo}
      ${EndIf}
      ${If} $2 == "/"
        StrCpy $4 $1 $3
        IntOp $5 $3 + 1
        StrCpy $6 $1 "" $5
        StrCpy $1 "$4\$6"
      ${EndIf}
      IntOp $3 $3 + 1
    ${Loop}
    Delete "$INSTDIR\$1"
    ; RMDir without /r only removes an empty folder, so files a user added keep theirs.
    StrCpy $3 "$INSTDIR\$1"
    ${Do}
      ${GetParent} $3 $3
      ${If} $3 == ""
      ${OrIf} $3 == $INSTDIR
        ${ExitDo}
      ${EndIf}
      RMDir $3
    ${Loop}
  ${Loop}
  FileClose $0
  Goto payload_done

legacy_payload:
  ; Be a bit careful to not delete files a user may have put into the install directory.
  Delete "$INSTDIR\lichii.exe"
  Delete "$INSTDIR\eden-cli.exe"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\README.md"
  RMDir /r "$INSTDIR\LICENSES"

payload_done:
  Delete "$INSTDIR\${MANIFEST_NAME}"
  Delete "$INSTDIR\uninst.exe"
  RMDir "$INSTDIR"

  DeleteRegKey HKCU "Software\Classes\.nsp"
  DeleteRegKey HKCU "Software\Classes\.xci"
  DeleteRegKey HKCU "Software\Classes\.nro"
  DeleteRegKey HKCU "Software\Classes\.kip"
  DeleteRegKey HKCU "Software\Classes\$(^Name)"

  DeleteRegKey HKCU "Software\Classes\discord-1397286652128264252"

  DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"

  SetAutoClose true
SectionEnd
