The printing system on server 2012R2 is flakey if you are printing on terminal servers.

Issues you will see are mutiple phantom copies of printers
Being unable to select a default (no green tick)
Unable to print from Adobe PDF reader
Unable to even see any printers in Foxit PDF reader
Event ID 365 logged in the PrintService/Admin log

The 2 golden rules you must follow when installing a new printer are:
1. Never use a 3rd party print processor
2. Never use render print job on client computer

There was a very good walkthrough on the web on how to fix this. Unfortunately it is no longer there as the domain hosting it seems to have lapsed. I have managed to find a version on wayback and saved it as a PDF:
2012 printing issues digital zombies.pdf

Unfortunately it is missing some media that was in the original such as screen grabs, MP3s and amusing animated GIFs.

Once you have run through this and fixed up the print processors and rendering on the client, you need to clean up the cruft that has been left behind in the registry on the terminal server. Specifically you need to clean:

HKLM\SYSTEM\CurrentControlSet\Control\Class\{1ed2bbf9-11f0-4084-b21f-ad83a8e6dcdc} <- All numbered keys
HKLM\SYSTEM\CurrentControlSet\Control\DeviceClasses\{0ecef634-6ef0-472a-8085-5ad023ecbccd} <- All ##?#SWD#PRINTENUM# keys
HKLM\SYSTEM\CurrentControlSet\Control\DeviceContainers\ <- All keys containing SWD\PRINTENUM values under GUID\BaseContainers\GUID
HKLM\SYSTEM\CurrentControlSet\Enum\SWD\PRINTENUM\ <- All subkeys
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\ <- Everything

There is a powershell script in the folder (CleanRDSPrinters.ps1) which will do this along with an XML file containing a scheduled task you can import which will run the script as SYSTEM and restart. Modify the path to the powershell script in the task after importing it. I suggest scheduling this to run once a week. You must restart the server after running the script as it deletes some valid values that will get recreated on restart.

Note that if running the script manually you need to run it as SYSTEM or you won't have the required permissions to the keys. You can do this by launching Powershell using the sysinternals psexec tool:
psexec /s /i powershell -file .\CleanRDSPrinters.ps1

All the usual caveats apply. Meddle with the registry at your peril! 

I can't actually tell you what these keys are used for. I only found that I need to delete from them by deleting a ghost printer and seeing what was removed using RegShot. All I can say is that I haven't seen any obvious issues since implementing this cleanup.