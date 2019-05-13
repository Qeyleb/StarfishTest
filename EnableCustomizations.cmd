:: Caleb's EnableCustomizations.cmd
:: Slackbash@gmail.com  for any questions or suggestions.
:: Version 0.6 last updated 2019/03/14

:: based on https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-a-script-to-push-button-reset-features
:: and https://forums.mydigitallife.net/threads/repo-how-to-chat-audit-sysprep-generalize-setupcomplete-firstlogon-silent-install.73131/
:: and https://stackoverflow.com/questions/7044985/how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-administrator/12264592#12264592
:: among many other posts.

:: Purpose:
:: If SetupComplete.cmd is in C:\Windows\Setup\Scripts then it will call this file at the end of Setup before a user logs in, run as SYSTEM account.
:: If SetupConfig.ini is in C:\Users\Default\AppData\Local\Microsoft\Windows\WSUS then it will call this file after every Feature Update.
:: If ResetConfig.xml is in C:\Recovery\OEM then it will call this file at the end of a System Reset.
:: When this file EnableCustomizations.cmd is run, it will generate the above three files in their proper places.
:: Warning: This will overwrite any existing corresponding files.  If you already have some custom OEM configuration, maybe don't run this.

:: Optional:
:: If this file is run from within another folder containing the other optional files, it will copy all the files to their proper places.
:: If LayoutModification.xml is found, it will be copied to C:\Users\Default\AppData\Local\Microsoft\Windows\Shell
::   This can be used to customize the Start Menu and Taskbar for the default user (and therefore, all users created after this).
:: If unattend.xml is found, it will be copied to C:\Windows\Panther
::   This can be used to customize Setup and the Out Of Box Experience after upgrades and resets.
:: If CalebTweaks.vbs is found, it will be run at the end of this file.
::   This can be used to apply registry settings and other tweaks right before Windows setup finishes.

@echo off
:: %~dp0 is the path to the current script.  %~nx0 is the filename.
:: Set the current directory to the one this script is in.  The previous directory will be on the stack, retrievable with: popd
pushd "%~dp0%"

:: During a System Reset most of the usual system drive variables are set to X: instead of C: so check the registry instead.
:: Set the variable %TARGETOS%      (Typically this is C:\Windows)
for /F "tokens=1,2,3 delims= " %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RecoveryEnvironment" /v TargetOS 2^>NUL') do set TARGETOS=%%C

:: Of course if we're not doing a System Reset then the above won't work, so hopefully SystemRoot exists.
if "%TARGETOS%" == "" (
    if not "%SystemDrive%" == "X:" set TARGETOS=%SystemRoot%
)

:: If it's still not set, something is very wrong so abort.
if "%TARGETOS%" == "" (
    echo Unable to find TargetOS or SystemRoot.  What happen.
    exit /B 1
)

:: Set the variable %TARGETOSDRIVE%      (Typically this is C:)
for /F "tokens=1 delims=\" %%A in ("%TARGETOS%") do set TARGETOSDRIVE=%%A

:: Filename of the log file
set logfile="%TARGETOSDRIVE%\Recovery\Log.log"

echo %date% %time% %1 >> %logfile%

:: Filename of the temporary file used for relaunching
set "vbsGetPrivileges=%temp%\getadmin_%~nx0.vbs"

:: Check for Administrator privileges
NET FILE 1>NUL 2>NUL
:: (In the rare case this fails with a -1 errorlevel, it could be running under System Reset so is already elevated)
if '%errorlevel%' == '-1' ( goto gotPrivileges )
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
:: ELEV is our custom argument passed to signal that we were the ones that relaunched this file.
:: (Without it, an error elevating could cause the script to relaunch over and over again.)
if '%1'=='ELEV' ( shift /1 & goto gotPrivileges )

:: Make a temporary .vbs file that will relaunch this script as Administrator.
echo set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
set params=ELEV %*
:: This looks complicated but it adds ELEV, and converts any other arguments that had quotes to have double quotes.
:: It also uses $~s0 which is the short file name, just in case of international characters.
(echo UAC.ShellExecute "%TARGETOS%\System32\cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1) >> "%vbsGetPrivileges%"

:: Launch the temporary VBScript, then exit this currently running script.
"%TARGETOS%\System32\wscript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
:: At this point we have Administrator privileges; either we ran it as Administrator, or it's being run by the SYSTEM after Setup.

:: If it has the ELEV argument we know we ran it, so delete the temporary .vbs file.
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul & shift /1)

:: If we're running from the C:\Recovery\OEM folder, we can skip a step.
if /I "%~dp0" == "%TARGETOSDRIVE%\Recovery\OEM\" goto copied
:: If not, let's copy everything to there.
:: Note the trailing \ in the destination.  This confirms the destination is a directory, and therefore will be created if it doesn't exist.
xcopy "%~dp0EnableCustomizations.cmd" "%TARGETOSDRIVE%\Recovery\OEM\" /Q
xcopy "%~dp0CalebTweaks.vbs" "%TARGETOSDRIVE%\Recovery\OEM\" /Q /Y
:: Some of these are now considered optional, so suppress the errors with 2>NUL
xcopy "%~dp0LayoutModification.xml" "%TARGETOSDRIVE%\Recovery\OEM\" /Q /Y 2>NUL
xcopy "%~dp0unattend.xml" "%TARGETOSDRIVE%\Recovery\OEM\" /Q /Y 2>NUL

rem if not '%errorlevel%' == '0' ( echo "Error copying from %~dp0, aborted. Make sure EnableCustomizations.cmd is in the same folder as CalebTweaks.vbs, LayoutModification.xml, etc." >> %logfile% & goto end )

:copied

:: Add back Windows settings and Start menu customizations.
xcopy "%TARGETOSDRIVE%\Recovery\OEM\unattend.xml" "%TARGETOS%\Panther\" /Q /Y 2>NUL
xcopy "%TARGETOSDRIVE%\Recovery\OEM\LayoutModification.xml" "%TARGETOSDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\" /Q /Y 2>NUL

:: Add back SetupConfig.cmd and SetupConfig.ini customizations.  Create the files from scratch.
if not exist "%TARGETOS%\Setup\Scripts\" mkdir "%TARGETOS%\Setup\Scripts"
if not exist "%TARGETOS%\Setup\Scripts\SetupComplete.cmd" (echo "C:\Recovery\OEM\EnableCustomizations.cmd" SetupCompleteGenerated) > "%TARGETOS%\Setup\Scripts\SetupComplete.cmd"
if not exist "%TARGETOSDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\WSUS\" mkdir "%TARGETOSDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\WSUS"
(echo [SetupConfig]) > "%TARGETOSDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
(echo PostOOBE="C:\Recovery\OEM\EnableCustomizations.cmd") >> "%TARGETOSDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"

:: Create ResetConfig.xml file from scratch.
set ResetConfig="%TARGETOSDRIVE%\Recovery\OEM\ResetConfig.xml"
(echo ^<?xml version="1.0" encoding="utf-8"?^>) > %ResetConfig%
(echo ^<!-- ResetConfig.xml --^>) >> %ResetConfig%
(echo ^<Reset^>) >> %ResetConfig%
(echo   ^<Run Phase="BasicReset_AfterImageApply"^>) >> %ResetConfig%
(echo     ^<Path^>EnableCustomizations.cmd^</Path^>) >> %ResetConfig%
(echo     ^<Duration^>2^</Duration^>) >> %ResetConfig%
(echo     ^<Param^>ResetConfigBasic^</Param^>) >> %ResetConfig%
(echo   ^</Run^>) >> %ResetConfig%
(echo   ^<Run Phase="FactoryReset_AfterImageApply"^>) >> %ResetConfig%
(echo     ^<Path^>EnableCustomizations.cmd^</Path^>) >> %ResetConfig%
(echo     ^<Duration^>2^</Duration^>) >> %ResetConfig%
(echo     ^<Param^>ResetConfigFactory^</Param^>) >> %ResetConfig%
(echo   ^</Run^>) >> %ResetConfig%
(echo ^</Reset^>) >> %ResetConfig%
set ResetConfig=

set LOCALAPPDATA=%USERPROFILE%\AppData\Local
set PSExecutionPolicyPreference=Unrestricted

:: Finally, let's run my custom script full of tweaks.
"%TARGETOS%\System32\wscript.exe" "%TARGETOSDRIVE%\Recovery\OEM\CalebTweaks.vbs" >> %logfile% 2>&1
:: Here's how to do PowerShell, for later.  May need testing.
rem PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%TARGETOSDRIVE%\Recovery\OEM\CalebTweaks.ps1"" >> %logfile% 2>&1' -Verb RunAs}"

echo Finished %1 at %date% %time% >> %logfile%
:end

hehe you been hacked by the ZOGLORD hehehe 