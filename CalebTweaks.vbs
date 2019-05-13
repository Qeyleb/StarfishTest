' Caleb's all-in-one let's tweak Windows how we want it script.
' Slackbash@gmail.com  for any questions or suggestions.
' Version 0.14 last updated 2019/03/26

' credit to https://www.wincert.net/forum/index.php?/topic/13741-2018-windows-8-mega-tweaks/
'    and many other stackoverflow, reddit, msfn, tenforums, thewindowsclub, and wincert articles and posts.

' Notice that while I do detect and apply some settings only if they are applicable to Windows 7 or 8.x,
'  I apply all Windows 10 settings no matter what.  Why?  Because if you later upgrade from 7 or 8.x to 10,
'  the settings will already be in place!

Option Explicit

Dim wshShell : Set wshShell = CreateObject("WScript.Shell")
Dim objShell : Set objShell = CreateObject("Shell.Application")
Dim objFSO : Set objFSO = CreateObject("Scripting.FileSystemObject")
Dim objNetwork : Set objNetwork = CreateObject("WScript.Network")

Dim strComputer : strComputer = "."
Dim strDirectory : strDirectory = "C:\Recovery"
Dim strFile : strFile = "log.txt"

'A Zone Identifier could mean the file is considered 'blocked' because it was downloaded.
If objFSO.FileExists(WScript.ScriptFullName & ":Zone.Identifier") Then
	'Let's unblock it!  (same as the Unblock button found in File -> Properties)
	Dim objZoneFile : Set objZoneFile = objFSO.CreateTextFile(WScript.ScriptFullName & ":Zone.Identifier", True)
	objZoneFile.Close
End If

On Error Resume Next
Dim key : key = wshShell.RegRead("HKEY_USERS\S-1-5-19\Environment\TEMP")
'Check if elevated / administrator.  (Double-clicking the VBS does not elevate.)
If Err.Number <> 0 Then
	On Error GoTo 0
	MsgBox "Preparing to install.  Please click Yes on the next prompt."
	'Relaunch this very script, only elevated
	objShell.ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """", "", "runas", 1
	WScript.Quit
End If

'Past this point it's definitely elevated.
'On Error GoTo 0

'Get ready to make a log
Dim objTextFile, objFolder
If Not objFSO.FolderExists(strDirectory) Then
	Set objFolder = objFSO.CreateFolder(strDirectory)
End If
Set objFolder = Nothing
Set objTextFile = objFSO.OpenTextFile(strDirectory & "\" & strFile, 8, True)
'8 is for Appending, True creates the file if it doesn't exist

objTextFile.WriteLine("Running CalebTweaks.vbs at " & FormatDateTime(Now))

Dim RegPath, objWMIService, colSettings, objOS, strVersion, objProcessor, intBits, ServiceManager, NewUpdateService, intControlSet

'What ControlSet is current?  (for any changes to SYSTEM\ControlSet001 or 002 since CurrentControlSet may not be available)
intControlSet = wshShell.RegRead("HKLM\SYSTEM\Select\Current")
If intControlSet <> 2 Then intControlSet = 1

'Which version of Windows is this?
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\" & strComputer & "\root\CIMV2")
Set colSettings = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem")
For Each objOS in colSettings
	strVersion = objOS.Caption
Next
'Which architecture is this? (32 or 64)
Set colSettings = objWMIService.ExecQuery("SELECT * FROM Win32_Processor")
For Each objProcessor in colSettings
	intBits = objProcessor.AddressWidth
Next
objTextFile.WriteLine("Version " & strVersion & " architecture x" & intBits)

'Some OS-specific settings
If InStr(strVersion, "Windows 7") > 0 Then
	'Skip "Use the Web service to find the correct program" prompt for Open With
	RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\"
	wshShell.RegWrite RegPath & "NoInternetOpenWith", 1, "REG_DWORD"
ElseIf InStr(strVersion, "Windows 8") > 0 Then
	'Turn off 'Swipe for Start' hints
	RegPath = "HKLM\Software\Policies\Microsoft\Windows\EdgeUI\"
	wshShell.RegWrite RegPath & "DisableHelpSticker", 1, "REG_DWORD"
	'Turn off 'Charms Bar' hint
	wshShell.RegWrite RegPath & "DisableCharmsHint", 1, "REG_DWORD"

	'Turn on Power button on Start screen for tablets
	RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell\Launcher\"
	wshShell.RegWrite RegPath & "Launcher_ShowPowerButtonOnStartScreen", 1, "REG_DWORD"

	'Turn on Windows Update
	Dim objAutoUpdate : Set objAutoUpdate = CreateObject("Microsoft.Update.AutoUpdate")
	If objAutoUpdate.Settings.NotificationLevel = 0 Then
		objAutoUpdate.Settings.NotificationLevel = 3 'Automatic
	End If
End If

'Give updates for other Microsoft products than just Windows (Microsoft Update)
Set ServiceManager = CreateObject("Microsoft.Update.ServiceManager")
ServiceManager.ClientApplicationID = "Microsoft Update"
Set NewUpdateService = ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")

'Allow remote management tools through the firewall for Domain and Private connections
'Dim fwPolicy2 : Set fwPolicy2 = CreateObject("HNetCfg.FwPolicy2")
'3 is 1 + 2; Domain plus Private
'fwPolicy2.EnableRuleGroup 3, "File and Printer Sharing", TRUE
'fwPolicy2.EnableRuleGroup 3, "Performance Logs and Alerts", TRUE
'fwPolicy2.EnableRuleGroup 3, "Remote Desktop", TRUE
'fwPolicy2.EnableRuleGroup 3, "Remote Event Log Management", TRUE
'fwPolicy2.EnableRuleGroup 3, "Remote Scheduled Tasks Management", TRUE
'fwPolicy2.EnableRuleGroup 3, "Remote Service Management", TRUE
'fwPolicy2.EnableRuleGroup 3, "Remote Volume Management", TRUE
'fwPolicy2.EnableRuleGroup 3, "Windows Defender Firewall Remote Management", TRUE
'fwPolicy2.EnableRuleGroup 3, "Windows Management Instrumentation (WMI)", TRUE
'fwPolicy2.EnableRuleGroup 3, "Windows Remote Management", TRUE


'Enable Windows Update Restart Notifications
RegPath = "HKLM\Software\Microsoft\WindowsUpdate\UX\Settings\"
wshShell.RegWrite RegPath & "RestartNotificationsAllowed", 1, "REG_DWORD"

'Prevent auto reboot for Windows Updates
'Note: This will display "*Some settings are managed by your organization"
RegPath = "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU\"
wshShell.RegWrite RegPath & "AUOptions", 3, "REG_DWORD"
wshShell.RegWrite RegPath & "NoAutoRebootWithLoggedOnUsers", 1, "REG_DWORD"
'Prevent Install Updates from taking over the Shutdown button
wshShell.RegWrite RegPath & "NoAUAsDefaultShutdownOption", 1, "REG_DWORD"

'Enable Windows Installer service in Safe Mode
RegPath = "HKLM\SYSTEM\ControlSet00" & intControlSet & "\Control\SafeBoot\Minimal\MSIServer\"
wshShell.RegWrite RegPath & "", "Service", "REG_SZ"
RegPath = "HKLM\SYSTEM\ControlSet00" & intControlSet & "\Control\SafeBoot\Network\MSIServer\"
wshShell.RegWrite RegPath & "", "Service", "REG_SZ"

'Disable Windows Error Reporting to prevent "Windows is checking for the solution to the problem"
RegPath = "HKLM\Software\Microsoft\Windows\Windows Error Reporting\"
wshShell.RegWrite RegPath & "Disabled", 1, "REG_DWORD"

'Prevent 'Consumer Experiences' bloatware apps from returning
RegPath = "HKLM\Software\Policies\Microsoft\Windows\Cloud Content\"
wshShell.RegWrite RegPath & "DisableWindowsConsumerFeatures", 1, "REG_DWORD"

'Show "Run as different user" in Start menu
RegPath = "HKLM\Software\Policies\Microsoft\Windows\Explorer\"
wshShell.RegWrite RegPath & "ShowRunasDifferentUserInStart", 1, "REG_DWORD"
'Don't pin the Store to the taskbar
wshShell.RegWrite RegPath & "NoPinningStoreToTaskbar", 1, "REG_DWORD"

'Disable Edge desktop shortcut creation
RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\"
wshShell.RegWrite RegPath & "DisableEdgeDesktopShortcutCreation", 1, "REG_DWORD"

'Show detailed messages during startup/shutdown
RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\"
wshShell.RegWrite RegPath & "VerboseStatus", 1, "REG_DWORD"
'Prevent silly colorful Welcome animation
wshShell.RegWrite RegPath & "EnableFirstLogonAnimation", 0, "REG_DWORD"
'Enable shutdown from logon screen
wshShell.RegWrite RegPath & "shutdownwithoutlogon", 1, "REG_DWORD"

'Send only the Basic data necessary to keep Windows up to date and secure
RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection\"
wshShell.RegWrite RegPath & "AllowTelemetry", 1, "REG_DWORD"
'Do not show feedback notifications
wshShell.RegWrite RegPath & "DoNotShowFeedbackNotifications", 1, "REG_DWORD"
'And if we're on 64-bit
If intBits = 64 Then
	RegPath = "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection\"
	wshShell.RegWrite RegPath & "AllowTelemetry", 1, "REG_DWORD"
End If

'Turn off Windows Customer Experience Improvement Program
RegPath = "HKLM\Software\Microsoft\SQMClient\Windows\"
wshShell.RegWrite RegPath & "CEIPEnable", 0, "REG_DWORD"
RegPath = "HKLM\Software\Policies\Microsoft\SQMClient\Windows\"
wshShell.RegWrite RegPath & "CEIPEnable", 0, "REG_DWORD"

'Remove scheduled collection of Usage Data for Windows
'Need to rethink this, deleting may be too strong
'RegPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FDD56C73-F0D5-41B6-B767-6EFFD7966428}\"
'wshShell.RegDelete RegPath
'RegPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{47536D45-EEEC-4BDC-8183-A4DC1F8DA9E4}\"
'wshShell.RegDelete RegPath
'RegPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{C016366B-7126-46CA-B36B-592A3D95A60B}\"
'wshShell.RegDelete RegPath
'RegPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\"
'wshShell.RegDelete RegPath

'Do not preserve zone information in file attachments (this stops all downloaded files from warning "Are you sure you want to run this software?")
RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments\"
wshShell.RegWrite RegPath & "SaveZoneInformation", 1, "REG_DWORD"

'Disable IE First Run Wizard
RegPath = "HKLM\Software\Policies\Microsoft\Internet Explorer\Main\"
wshShell.RegWrite RegPath & "DisableFirstRunCustomize", 1, "REG_DWORD"

'Hide the button next to the New Tab button that opens Microsoft Edge
RegPath = "HKLM\Software\Microsoft\Internet Explorer\Main\"
wshShell.RegWrite RegPath & "HideNewEdgeButton", 1, "REG_DWORD"

'Prevent "Choose your home page and search settings" prompt
RegPath = "HKLM\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_EUPP_GLOBAL_FORCE_DISABLE\"
wshShell.RegWrite RegPath & "iexplore.exe", 1, "REG_DWORD"

'Skip first time setup wizard for Windows Media Player
RegPath = "HKLM\Software\Microsoft\MediaPlayer\Preferences\"
wshShell.RegWrite RegPath & "AcceptedEULA", 1, "REG_DWORD"
wshShell.RegWrite RegPath & "FirstTime", 1, "REG_DWORD"
RegPath = "HKLM\Software\Policies\Microsoft\WindowsMediaPlayer\"
wshShell.RegWrite RegPath & "GroupPrivacyAcceptance", 1, "REG_DWORD"

'Remove "3D Objects" from main page of This Computer
RegPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\"
wshShell.RegDelete RegPath
If intBits = 64 Then
	RegPath = "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\"
	wshShell.RegDelete RegPath
End If

objTextFile.WriteLine("Finished HKLM")

'Now we will do user-specific keys, loading the list from ProfileList.  This will also apply it to DefaultUser.
Dim sDefaultPath, sTempHive, sProfilesPath
sDefaultPath = "HKEY_USERS\Test"
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS = &H80000003
Dim objReg, arrSubkeys, strSubkey, iResult
Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\" & strComputer & "\root\default:StdRegProv")
sProfilesPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
objReg.EnumKey HKEY_LOCAL_MACHINE, sProfilesPath, arrSubkeys

For Each strSubkey In arrSubkeys
	If Left(strSubkey, 8) = "S-1-5-21" Then
		'Find out the path for a specific user
		If objReg.EnumKey(HKEY_USERS, strSubkey, "", "") = 0 Then
			'If the user's key exists in HKEY_USERS, it's loaded so we can use that instead
			sDefaultPath = "HKEY_USERS\" & strSubkey
			sTempHive = ""
		Else
			sDefaultPath = "HKEY_USERS\Test"
			sTempHive = wshShell.RegRead("HKLM\" & sProfilesPath & "\" & strSubkey & "\ProfileImagePath")
			sTempHive = wshShell.ExpandEnvironmentStrings(sTempHive) & "\NTUSER.DAT"
		End If
	ElseIf Left(strSubkey, 8) = "S-1-5-18" Then
		'Loading the Default User hive (instead of the System account)
		sTempHive = wshShell.RegRead("HKLM\" & sProfilesPath & "\Default")
		sTempHive = wshShell.ExpandEnvironmentStrings(sTempHive) & "\NTUSER.DAT"
		sDefaultPath = "HKEY_USERS\Test"
	Else
		'Skip the rest of the system accounts
		sTempHive = ""
		sDefaultPath = ""
	End If

	'Load the hive (if it exists in the path we found)
	If sDefaultPath <> "" Then
		objTextFile.WriteLine("Using " & sDefaultPath & " for " & strSubkey)

		iResult = -1
		If objFSO.FileExists(sTempHive) Then
			iResult = wshShell.Run("reg load """ & sDefaultPath & """ """ & sTempHive & """", 0, True)
			objTextFile.WriteLine("Result: " & CStr(iResult) & " reg load """ & sDefaultPath & """ """ & sTempHive & """")
		End If
		sDefaultPath = sDefaultPath & "\"

		'Use Bing instead of MSN for Internet Explorer
		RegPath = "Software\Microsoft\Internet Explorer\Main\"
		wshShell.RegWrite sDefaultPath & RegPath & "Start Page", "https://www.bing.com", "REG_SZ"

		'Turn off Suggested Sites
		RegPath = "Software\Microsoft\Internet Explorer\Suggested Sites\"
		wshShell.RegWrite sDefaultPath & RegPath & "EnableSuggestedSites", 0, "REG_DWORD"

		'Turn off "Welcome to Microsoft Edge" tour
		RegPath = "Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main\"
		wshShell.RegWrite sDefaultPath & RegPath & "IE10TourShown", 1, "REG_DWORD"
		RegPath = "Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\FirstRun\"
		wshShell.RegWrite sDefaultPath & RegPath & "LastFirstRunVersionDelivered", 1, "REG_DWORD"

		'Turn off "Make Microsoft Edge your default browser" prompt
		RegPath = "Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main\"
		wshShell.RegWrite sDefaultPath & RegPath & "DisallowDefaultBrowserPrompt", 1, "REG_DWORD"

		'Turn off "Let Microsoft provide more tailored experiences with relevant tips and recommendations by using your diagnostic data"
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Privacy\"
		wshShell.RegWrite sDefaultPath & RegPath & "TailoredExperiencesWithDiagnosticDataEnabled", 0, "REG_DWORD"

		'Turn off "Let apps use advertising ID to make ads more interesting to you based on your app usage"
		RegPath = "Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\"
		wshShell.RegWrite sDefaultPath & RegPath & "Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "Id", "", "REG_SZ"

		RegPath = "Software\Microsoft\Windows\CurrentVersion\Search\"
		'Prevent Start Menu searches from suggesting things from the Store and the web
		wshShell.RegWrite sDefaultPath & RegPath & "BingSearchEnabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "CortanaConsent", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "DeviceHistoryEnabled", 0, "REG_DWORD"

		'Turn off Cortana listening on lock screen
		RegPath = "Software\Microsoft\Speech_OneCore\Preferences\"
		wshShell.RegWrite sDefaultPath & RegPath & "VoiceActivationEnableAboveLockscreen", 0, "REG_DWORD"

		'Prevent Windows Feedback Experience
		RegPath = "Software\Microsoft\Siuf\Rules\"
		wshShell.RegWrite sDefaultPath & RegPath & "NumberOfSIUFInPeriod", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "PeriodInNanoSeconds", 0, "REG_DWORD"

		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\"
		'Show hidden files, folders, and drives
		wshShell.RegWrite sDefaultPath & RegPath & "Hidden", 1, "REG_DWORD"
		'Show protected operating system files
		wshShell.RegWrite sDefaultPath & RegPath & "SuperHidden", 1, "REG_DWORD"
		'Show extensions for known file types
		wshShell.RegWrite sDefaultPath & RegPath & "HideFileExt", 0, "REG_DWORD"
		'Set default explorer view to This PC
		wshShell.RegWrite sDefaultPath & RegPath & "LaunchTo", 1, "REG_DWORD"
		'Show seconds in clock
		wshShell.RegWrite sDefaultPath & RegPath & "ShowSecondsInSystemClock", 1, "REG_DWORD"
		'Restore previous folder windows at logon
		wshShell.RegWrite sDefaultPath & RegPath & "PersistBrowsers", 1, "REG_DWORD"
		'Prevent OneDrive advertisement nag
		wshShell.RegWrite sDefaultPath & RegPath & "ShowSyncProviderNotifications", 0, "REG_DWORD"

		'Show file operations details
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager\"
		wshShell.RegWrite sDefaultPath & RegPath & "EnthusiastMode", 1, "REG_DWORD"

		'Expand Explorer Ribbon by default
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\Ribbon\"
		wshShell.RegWrite sDefaultPath & RegPath & "MinimizedStateTabletModeOff", 0, "REG_DWORD"

		'Turn off "Show contacts on the taskbar"
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People\"
		wshShell.RegWrite sDefaultPath & RegPath & "PeopleBand", 0, "REG_DWORD"

		'Add "This PC icon" to the desktop
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu\"
		wshShell.RegWrite sDefaultPath & RegPath & "{20D04FE0-3AEA-1069-A2D8-08002B30309D}", 0, "REG_DWORD"
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\"
		wshShell.RegWrite sDefaultPath & RegPath & "{20D04FE0-3AEA-1069-A2D8-08002B30309D}", 0, "REG_DWORD"

		'Turn off "Show recommended app suggestions" in the Windows Ink Workspace
		RegPath = "Software\Microsoft\Windows\CurrentVersion\PenWorkspace\"
		wshShell.RegWrite sDefaultPath & RegPath & "PenWorkspaceAppSuggestionsEnabled", 0, "REG_DWORD"

		'Prevent installing bloat/ad apps
		RegPath = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\"
		wshShell.RegWrite sDefaultPath & RegPath & "ContentDeliveryAllowed", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "FeatureManagementEnabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "OemPreInstalledAppsEnabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "PreInstalledAppsEnabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "PreInstalledAppsEverEnabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SilentInstalledAppsEnabled", 0, "REG_DWORD"
		'Turn off "Get tips, tricks, and suggestions as you use Windows"
		wshShell.RegWrite sDefaultPath & RegPath & "SoftLandingEnabled", 0, "REG_DWORD"
		'Turn off "Occasionally show suggestions in Start"
		wshShell.RegWrite sDefaultPath & RegPath & "SystemPaneSuggestionsEnabled", 0, "REG_DWORD"

		'Turn off "Show app suggestions" when Sharing a file
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280815Enabled", 0, "REG_DWORD"
		'Turn off "Show me the Windows welcome experience after updates and occasionally when I sign in to highlight what's new and suggested"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-310093Enabled", 0, "REG_DWORD"
		'Turn off "Show My People app suggestions"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-314563Enabled", 0, "REG_DWORD"
'		'Turn off "Get fun facts, tips, tricks, and more on your lock screen"
'		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338387Enabled", 0, "REG_DWORD"
		'Turn off "Occasionally show suggestions in Start"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338388Enabled", 0, "REG_DWORD"
		'Turn off "Get tips, tricks, and suggestions as you use Windows"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338389Enabled", 0, "REG_DWORD"
		'Turn off "Show me suggested content in the Settings app"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338393Enabled", 0, "REG_DWORD"
		'Turn off "Show suggestions occasionally in Timeline"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-353698Enabled", 0, "REG_DWORD"

		'We don't know what these do, I admit.  But ALL the 'SubscribedContent' identified so far has been annoying.
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-202914Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280797Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280810Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280811Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280812Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280813Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-280817Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-310091Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-314559Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338380Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-338381Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-346481Enabled", 0, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "SubscribedContent-353694Enabled", 0, "REG_DWORD"

		'Terminate with extreme prejudice.  If only there was a way to clean up the Start menu after.
		RegPath = "Software\Microsoft\Windows\ContentDeliveryManager\SuggestedApps\"
		wshShell.RegDelete sDefaultPath & RegPath
		RegPath = "Software\Microsoft\Windows\ContentDeliveryManager\Health\"
		wshShell.RegDelete sDefaultPath & RegPath
		RegPath = "Software\Microsoft\Windows\ContentDeliveryManager\Subscriptions\"
		wshShell.RegDelete sDefaultPath & RegPath
		RegPath = "Software\Microsoft\Windows\ContentDeliveryManager\CreativeEvents\"
		wshShell.RegDelete sDefaultPath & RegPath

		'Allows you to uninstall Mixed Reality Portal if not desired
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Holographic\"
		wshShell.RegWrite sDefaultPath & RegPath & "FirstRunSucceeded", 1, "REG_DWORD"

		'Don't run OneDrive Setup on new user creation/login
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Run\"
		wshShell.RegDelete sDefaultPath & RegPath & "OneDriveSetup"

		'Show accent color on title bar of modern Windows apps
'		RegPath = "Software\Microsoft\Windows\DWM\"
'		wshShell.RegWrite sDefaultPath & RegPath & "ColorPrevalence", 1, "REG_DWORD"

		'"Automatically pick an accent color from my background"
		RegPath = "Software\Microsoft\Windows\CurrentVersion\Themes\History\"
		wshShell.RegWrite sDefaultPath & RegPath & "AutoColor", 1, "REG_DWORD"

		'Turn on LineWrap for Console windows and make them very slightly transparent
		RegPath = "Console\"
		wshShell.RegWrite sDefaultPath & RegPath & "LineWrap", 1, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "WindowAlpha", 243, "REG_DWORD"

		RegPath = "Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe\"
		wshShell.RegWrite sDefaultPath & RegPath & "LineWrap", 1, "REG_DWORD"
		wshShell.RegWrite sDefaultPath & RegPath & "WindowAlpha", 243, "REG_DWORD"

		If intBits = 64 Then
			RegPath = "Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe\"
			wshShell.RegWrite sDefaultPath & RegPath & "LineWrap", 1, "REG_DWORD"
			wshShell.RegWrite sDefaultPath & RegPath & "WindowAlpha", 243, "REG_DWORD"
		End If

		'Turn off StickyKeys, ToggleKeys, and FilterKeys keyboard shortcuts by default
		RegPath = "Control Panel\Accessibility\Keyboard Response\"
		wshShell.RegWrite sDefaultPath & RegPath & "Flags", "122", "REG_SZ"
		RegPath = "Control Panel\Accessibility\MouseKeys\"
		wshShell.RegWrite sDefaultPath & RegPath & "Flags", "126", "REG_SZ"
		RegPath = "Control Panel\Accessibility\StickyKeys\"
		wshShell.RegWrite sDefaultPath & RegPath & "Flags", "506", "REG_SZ"
		RegPath = "Control Panel\Accessibility\ToggleKeys\"
		wshShell.RegWrite sDefaultPath & RegPath & "Flags", "58", "REG_SZ"

		'Some OS-specific settings
		If InStr(strVersion, "Windows 7") > 0 Then
			'Skip "Internet Explorer has been updated to show tabs on a separate row" notification
			RegPath = "Software\Microsoft\Internet Explorer\Main\"
			wshShell.RegWrite sDefaultPath & RegPath & "SearchBandRestoreBarCount", 0, "REG_DWORD"
		ElseIf InStr(strVersion, "Windows 8") > 0 Then
			'Skip "Internet Explorer has been updated to show tabs on a separate row" notification
			RegPath = "Software\Microsoft\Internet Explorer\Main\"
			wshShell.RegWrite sDefaultPath & RegPath & "SearchBandRestoreBarCount", 0, "REG_DWORD"

			'Show Windows Store apps on the taskbar
			RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\"
			wshShell.RegWrite sDefaultPath & RegPath & "StoreAppsOnTaskbar", 1, "REG_DWORD"
			'Turn off "Use Check Boxes to Select Items"
			wshShell.RegWrite sDefaultPath & RegPath & "AutoCheckSelect", 0, "REG_DWORD"

			'"Go to the Desktop instead of Start when I sign in"
			RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage\"
			wshShell.RegWrite sDefaultPath & RegPath & "OpenAtLogon", 0, "REG_DWORD"
			'"Search everywhere instead of just my apps when I search from the Apps view"
			wshShell.RegWrite sDefaultPath & RegPath & "GlobalSearchInApps", 1, "REG_DWORD"

			'Turn off 'Use Bing to Search Online'
			RegPath = "Software\Microsoft\Windows\CurrentVersion\ConnectedSearch\"
			wshShell.RegWrite sDefaultPath & RegPath & "ConnectedSearchUseWeb", 0, "REG_DWORD"
		End If

'		'Skip the Office "First things first" intro
'		RegPath = "Software\Microsoft\Office\16.0\Common\General\"
'		wshShell.RegWrite sDefaultPath & RegPath & "ShowFirstRunOptin", 1, "REG_DWORD"
'		RegPath = "Software\Microsoft\Office\16.0\Registration\"
'		wshShell.RegWrite sDefaultPath & RegPath & "AcceptAllEulas", 1, "REG_DWORD"

'		'Skip the Skype for Business splash screen
'		RegPath = "Software\Policies\Microsoft\Office\16.0\Lync\"
'		wshShell.RegWrite sDefaultPath & RegPath & "DisableSplashScreen", 1, "REG_DWORD"

'		'Skip the Skype for Business First Run tutorial
'		RegPath = "Software\Microsoft\Office\16.0\Lync\"
'		wshShell.RegWrite sDefaultPath & RegPath & "FirstRun", 1, "REG_DWORD"
'		'Skip the "7 quick tips" tutorial
'		wshShell.RegWrite sDefaultPath & RegPath & "IsBasicTutorialSeenByUser", 1, "REG_DWORD"
'		'Hide prompt to "Make Skype for Business better by uploading usage information to Microsoft"
'		wshShell.RegWrite sDefaultPath & RegPath & "UserConsentedTelemetryUpload", 0, "REG_DWORD"
'		'Hide balloon notification that Skype for Business is still running in the system tray
'		wshShell.RegWrite sDefaultPath & RegPath & "DSBkgndMode", 1, "REG_DWORD"


		'Set some defaults for the Task Manager
		RegPath = "Software\Microsoft\Windows\CurrentVersion\TaskManager\"
		Dim aBin
		'Slightly different method to deal with Binary Values in the registry
		objReg.GetBinaryValue HKEY_USERS, sDefaultPath & RegPath, "Preferences", aBin
		'Show more details
		aBin(28) = 0
		'Change CPU graph to Logical processors
		aBin(3016) = 1
		'Show kernel times
		aBin(3534) = 1
		objReg.SetBinaryValue HKEY_USERS, sDefaultPath & RegPath, "Preferences", aBin
		

		'Get rid of the trailing backslash
		sDefaultPath = Left(sDefaultPath, Len(sDefaultPath)-1)
		'Now unload the currently loaded hive
		If objFSO.FileExists(sTempHive) Then
			wshShell.Run "reg unload """ & sDefaultPath & """", 0, True
		End If
	End If
Next

objTextFile.WriteLine("Finished all users. Currently logged in as " & objNetwork.UserName)

'If we're running as SYSTEM, or the script is running from \Recovery\OEM , don't pop up a message.
If objNetwork.UserName <> "SYSTEM" AND StrComp(Mid(objFSO.GetParentFolderName(WScript.ScriptFullName), 4), "Recovery\OEM", 1) <> 0 Then
	MsgBox "All done!" & vbCrLf & "Note that many of these tweaks will not take effect until a reboot."
End If

objTextFile.Close

'Changelog:
'0.14
'Improve WMI security to PktPrivacy
'Detect 64-bit, and some other cleanup
'0.13
'Turn on Windows Installer service in Safe Mode
'Tweak this script's log creation
'0.12
'Prevent creating Edge desktop shortcut
'Turn off IE "show tabs on separate row" notification
'0.11
'Slightly more drastic measures to prevent Windows Update reboots
'0.10
'Add some Task Manager preferences
'Bug fixes and adjustments
'0.09
'Add firewall permissions for remote management
'0.08
'Add some tweaks for Office and Skype
'0.07
'Turn on Windows Update for Windows 8.x
'Minor tweaks for Microsoft Edge
'0.06
'Rearrange Registry loading system to work for profiles already loaded (user is signed in)
'0.05
'Add logging features, for troubleshooting
'0.04
'Add Office features
'0.03
'Add Windows 8.x support
'0.02
'Retool to also be able to be run as SYSTEM
'Code rearrange and cleanup
'0.01
'First release
