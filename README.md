# Contents
  - [Description](#description)
  - [Removal](#removal)
  - [FAQ](#faq)
  - [Advanced](#advanced)
  - [Highlights](#highlights)
  - [License](#license)
  - [Disclaimer](#disclaimer)

## Description
Starfish is a set of scripts that will install themselves into a Windows environment to reapply themselves every upgrade / Feature Update / System Reset.  Their purpose is to apply some Windows tweaks to the default user and all users, ideally before any users have logged on.  See [Highlights](#highlights) for more details.

## Usage
If you just want to go ahead and install, download and unpack the files to a folder and then simply run (double-click) **EnableCustomizations.cmd** -- you will need to confirm the User Account Control prompt as it will attempt to run itself with elevated privileges.  It will copy itself into **C:\Recovery\OEM** and the other appropriate folders.  See [Advanced](#advanced).  You may then delete the folder you made if you wish.

Warning: This script will overwrite any existing corresponding files.  If you already have some custom OEM configuration, check before running this.  See [FAQ](#faq), and look at the list of files affected under [Removal](#removal), below.

## Removal
Delete all these files:
```text
C:\Recovery\OEM\EnableCustomizations.cmd
C:\Recovery\OEM\CalebTweaks.vbs
C:\Recovery\OEM\ResetConfig.xml
C:\Recovery\OEM\LayoutModification.xml
C:\Recovery\OEM\unattend.xml
C:\Windows\Setup\Scripts\SetupComplete.cmd
C:\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini
C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml
C:\Windows\Panther\unattend.xml
```

Once it's been run, it's difficult to reverse everything in CalebTweaks.vbs -- if you dislike some tweak it made, you may have an easier time just looking at the file and finding the exact tweak you didn't like, and then changing it manually.

## FAQ

**Q:** Should I just go ahead and run the script?<br>
**A:** You can, with a few caveats.  I've tried to make it as safe as possible, but you should know by now that there are always exceptions when it comes to computers.  In particular, if you have some sort of OEM brand like Dell or HP, this could wreck any sort of custom recovery solution they gave you.  (Some users might not consider this a bad thing.)  And if you're in a corporate environment, you probably shouldn't be running this without checking with your IT department first.

**Q:** What versions of Windows will it work on?<br>
**A:** I have tested it on Windows 7, Windows 8.1, and many different editions of Windows 10.  I have not tested it on 8, Vista, or any versions of Server, but in theory it should work fine.  I don't test 7 as often as 10 so it is always possible that I broke something with a change, so let me know if you run into anything.

**Q:** Why aren't you detecting whether a Windows 10 setting is applicable before applying it, like if I'm on Windows 7?<br>
**A:** Because if I apply the setting to 7 or 8.x or an older version of 10, if you later upgrade from 7 or 8.x to 10 (or to a newer version of 10), the setting will already be in place!  Otherwise it's harmless in all cases I've seen so far.

**Q:** Do you use this yourself?<br>
**A:** Yes, it's on all my personal computers, and on each I've had it in place for at least one if not two Windows 10 Feature Updates.  I also test it on quite a few different virtual machines.

**Q:** Why VBScript and CMD instead of PowerShell?<br>
**A:** I know, I know.  I do actually like PowerShell.  But let's look at the facts: VBScript (and batch) just works, almost too easily.  PowerShell you have to configure ExecutionPolicy first, and to run it you have to right-click the file and choose Run with PowerShell.  Not to mention some functions are just slower and more complicated in PowerShell than VBScript.  And you have to admit it is more fiddly to get PowerShell working right during unattended Setup.

**Q:** CalebTweaks.vbs changed something I don't want.  What now?<br>
**A:** I've done my best to document the tweaks in-line; it's nearly all registry settings so you should be able to go into Regedit and change back what you need to.  Still, contact me and let me know your problem.  I take no responsibility or liability, but I will be glad to give suggestions.

**Q:** This actually broke my computer and I'm mad.<br>
**A:** You SURE it wasn't a Windows Update?  I'm not doing anything destructive.  Still, contact me and let me know your problem.  I take no responsibility or liability, but I will be glad to give suggestions.

**Q:** Can I change it and use it for my own purposes?<br>
**A:** Please do!  See [License](#license).  Do me a favor and let me know what you end up making, I'd like to know how people use it.  I would be glad to make changes to better fit others, as well.

## Advanced
Here I will overview what each file does.

#### EnableCustomizations.cmd
EnableCustomizations.cmd is the key.  It makes itself a home in C:\Recovery\OEM and generates a few files:
- **SetupComplete.cmd** in C:\Windows\Setup\Scripts -- this file is called after Setup before a user logs in, run as SYSTEM account.
- **SetupConfig.ini** in C:\Users\Default\AppData\Local\Microsoft\Windows\WSUS -- this file is called after a Feature Update, whether run manually or triggered through Windows Update.
- **ResetConfig.xml** in C:\Recovery\OEM -- this file is called after a System Reset, whether it's a refresh or a full wipe.

All three of these files will run EnableCustomizations.cmd .

Warning: This will overwrite any existing corresponding files.  If you already have some custom OEM configuration, check before running this.

Optional:
If this file is run from within another folder containing the other optional files, it will copy all the files to their proper places.
- If **LayoutModification.xml** is found, it will be copied to C:\Users\Default\AppData\Local\Microsoft\Windows\Shell
- If **unattend.xml** is found, it will be copied to C:\Windows\Panther

Each of these are documented more below.

At the end of EnableCustomizations.cmd , it will call another script, CalebTweaks.vbs -- which is technically the whole purpose for all this...

#### CalebTweaks.vbs
CalebTweaks.vbs is my personal set of Windows tweaks and customizations collected over the years.  It will apply per-user tweaks to all users on a system including the Default user account.

See [Highlights](#highlights).

#### LayoutModification.xml
- This can be used to customize the Start Menu and Taskbar for the default user (and therefore, all users created after this).
- I removed Mail and Edge from the Taskbar, and a lot of junk from the Start Menu.
- Note that when applied this will only work for users created after this -- it can't change existing users.  A pity.

#### unattend.xml
- This can be used to customize Setup and the Out Of Box Experience after upgrades and resets.
- If you rename it to **autounattend.xml** and put it on the root drive of your Windows Setup ISO or USB drive, it will be used automatically when Setup is run.
- I've tweaked this to skip steps like language choice and timezone, and it should work for Windows 7, 8, 8.1, and 10.

-- Did You Know That you can use Windows 10's setup files to install Windows 7 (or 8/8.1)?  All you need to do is replace install.wim with the one from Windows 7!  It works surprisingly well.

## Highlights
The whole purpose of this system is to apply a set of Windows tweaks, ideally before user accounts have been created.  Here are a few of my favorites:
- By turning off nearly all of the "ContentDeliveryManager", all the crap like CandyCrush never gets installed!  (This is one of the main reasons I made this whole thing so robust -- Upgrades / Feature Updates / System Resets will get rid of some customizations without this.)
- Now Windows Update will never reboot your machine for you, especially not while you're in the middle of something.  (By applying a combination of policies, which a message will inform you in Windows Update.)
- Lots of ads, nags, welcome messages, and popups are skipped/disabled:
  - The Start Menu / Search will not suggest new apps you don't have from the Store, or web results.
  - No suggestions / advertisements in Start, Settings, File Explorer, Timeline, etc.
  - No "Tips, tricks and suggestions as you use Windows" or requests for "Feedback".
  - 'First run' wizards are skipped for Internet Explorer, Edge, and Windows Media Player.
- More details are shown by default:
  - Hidden files and extensions are shown.
  - Startup/Logon and Logoff/Shutdown has more detailed status messages.
  - Show seconds in taskbar clock.
- Some things are hidden by default:
  - Don't show People on the taskbar (does anyone use this?).
  - Don't make a Store icon on the taskbar.
  - Don't make an Edge icon on the desktop.

The rest is all documented in-line in **CalebTweaks.vbs** -- I've tried to make it as readable as possible, just look for the comments (they start with ').  I'm fairly confident no one will have a problem with any of these tweaks, but please let me know if you have feedback.

## License
MIT License -- See [LICENSE.md](LICENSE.md)<br>
I also ask nicely that you let me know what you think, especially if you use ideas from or modify any of the files.

## Disclaimer
I take no responsibility or liability for anything this does to your computer that you did or didn't want.  It's all open source so look at it first before using it; if you have questions, ask.<br>
I intend no harm; I make a useful thing for myself, and share it here that others may or may not find useful.  I've done my best to test this on all common configurations and I use it myself.  But computers can be unpredictable and Windows changes, so there's always the possibility of unintended behavior.<br>
Still, if something goes wrong I want to learn about it, and may offer help as well, so contact me and let me know your problem.  I will be glad to give suggestions.
