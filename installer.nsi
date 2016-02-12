; Compiler options
SetCompressor /SOLID lzma
SetCompress force

; Includes
!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "x64.nsh"

; Variables
Var StartMenuFolder

; Defines
!define APP_AUTHOR "Henry++"
!define APP_WEBSITE "http://www.henrypp.org"

!define COPYRIGHT "(c) ${APP_AUTHOR}. All rights reserved."
!define LICENSE_FILE "${APP_FILES_DIR}\License.txt"

!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-nsis.bmp"

!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM" 
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "StartMenuDir"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION RunApplication
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_WEBSITE}"
!define MUI_FINISHPAGE_LINK "${APP_WEBSITE}"
!define MUI_FINISHPAGE_TEXT_LARGE

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Options
Name "${APP_NAME}"
BrandingText "${COPYRIGHT}"

Caption "${APP_NAME}"
UninstallCaption "${APP_NAME}"

Icon "${NSISDIR}\Contrib\Graphics\Icons\orange-install-nsis.ico"
UninstallIcon "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall-nsis.ico"

InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation"

;OutFile "bin\${APP_NAME_SHORT}_${APP_VERSION}_setup.exe"
RequestExecutionLevel highest

AllowSkipFiles off
AutoCloseWindow false
CRCCheck force
ShowInstDetails show
ShowUninstDetails nevershow
SilentUnInstall silent
XPStyle on

Function .onInit
	${If} ${RunningX64}
		${If} $INSTDIR == ""
			StrCpy $INSTDIR "$PROGRAMFILES64\${APP_NAME}"
		${EndIf}
	${Else}
		${If} $INSTDIR == ""
			StrCpy $INSTDIR "$PROGRAMFILES32\${APP_NAME}"
		${EndIf}
	${EndIf}
FunctionEnd

Function un.onInit
	MessageBox MB_YESNO|MB_ICONEXCLAMATION 'Are you sure you want to uninstall ${APP_NAME}' IDYES +2
	Abort
FunctionEnd

Function un.onUninstSuccess
    MessageBox MB_OK '${APP_NAME} completely removed.'
FunctionEnd

Function RunApplication
	Exec '"$INSTDIR\${APP_NAME_SHORT}.exe"'
FunctionEnd

Section "!${APP_NAME}"
	SectionIn RO

	nsExec::Exec 'taskkill.exe /f /im ${APP_NAME_SHORT}.exe'

	SetOutPath $INSTDIR

	${If} ${RunningX64}
		File "${APP_FILES_DIR}\64\${APP_NAME_SHORT}.exe"
	${Else}
		File "${APP_FILES_DIR}\32\${APP_NAME_SHORT}.exe"
	${EndIf}

	File /nonfatal /r "${APP_FILES_DIR}\i18n"

	File "${APP_FILES_DIR}\History.txt"
	File "${APP_FILES_DIR}\License.txt"
	File "${APP_FILES_DIR}\Readme.txt"

	WriteUninstaller $INSTDIR\uninstall.exe

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayName" "${APP_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayIcon" '"$INSTDIR\${APP_NAME_SHORT}.exe"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayVersion" "${APP_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation" '"$INSTDIR"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "Publisher" "${APP_AUTHOR}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "HelpLink" "${APP_WEBSITE}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoRepair" 1

	!insertmacro MUI_STARTMENU_WRITE_BEGIN Application

	CreateDirectory "$SMPROGRAMS\$StartMenuFolder"

	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\License.lnk" "$INSTDIR\License.txt"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\History.lnk" "$INSTDIR\History.txt"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Readme.lnk" "$INSTDIR\Readme.txt"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\uninstall.exe"

	!insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section "Create desktop shortcut"
	CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"
SectionEnd

Section /o "Store settings in application directory"
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" file_found file_not_found

	file_not_found:

	FileOpen $0 "$INSTDIR\${APP_NAME_SHORT}.ini" w
	FileClose $0

	file_found:
SectionEnd

Section "Uninstall"
	; Kill running applications
	nsExec::Exec 'taskkill.exe /f /im ${APP_NAME_SHORT}.exe'
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}SkipUac"'

	; Clean install directory
	RMDir /r "$INSTDIR\i18n"

	Delete "$INSTDIR\${APP_NAME_SHORT}.exe"
	Delete "$INSTDIR\${APP_NAME_SHORT}.ini"
	Delete "$INSTDIR\Readme.txt"
	Delete "$INSTDIR\History.txt"
	Delete "$INSTDIR\License.txt"
	Delete "$INSTDIR\Uninstall.exe"

	; Delete shortcut's
	!insertmacro MUI_STARTMENU_GETFOLDER "Application" $StartMenuFolder

	RMDir /r "$SMPROGRAMS\$StartMenuFolder"
	Delete "$DESKTOP\${APP_NAME}.lnk"
	
	; Clean registry
	DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}"

	; Settings
	RMDir /r "$APPDATA\${APP_AUTHOR}\${APP_NAME}"
	RMDir "$APPDATA\${APP_AUTHOR}"

	RMDir "$INSTDIR"
SectionEnd

; Version info
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "Comments" "${APP_WEBSITE}"
VIAddVersionKey "FileDescription" "${APP_NAME}"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT}"
VIProductVersion "${APP_VERSION}.0"

;!packhdr "$%TEMP%\exehead.tmp" '"upx.exe" "$%TEMP%\exehead.tmp"'