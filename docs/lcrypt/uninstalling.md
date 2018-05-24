# Appendix G: Uninstalling

To uninstall LibreCrypt, please carry out the steps detailed in either of the sections below:

* * * 
<A NAME="level_3_heading_1">
### Automatic Uninstall
</A>
If installed via the installation wizard, LibreCrypt may be uninstalled by either:


1. Using the "Add and Remove Programs" control panel applet.
1. Running "uninstall.exe", found in the directory LibreCrypt was installed in


* * * 
<A NAME="level_3_heading_2">
### Manual Uninstall
</A>

<OL>

1. Launch "LibreCrypt.exe".
1. Unmount **all** mounted volumes.

1. Select "File | Drivers..."

1. Select each of the drivers you have installed, and click "Uninstall". Repeat this until all drivers have been uninstalled. If you encounter errors in this step, don't worry; just continue uninstalling your other remaining drivers
1. Exit LibreCrypt.

1. Reboot your computer
1. You shouldn't need to, but if you encountered any errors while uninstalling the drivers:
	1. Run "regedit.exe", and remove all registry keys under: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services` that have "FreeOTFE" in their name.	
	2. Delete all files beginning "FreeOTFE" from your `<windows>\system32\drivers` directory (you may need to reboot your computer again before you can do this)
	3. If you deleted any registry entries or files, reboot your computer again.


1. Finally, delete "LibreCrypt.exe", and any shortcuts you may have created.
</OL>

_Original by Sarah Dean, copyright 2004 - 2008 Sarah Dean, 2015 tdk_
