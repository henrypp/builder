; Archive options
SetCompress force
SetCompressor /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize on
SetCompress force
CRCCheck force
Unicode true

; Includes
!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

Var /GLOBAL ProfilePath

; Defines
!define APP_AUTHOR "Henry++"
!define APP_WEBSITE_HOST "www.henrypp.org"
!define APP_WEBSITE "https://${APP_WEBSITE_HOST}"

!define COPYRIGHT "(c) ${APP_AUTHOR}. All rights reserved."
!define LICENSE_FILE "${APP_FILES_DIR}\License.txt"

;!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\nsis3-metro.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis3-metro.bmp"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION RunApplication

!define MUI_FINISHPAGE_LINK_LOCATION "${APP_WEBSITE}"
!define MUI_FINISHPAGE_LINK "${APP_WEBSITE_HOST}"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE IsPortable
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_PAGE_CUSTOMFUNCTION_PRE SetPortableMode
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Options
AllowSkipFiles off
AutoCloseWindow false
LicenseBkColor /windows
ManifestSupportedOS all
ManifestLongPathAware true
ManifestDPIAware true
SetFont 'Segoe UI' 8
ShowInstDetails show
ShowUninstDetails nevershow
SilentUnInstall silent
;XPStyle on

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

Function .onInit
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}

	; Windows 7 and later
	${If} ${APP_NAME_SHORT} == 'simplewall'
		${IfNot} ${AtLeastWin7}
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST '"${APP_NAME}" requires Windows 7 or later.'
			Abort
		${EndIf}
	${EndIf}
FunctionEnd

Function un.onInit
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}

	MessageBox MB_YESNO|MB_ICONEXCLAMATION|MB_TOPMOST|MB_DEFBUTTON2 'Are you sure you want to uninstall "${APP_NAME}"?' IDYES +2
	Abort
FunctionEnd

Function un.onUninstSuccess
	MessageBox MB_OK|MB_ICONINFORMATION|MB_TOPMOST '"${APP_NAME}" was completely removed.'
FunctionEnd

Section "!${APP_NAME}"
	SectionIn RO

	SetOutPath $INSTDIR

	${If} ${RunningX64}
		File "${APP_FILES_DIR}\64\${APP_NAME_SHORT}.exe"
		File /nonfatal "${APP_FILES_DIR}\64\${APP_NAME_SHORT}.exe.sig"
	${Else}
		File "${APP_FILES_DIR}\32\${APP_NAME_SHORT}.exe"
		File /nonfatal "${APP_FILES_DIR}\32\${APP_NAME_SHORT}.exe.sig"
	${EndIf}

	File /nonfatal "${APP_FILES_DIR}\${APP_NAME_SHORT}.lng"
	File "${APP_FILES_DIR}\History.txt"
	File "${APP_FILES_DIR}\License.txt"
	File "${APP_FILES_DIR}\Readme.txt"

	WriteUninstaller $INSTDIR\uninstall.exe

	Call CreateUninstallEntry
SectionEnd

Section /o "Store settings in application directory (portable mode)" SecPortable
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable not_portable

	; Create empty .ini
	not_portable:
	FileOpen $0 "$INSTDIR\portable.dat" w
	FileWrite $0 "#PORTABLE#" ; we write a new line
	FileClose $0

	portable:
SectionEnd

Section "Create desktop shortcut" SecShortcut1
	IfSilent skip

	CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"

	skip:
SectionEnd

Section "Create start menu shortcuts" SecShortcut2
	IfSilent skip

	CreateDirectory "$SMPROGRAMS\${APP_NAME}"

	CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME_SHORT}.exe"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\License.lnk" "$INSTDIR\License.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\History.lnk" "$INSTDIR\History.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\Readme.lnk" "$INSTDIR\Readme.txt"
	CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"

	skip:
SectionEnd

Section "Uninstall"
	${If} ${APP_NAME_SHORT} == 'simplewall'
		ExecWait '"$INSTDIR\${APP_NAME_SHORT}.exe" /uninstall'
	${EndIf}

	; Remove "skipuac" entry
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}Task"'

	; Remove "skipuac" entry (deprecated)
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}SkipUac"'

	; Remove configuration from %appdata% only for non-portable mode
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable check2

	check2:
	IfFileExists "$INSTDIR\portable.dat" portable not_portable

	not_portable:
	RMDir /r "$APPDATA\${APP_AUTHOR}\${APP_NAME}"
	RMDir "$APPDATA\${APP_AUTHOR}"

	portable:

	; Remove localizations
	RMDir /r "$INSTDIR\i18n"

	; Remove plugins (if exists)
	RMDir /r "$INSTDIR\plugins"

	; Remove install directory
	Delete "$INSTDIR\${APP_NAME_SHORT}.scr"
	Delete "$INSTDIR\${APP_NAME_SHORT}.scr.sig"
	Delete "$INSTDIR\${APP_NAME_SHORT}.exe"
	Delete "$INSTDIR\${APP_NAME_SHORT}.exe.sig"
	Delete "$INSTDIR\${APP_NAME_SHORT}.pdb"
	Delete "$INSTDIR\${APP_NAME_SHORT}.sig"
	Delete "$INSTDIR\${APP_NAME_SHORT}.lng"
	Delete "$INSTDIR\${APP_NAME_SHORT}.ini"
	Delete "$INSTDIR\${APP_NAME_SHORT}_debug.log"
	Delete "$INSTDIR\portable.dat"
	Delete "$INSTDIR\Readme.txt"
	Delete "$INSTDIR\History.txt"
	Delete "$INSTDIR\License.txt"
	Delete "$INSTDIR\FAQ.txt"

	${If} ${APP_NAME_SHORT} == 'simplewall'
		Delete "$INSTDIR\apps.xml"
		Delete "$INSTDIR\blocklist.xml"
		Delete "$INSTDIR\rules_system.xml"
		Delete "$INSTDIR\rules_custom.xml"
		Delete "$INSTDIR\rules_config.xml"
		Delete "$INSTDIR\profile.xml"
		Delete "$INSTDIR\profile_internal.xml"

		Delete "$INSTDIR\apps.xml.bak"
		Delete "$INSTDIR\rules_custom.xml.bak"
		Delete "$INSTDIR\rules_config.xml.bak"
		Delete "$INSTDIR\profile.xml.bak"
	${EndIf}

	Delete "$INSTDIR\Uninstall.exe"

	; Remove shortcuts
	RMDir /r "$SMPROGRAMS\${APP_NAME}"
	Delete "$DESKTOP\${APP_NAME}.lnk"

	; Clean registry
	DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}"
	DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}"

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}"

	RMDir "$INSTDIR"
SectionEnd

Function RunApplication
	IfSilent skip

	Exec '"$INSTDIR\${APP_NAME_SHORT}.exe"'

	skip:
FunctionEnd

Function IsPortable
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable check2

	check2:
	IfFileExists "$INSTDIR\portable.dat" portable not_portable

	portable:
	SectionSetFlags ${SecPortable} ${SF_SELECTED}

	SectionSetFlags ${SecShortcut1} 0
	SectionSetFlags ${SecShortcut2} 0

	Goto end
	
	not_portable:
	SectionSetFlags ${SecPortable} 0

	SectionSetFlags ${SecShortcut1} ${SF_SELECTED}
	SectionSetFlags ${SecShortcut2} ${SF_SELECTED}

	end:
FunctionEnd

Function SetPortableMode
	${IfNot} ${SectionIsSelected} ${SecPortable}
		StrCpy $ProfilePath "$APPDATA\${APP_AUTHOR}\${APP_NAME}"
	${Else}
		StrCpy $ProfilePath "$INSTDIR"
	${EndIf}
FunctionEnd

Function CreateUninstallEntry
	IfSilent skip

	; Create uninstall entry only for non-portable mode
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayName" "${APP_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayIcon" '"$INSTDIR\${APP_NAME_SHORT}.exe"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayVersion" "${APP_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation" '"$INSTDIR"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "Publisher" "${APP_AUTHOR}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "HelpLink" "${APP_WEBSITE}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoRepair" 1

	skip:
FunctionEnd

; Version info
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "Comments" "${APP_WEBSITE}"
VIAddVersionKey "FileDescription" "${APP_NAME}"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT}"
VIProductVersion "${APP_VERSION}.0.0"

;!packhdr "$%TEMP%\exehead.tmp" '"upx.exe" "$%TEMP%\exehead.tmp"'