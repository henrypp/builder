; Archive options
SetCompress force
SetCompressor /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize on
SetDateSave off
SetCompress force
CRCCheck force
Unicode true

; Includes
!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

; Defines
!define APP_AUTHOR "Henry++"
!define APP_WEBSITE_HOST "www.henrypp.org"
!define APP_WEBSITE "https://${APP_WEBSITE_HOST}"

!define COPYRIGHT "(c) ${APP_AUTHOR}. All rights reversed."
!define LICENSE_FILE "${APP_FILES_DIR}\64\License.txt"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION RunApplication

!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Show release notes"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION ShowReleaseNotes

!define MUI_FINISHPAGE_NOREBOOTSUPPORT

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE IsPortable
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Options
AllowSkipFiles off
AutoCloseWindow false
LicenseBkColor /windows
LicenseForceSelection checkbox
ManifestSupportedOS all
ManifestLongPathAware true
ManifestDPIAware true
ShowInstDetails show
ShowUninstDetails nevershow
SilentUnInstall silent
XPStyle on

Name "${APP_NAME}"
BrandingText "${COPYRIGHT}"

Caption "${APP_NAME} v${APP_VERSION}"
UninstallCaption "${APP_NAME}"

Icon "${NSISDIR}\Contrib\Graphics\Icons\classic-install.ico"
UninstallIcon "${NSISDIR}\Contrib\Graphics\Icons\classic-uninstall.ico"

InstallDir "$PROGRAMFILES64\${APP_NAME}"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation"

;OutFile "${APP_NAME_SHORT}-${APP_VERSION}-setup.exe"
RequestExecutionLevel admin

Function .onInit
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}

	; Windows 7 and later
	${If} ${APP_NAME_SHORT} == 'simplewall'
		${IfNot} ${AtLeastWin7}
			IfSilent +1
			MessageBox MB_OK|MB_ICONEXCLAMATION '${APP_NAME} requires Windows 7 SP1 or later.'
			Abort
		${EndIf}
	${EndIf}
FunctionEnd

Function un.onInit
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}

	IfSilent skip

	MessageBox MB_YESNO|MB_ICONEXCLAMATION|MB_DEFBUTTON2 'Are you sure you want to uninstall ${APP_NAME}?' IDYES +1
	Abort

	skip:
FunctionEnd

Function un.onUninstSuccess
	IfSilent skip

	MessageBox MB_OK|MB_ICONINFORMATION '${APP_NAME} was completely removed.'

	skip:
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

	File "${APP_FILES_DIR}\64\History.txt"
	File "${APP_FILES_DIR}\64\License.txt"
	File "${APP_FILES_DIR}\64\Readme.txt"

	WriteUninstaller $INSTDIR\uninstall.exe

	; Create uninstall entry
	Call CreateUninstallEntry
SectionEnd

Section "Localization"
	SetOutPath $INSTDIR

	File /nonfatal "${APP_FILES_DIR}\64\${APP_NAME_SHORT}.lng"
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

Section /o "Store settings in application directory (portable mode)" SecPortable
	IfFileExists "$INSTDIR\portable.dat" portable
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable not_portable

	; Create portable indicator file
	not_portable:
	FileOpen $0 "$INSTDIR\portable.dat" w
	FileWrite $0 "#PORTABLE#" ; we write a new line
	FileClose $0

	portable:
SectionEnd

Section "Uninstall"
	IfFileExists $INSTDIR\${APP_NAME_SHORT}.exe installed
		IfSilent +1
		MessageBox MB_YESNO "It does not appear that ${APP_NAME} is installed in the directory '$INSTDIR'.$\r$\nContinue anyway (not recommended)?" IDYES installed
		Abort
	installed:

	${If} ${APP_NAME_SHORT} == 'simplewall'
		ExecWait '"$INSTDIR\${APP_NAME_SHORT}.exe" -uninstall'
	${EndIf}

	; Remove "skipuac" entry
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}Task"'

	; Remove "skipuac" entry (deprecated)
	nsExec::Exec 'schtasks /delete /f /tn "${APP_NAME_SHORT}SkipUac"'

	; Remove configuration from %appdata% only for non-portable mode
	IfFileExists "$INSTDIR\portable.dat" portable
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable not_portable

	not_portable:
	RMDir /r "$APPDATA\${APP_AUTHOR}\${APP_NAME}"
	RMDir "$APPDATA\${APP_AUTHOR}"

	portable:

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
		Delete "$INSTDIR\profile.xml"
		Delete "$INSTDIR\profile_internal.xml"

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

Function CreateUninstallEntry
	; Check if uninstall registry key exists and update if possible
	ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "UninstallString"
	IfErrors 0 write_registry

	IfSilent skip

	write_registry:
	WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "InstallLocation" '"$INSTDIR"'
	WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "UninstallString" '"$INSTDIR\uninstall.exe"'

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayName" "${APP_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayIcon" '"$INSTDIR\${APP_NAME_SHORT}.exe"'
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "DisplayVersion" "${APP_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "Publisher" "${APP_AUTHOR}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "URLInfoAbout" "${APP_WEBSITE}"

	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_SHORT}" "NoRepair" 1

	skip:
FunctionEnd

Function RunApplication
	IfSilent skip

	${If} ${FileExists} $INSTDIR\${APP_NAME_SHORT}.exe
		Exec '"$INSTDIR\${APP_NAME_SHORT}.exe"'
	${EndIf}

	skip:
FunctionEnd

Function ShowReleaseNotes
	IfSilent skip

	${If} ${FileExists} $INSTDIR\History.txt
		ExecShell "" '"$INSTDIR\History.txt"'
	${EndIf}

	skip:
FunctionEnd

Function IsPortable
	IfFileExists "$INSTDIR\portable.dat" portable 0
	IfFileExists "$INSTDIR\${APP_NAME_SHORT}.ini" portable not_portable

	portable:
	SectionSetFlags ${SecPortable} ${SF_SELECTED}

	SectionSetFlags ${SecShortcut1} 0
	SectionSetFlags ${SecShortcut2} 0

	Goto skip
	
	not_portable:
	SectionSetFlags ${SecPortable} 0

	SectionSetFlags ${SecShortcut1} ${SF_SELECTED}
	SectionSetFlags ${SecShortcut2} ${SF_SELECTED}

	skip:
FunctionEnd

; Version info
VIAddVersionKey "Comments" "${APP_WEBSITE}"
VIAddVersionKey "CompanyName" "${APP_AUTHOR}"
VIAddVersionKey "FileDescription" "${APP_NAME}"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "InternalName" "${APP_NAME_SHORT}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT}"
VIAddVersionKey "OriginalFilename" "${APP_NAME_SHORT}-${APP_VERSION}-setup.exe"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIProductVersion "${APP_VERSION}.0.0"
