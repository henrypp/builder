; Archive options
SetCompressor /SOLID lzma
SetCompress force
Unicode true

; Includes
!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

; Defines
!define APP_AUTHOR "Henry++"
!define APP_WEBSITE_HOST "www.henrypp.org"
!define APP_WEBSITE "http://${APP_WEBSITE_HOST}"

!define COPYRIGHT "(c) ${APP_AUTHOR}. All rights reserved."
!define LICENSE_FILE "${APP_FILES_DIR}\License.txt"

;!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\nsis3-branding.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis3-branding.bmp"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION RunApplication

!define MUI_FINISHPAGE_LINK_LOCATION "${APP_WEBSITE}"
!define MUI_FINISHPAGE_LINK "${APP_WEBSITE_HOST}"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Options
AllowSkipFiles off
AutoCloseWindow false
LicenseBkColor /windows
ManifestSupportedOS all
ManifestDPIAware true
SetFont 'Arial' 8
ShowInstDetails show
ShowUninstDetails nevershow
SilentUnInstall silent
XPStyle on

Name "${APP_NAME}"
BrandingText "${COPYRIGHT}"

Caption "${APP_NAME} v${APP_VERSION}"
UninstallCaption "${APP_NAME}"

Icon "logo.ico"
UninstallIcon "${NSISDIR}\Contrib\Graphics\Icons\classic-uninstall.ico"

InstallDir "$PROGRAMFILES64\${APP_NAME}"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation"

;OutFile "${APP_NAME_SHORT}_${APP_VERSION}_setup.exe"
RequestExecutionLevel highest

!macro CheckMutex
	retry:
	System::Call 'kernel32::OpenMutex(i 0x100000, b 0, t "${APP_NAME_SHORT}") i .R0'
	IntCmp $R0 0 ignore
		System::Call 'kernel32::CloseHandle(i $R0)'
		MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION|MB_TOPMOST '"${APP_NAME}" is running. Please close it before continue.' IDRETRY retry IDIGNORE ignore
		Abort
	ignore:
!macroend

!define CheckMutex "${CallArtificialFunction} CheckMutex"

Function .onInit
	; Windows Vista and later
	${If} ${APP_NAME_SHORT} == 'simplewall'
		${IfNot} ${AtLeastWinVista}
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST '"${APP_NAME}" requires Windows Vista and later.'
			Abort
		${EndIf}
	${EndIf}

	${CheckMutex}
FunctionEnd

Function un.onInit
	${CheckMutex}

	MessageBox MB_YESNO|MB_ICONEXCLAMATION|MB_TOPMOST|MB_DEFBUTTON2 'Are you sure you want to uninstall "${APP_NAME}"?' IDYES +2
	Abort
FunctionEnd

Function un.onUninstSuccess
    MessageBox MB_OK|MB_ICONINFORMATION|MB_TOPMOST '"${APP_NAME}" was completely removed.'
FunctionEnd

Function RunApplication
	Exec '"$INSTDIR\${APP_NAME_SHORT}.exe"'
FunctionEnd

Section "!${APP_NAME}"
	SectionIn RO

	SetOutPath $INSTDIR

	${If} ${RunningX64}
		File "${APP_FILES_DIR}\64\${APP_NAME_SHORT}.exe"
	${Else}
		File "${APP_FILES_DIR}\32\${APP_NAME_SHORT}.exe"
	${EndIf}

	WriteUninstaller $INSTDIR\uninstall.exe

	File "${APP_FILES_DIR}\History.txt"
	File "${APP_FILES_DIR}\License.txt"
	File "${APP_FILES_DIR}\Readme.txt"

	File /nonfatal /r "${APP_FILES_DIR}\i18n"

	Call CreateUninstallEntry
SectionEnd

Section "Create desktop shortcut"
	CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"
SectionEnd

Section "Create start menu shortcuts"
	CreateDirectory "$SMPROGRAMS\${APP_NAME}"

	CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\License.lnk" "$INSTDIR\License.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\History.lnk" "$INSTDIR\History.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\Readme.lnk" "$INSTDIR\Readme.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

Section /o "Store settings in application directory (portable mode)" SecPortable
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" file_found file_not_found

	; Check for existent configuration
	file_not_found:
	IfFileExists "$APPDATA\${APP_AUTHOR}\${APP_NAME}\${APP_NAME_SHORT}.ini" cfg_found cfg_not_found

	; Copy existing configuration
	cfg_found:
	CopyFiles /SILENT /FILESONLY '$APPDATA\${APP_AUTHOR}\${APP_NAME}\*' $INSTDIR
	Goto file_found

	; Create empty .ini
	cfg_not_found:
	FileOpen $0 "$INSTDIR\${APP_NAME_SHORT}.ini" w
	FileClose $0

	file_found:
SectionEnd

Section "Uninstall"
	${If} ${APP_NAME_SHORT} == 'simplewall'
		ExecWait '"$INSTDIR\${APP_NAME_SHORT}.exe" /uninstall'
	${EndIf}

	; Destroy process
	nsExec::Exec 'taskkill /f /im "${APP_NAME_SHORT}.exe"'

	; Remove "skipuac" entry
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}SkipUac"'

	; Remove configuration from %appdata% only for non-portable mode
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" file_found file_not_found

	file_not_found:
	RMDir /r "$APPDATA\${APP_AUTHOR}\${APP_NAME}"
	RMDir "$APPDATA\${APP_AUTHOR}"

	file_found:

	; Remove localizations
	RMDir /r "$INSTDIR\i18n"

	; Remove install directory
	Delete "$INSTDIR\${APP_NAME_SHORT}.exe"
	Delete "$INSTDIR\${APP_NAME_SHORT}.ini"
	Delete "$INSTDIR\Readme.txt"
	Delete "$INSTDIR\History.txt"
	Delete "$INSTDIR\License.txt"
	Delete "$INSTDIR\Uninstall.exe"

	; Remove shortcuts
	RMDir /r "$SMPROGRAMS\${APP_NAME}"
	Delete "$DESKTOP\${APP_NAME}.lnk"

	; Clean registry
	DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}"

	RMDir "$INSTDIR"
SectionEnd

Function CreateUninstallEntry
	; Create uninstall entry only for non-portable mode
	${IfNot} ${SectionIsSelected} ${SecPortable}
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayName" "${APP_NAME}"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayIcon" '"$INSTDIR\${APP_NAME_SHORT}.exe"'
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "UninstallString" '"$INSTDIR\uninstall.exe"'
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayVersion" "${APP_VERSION}"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation" '"$INSTDIR"'
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "Publisher" "${APP_AUTHOR}"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "HelpLink" "${APP_WEBSITE}"
		WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoModify" 1
		WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoRepair" 1
	${EndIf}
FunctionEnd

; Version info
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "Comments" "${APP_WEBSITE}"
VIAddVersionKey "FileDescription" "${APP_NAME}"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT}"
VIProductVersion "${APP_VERSION}.0"

;!packhdr "$%TEMP%\exehead.tmp" '"upx.exe" "$%TEMP%\exehead.tmp"'