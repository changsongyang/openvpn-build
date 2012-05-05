; ****************************************************************************
; * Copyright (C) 2002-2010 OpenVPN Technologies, Inc.                       *
; * Copyright (C)      2012 Alon Bar-Lev <alon.barlev@gmail.com>             *
; *  This program is free software; you can redistribute it and/or modify    *
; *  it under the terms of the GNU General Public License version 2          *
; *  as published by the Free Software Foundation.                           *
; ****************************************************************************

; OpenVPN install script for Windows, using NSIS

SetCompressor lzma

!include "MUI.nsh"

!include "StrStr.nsi"
!include "setpath.nsi"

; Default service settings
!define OPENVPN_CONFIG_EXT   "ovpn"

;--------------------------------
;Configuration

;General

Name "${PACKAGE_NAME} ${VERSION_STRING}"
OutFile "${OUTPUT}"

ShowInstDetails show
ShowUninstDetails show

;Folder selection page
InstallDir "$PROGRAMFILES\${PACKAGE_NAME}"

;Remember install folder
InstallDirRegKey HKCU "Software\${PACKAGE_NAME}" ""

;--------------------------------
;Modern UI Configuration

!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${PACKAGE_NAME} ${SPECIAL_BUILD}, an Open Source VPN package by James Yonan.\r\n\r\nNote that the Windows version of ${PACKAGE_NAME} will only run on Windows XP, or higher.\r\n\r\n\r\n"

!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components to install/upgrade.  Stop any ${PACKAGE_NAME} processes or the ${PACKAGE_NAME} service if it is running.  All DLLs are installed locally."

!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\INSTALL-win32.txt"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ABORTWARNING
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "install-whirl.bmp"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES  
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
 
!insertmacro MUI_LANGUAGE "English"
  
;--------------------------------
;Language Strings

LangString DESC_SecOpenVPNUserSpace ${LANG_ENGLISH} "Install ${PACKAGE_NAME} user-space components, including openvpn.exe."

!ifdef USE_OPENVPN_GUI
	LangString DESC_SecOpenVPNGUI ${LANG_ENGLISH} "Install ${PACKAGE_NAME} GUI by Mathias Sundman"
!endif

!ifdef USE_TAP_WINDOWS
	LangString DESC_SecTAP ${LANG_ENGLISH} "Install/upgrade the TAP virtual device driver."
!endif

!ifdef USE_EASYRSA
	LangString DESC_SecOpenVPNEasyRSA ${LANG_ENGLISH} "Install ${PACKAGE_NAME} RSA scripts for X509 certificate management."
!endif

LangString DESC_SecOpenSSLDLLs ${LANG_ENGLISH} "Install OpenSSL DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecLZODLLs ${LANG_ENGLISH} "Install LZO DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecPKCS11DLLs ${LANG_ENGLISH} "Install PKCS#11 helper DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME} service wrapper (openvpnserv.exe)"

LangString DESC_SecOpenSSLUtilities ${LANG_ENGLISH} "Install the OpenSSL Utilities (used for generating public/private key pairs)."

LangString DESC_SecAddPath ${LANG_ENGLISH} "Add ${PACKAGE_NAME} executable directory to the current user's PATH."

LangString DESC_SecAddShortcuts ${LANG_ENGLISH} "Add ${PACKAGE_NAME} shortcuts to the current user's Start Menu."

LangString DESC_SecFileAssociation ${LANG_ENGLISH} "Register ${PACKAGE_NAME} config file association (*.${OPENVPN_CONFIG_EXT})"

;--------------------------------
;Reserve Files
  
;Things that need to be extracted on first (keep these lines before any File command!)
;Only useful for BZIP2 compression

ReserveFile "install-whirl.bmp"

;--------------------------------
;Macros

!macro WriteRegStringIfUndef ROOT SUBKEY KEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" "${KEY}"
	${If} $R0 == ""
		WriteRegStr "${ROOT}" "${SUBKEY}" "${KEY}" '${VALUE}'
	${EndIf}
	Pop $R0
!macroend

!macro DelRegKeyIfUnchanged ROOT SUBKEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" ""
	${If} $R0 == '${VALUE}'
		DeleteRegKey "${ROOT}" "${SUBKEY}"
	${EndIf}
	Pop $R0
!macroend

!macro IsAdmin
	# Verify that user has admin privs
	UserInfo::GetName
	${Unless} ${Errors}
		Pop $R0
		UserInfo::GetAccountType
		Pop $R1
		${If} $R1 != "Admin"
			Messagebox MB_OK "Administrator privileges required to install ${PACKAGE_NAME} [$R0/$R1]"
			Abort
		${EndIF}
	${EndUnless}
!macroend

;--------------------------------
;Installer Sections

Function .onInit
	ClearErrors

	!insertmacro IsAdmin

	# Delete previous start menu
	RMDir /r $SMPROGRAMS\${PACKAGE_NAME}
FunctionEnd

;--------------------
;Pre-install section

Section -pre

	; Stop OpenVPN if currently running
	DetailPrint "Previous Service REMOVE (if exists)"
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	Pop $R0 # return value/error/timeout

	Sleep 3000

SectionEnd

Section "${PACKAGE_NAME} User-Space Components" SecOpenVPNUserSpace

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"

	File "${OPENVPN_ROOT}\bin\openvpn.exe"

SectionEnd

Section "${PACKAGE_NAME} Service" SecService

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\openvpnserv.exe"

	SetOutPath "$INSTDIR\config"

	FileOpen $R0 "$INSTDIR\config\README.txt" w
	FileWrite $R0 "This directory should contain ${PACKAGE_NAME} configuration files$\r$\n"
	FileWrite $R0 "each having an extension of .${OPENVPN_CONFIG_EXT}$\r$\n"
	FileWrite $R0 "$\r$\n"
	FileWrite $R0 "When ${PACKAGE_NAME} is started as a service, a separate ${PACKAGE_NAME}$\r$\n"
	FileWrite $R0 "process will be instantiated for each configuration file.$\r$\n"
	FileClose $R0

	SetOutPath "$INSTDIR\sample-config"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\sample.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\client.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\server.${OPENVPN_CONFIG_EXT}"

	CreateDirectory "$INSTDIR\log"
	FileOpen $R0 "$INSTDIR\log\README.txt" w
	FileWrite $R0 "This directory will contain the log files for ${PACKAGE_NAME}$\r$\n"
	FileWrite $R0 "sessions which are being run as a service.$\r$\n"
	FileClose $R0

	; set registry parameters for openvpnserv	
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "config_dir" "$INSTDIR\config" 
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "config_ext"  "${OPENVPN_CONFIG_EXT}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "exe_path"    "$INSTDIR\bin\openvpn.exe"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "log_dir"     "$INSTDIR\log"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "priority"    "NORMAL_PRIORITY_CLASS"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "log_append"  "0"

	; shortcuts
	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Utilities"
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Utilities\Generate a static ${PACKAGE_NAME} key.lnk" "$INSTDIR\bin\openvpn.exe" '--pause-exit --verb 3 --genkey --secret "$INSTDIR\config\key.txt"' "$INSTDIR\icon.ico" 0
	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts"
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} Sample Configuration Files.lnk" "$INSTDIR\sample-config" ""
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} log file directory.lnk" "$INSTDIR\log" ""
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} configuration file directory.lnk" "$INSTDIR\config" ""

	; install openvpnserv as a service (to be started manually from service control manager)
	DetailPrint "Service INSTALL"
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -install'
	Pop $R0 # return value/error/timeout

SectionEnd

!ifdef USE_TAP_WINDOWS
Section "TAP Virtual Ethernet Adapter" SecTAP

	SetOverwrite on
	SetOutPath "$TEMP"

	File /oname=tap-windows.exe "${TAP_WINDOWS_INSTALLER}"

	DetailPrint "TAP INSTALL (May need confirmation)"
	nsExec::ExecToLog '"$TEMP\tap-windows.exe" /S'
	Pop $R0 # return value/error/timeout

	Delete "$TEMP\tap-windows.exe"

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "tap" "installed"
SectionEnd
!endif

!ifdef USE_OPENVPN_GUI
Section "${PACKAGE_NAME} GUI" SecOpenVPNGUI

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"

	File "${OPENVPN_ROOT}\bin\openvpn-gui.exe"

	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Documentation"
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe" ""
	CreateShortcut "$DESKTOP\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe"
SectionEnd
!endif

Section "${PACKAGE_NAME} File Associations" SecFileAssociation
	WriteRegStr HKCR ".${OPENVPN_CONFIG_EXT}" "" "${PACKAGE_NAME}File"
	WriteRegStr HKCR "${PACKAGE_NAME}File" "" "${PACKAGE_NAME} Config File"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell" "" "open"
	WriteRegStr HKCR "${PACKAGE_NAME}File\DefaultIcon" "" "$INSTDIR\icon.ico,0"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\open\command" "" 'notepad.exe "%1"'
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\run" "" "Start ${PACKAGE_NAME} on this config file"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\run\command" "" '"$INSTDIR\bin\openvpn.exe" --pause-exit --config "%1"'
SectionEnd

Section /o "OpenSSL Utilities" SecOpenSSLUtilities

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\openssl.exe"

SectionEnd

!ifdef USE_EASYRSA
Section /o "${PACKAGE_NAME} RSA Certificate Management Scripts" SecOpenVPNEasyRSA

	SetOverwrite on
	SetOutPath "$INSTDIR\easy-rsa"

	File "${EASYRSA_ROOT}\2.0\openssl-1.0.0.cnf"
	File "${EASYRSA_ROOT}\Windows\vars.bat.sample"

	File "${EASYRSA_ROOT}\Windows\init-config.bat"

	File "${EASYRSA_ROOT}\Windows\README.txt"
	File "${EASYRSA_ROOT}\Windows\build-ca.bat"
	File "${EASYRSA_ROOT}\Windows\build-dh.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-server.bat"
	File "${EASYRSA_ROOT}\Windows\build-key.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-pkcs12.bat"
	File "${EASYRSA_ROOT}\Windows\clean-all.bat"
	File "${EASYRSA_ROOT}\Windows\index.txt.start"
	File "${EASYRSA_ROOT}\Windows\revoke-full.bat"
	File "${EASYRSA_ROOT}\Windows\serial.start"

SectionEnd
!endif

Section "OpenSSL DLLs" SecOpenSSLDLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\libeay32.dll"
	File "${OPENVPN_ROOT}\bin\ssleay32.dll"

SectionEnd

Section "LZO DLLs" SecLZODLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\liblzo2-2.dll"

SectionEnd

Section "PKCS#11 DLLs" SecPKCS11DLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\libpkcs11-helper-1.dll"

SectionEnd

Section "Add ${PACKAGE_NAME} to PATH" SecAddPath

	; remove previously set path (if any)
	Push "$INSTDIR\bin"
	Call RemoveFromPath

	; append our bin directory to end of current user path
	Push "$INSTDIR\bin"
	Call AddToPath

SectionEnd

Section "Add Shortcuts to Start Menu" SecAddShortcuts

	SetOverwrite on
	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}"
	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Documentation"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Windows Notes.url" "InternetShortcut" "URL" "http://openvpn.net/INSTALL-win32.html"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Manual Page.url" "InternetShortcut" "URL" "http://openvpn.net/man.html"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} HOWTO.url" "InternetShortcut" "URL" "http://openvpn.net/howto.html"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Web Site.url" "InternetShortcut" "URL" "http://openvpn.net/"
	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Uninstall ${PACKAGE_NAME}.lnk" "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
;Dependencies

Function .onSelChange
	${If} ${SectionIsSelected} ${SecService}
		!insertmacro SelectSection ${SecOpenVPNUserSpace}
	${EndIf}
!ifdef USE_EASYRSA
	${If} ${SectionIsSelected} ${SecOpenVPNEasyRSA}
		!insertmacro SelectSection ${SecOpenSSLUtilities}
	${EndIf}
!endif
FunctionEnd

;--------------------
;Post-install section

Section -post

	SetOverwrite on

	; Store README, license, icon
	SetOverwrite on
	SetOutPath $INSTDIR
	File "icon.ico"
	File "${OPENVPN_ROOT}\share\doc\openvpn\INSTALL-win32.txt"
	File "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"

	; Store install folder in registry
	WriteRegStr HKLM SOFTWARE\${PACKAGE_NAME} "" $INSTDIR

	; Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	; Show up in Add/Remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayName" "${PACKAGE_NAME} ${VERSION_STRING} ${SPECIAL_BUILD}"
	WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayIcon" "$INSTDIR\icon.ico"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayVersion" "${VERSION_STRING}"

SectionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNUserSpace} $(DESC_SecOpenVPNUserSpace)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
	!ifdef USE_OPENVPN_GUI
		!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNGUI} $(DESC_SecOpenVPNGUI)
	!endif
	!ifdef USE_TAP_WINDOWS
		!insertmacro MUI_DESCRIPTION_TEXT ${SecTAP} $(DESC_SecTAP)
	!endif
	!ifdef USE_EASYRSA
		!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNEasyRSA} $(DESC_SecOpenVPNEasyRSA)
	!endif
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLUtilities} $(DESC_SecOpenSSLUtilities)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLDLLs} $(DESC_SecOpenSSLDLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecLZODLLs} $(DESC_SecLZODLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecPKCS11DLLs} $(DESC_SecPKCS11DLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAddPath} $(DESC_SecAddPath)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAddShortcuts} $(DESC_SecAddShortcuts)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssociation} $(DESC_SecFileAssociation)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Function un.onInit
	ClearErrors

	!insertmacro IsAdmin
FunctionEnd

Section "Uninstall"

	; Stop OpenVPN if currently running
	DetailPrint "Service REMOVE"
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	Pop $R0 # return value/error/timeout

	Sleep 3000

	!ifdef USE_TAP_WINDOWS
		ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "tap"
		${If} $R0 == "installed"
			ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TAP-Windows" "UninstallString"
			${If} $R0 != ""
				DetailPrint "TAP UNINSTALL"
				nsExec::ExecToLog '"$R0" /S'
				Pop $R0 # return value/error/timeout
			${EndIf}
		${EndIf}
	!endif

	Push "$INSTDIR\bin"
	Call un.RemoveFromPath

	RMDir /r $SMPROGRAMS\${PACKAGE_NAME}

	!ifdef USE_OPENVPN_GUI
		Delete "$INSTDIR\bin\openvpn-gui.exe"
		Delete "$DESKTOP\${PACKAGE_NAME} GUI.lnk"
	!endif

	Delete "$INSTDIR\bin\openvpn.exe"
	Delete "$INSTDIR\bin\openvpnserv.exe"
	Delete "$INSTDIR\bin\libeay32.dll"
	Delete "$INSTDIR\bin\ssleay32.dll"
	Delete "$INSTDIR\bin\liblzo2-2.dll"
	Delete "$INSTDIR\bin\libpkcs11-helper-1.dll"

	Delete "$INSTDIR\config\README.txt"
	Delete "$INSTDIR\config\sample.${OPENVPN_CONFIG_EXT}.txt"

	Delete "$INSTDIR\log\README.txt"

	Delete "$INSTDIR\bin\openssl.exe"

	Delete "$INSTDIR\INSTALL-win32.txt"
	Delete "$INSTDIR\icon.ico"
	Delete "$INSTDIR\license.txt"
	Delete "$INSTDIR\Uninstall.exe"

	!ifdef USE_EASYRSA
		Delete "$INSTDIR\easy-rsa\openssl-1.0.0.cnf"
		Delete "$INSTDIR\easy-rsa\vars.bat.sample"
		Delete "$INSTDIR\easy-rsa\init-config.bat"
		Delete "$INSTDIR\easy-rsa\README.txt"
		Delete "$INSTDIR\easy-rsa\build-ca.bat"
		Delete "$INSTDIR\easy-rsa\build-dh.bat"
		Delete "$INSTDIR\easy-rsa\build-key-server.bat"
		Delete "$INSTDIR\easy-rsa\build-key.bat"
		Delete "$INSTDIR\easy-rsa\build-key-pkcs12.bat"
		Delete "$INSTDIR\easy-rsa\clean-all.bat"
		Delete "$INSTDIR\easy-rsa\index.txt.start"
		Delete "$INSTDIR\easy-rsa\revoke-key.bat"
		Delete "$INSTDIR\easy-rsa\revoke-full.bat"
		Delete "$INSTDIR\easy-rsa\serial.start"
	!endif

	Delete "$INSTDIR\sample-config\*.${OPENVPN_CONFIG_EXT}"

	RMDir "$INSTDIR\bin"
	RMDir "$INSTDIR\config"
	RMDir "$INSTDIR\easy-rsa"
	RMDir "$INSTDIR\sample-config"
	RMDir /r "$INSTDIR\log"
	RMDir "$INSTDIR"

	!insertmacro DelRegKeyIfUnchanged HKCR ".${OPENVPN_CONFIG_EXT}" "${PACKAGE_NAME}File"
	DeleteRegKey HKCR "${PACKAGE_NAME}File"
	DeleteRegKey HKLM SOFTWARE\${PACKAGE_NAME}
	DeleteRegKey HKCU "Software\${PACKAGE_NAME}"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}"

SectionEnd