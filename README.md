# ![lcrypt](src/lcrypt/assets/images/DoxBox32.png) lcrypt

## Open-Source disk encryption for Windows

[![Travis CI](https://travis-ci.com/ludwhe/lcrypt.svg?branch=master)](https://travis-ci.com/ludwhe/lcrypt) [![AppVeyor](https://ci.appveyor.com/api/projects/status/ixqu0a65eow80qun?svg=true)](https://ci.appveyor.com/project/ludwhe/lcrypt) [![CodeFactor](https://www.codefactor.io/repository/github/ludwhe/lcrypt/badge)](https://www.codefactor.io/repository/github/ludwhe/lcrypt) [![codebeat](https://codebeat.co/badges/d030f0b3-f599-4b25-8aa7-5fd413adb5ec)](https://codebeat.co/projects/github-com-ludwhe-lcrypt-master)

[Download](https://github.com/t-d-k/doxbox/releases/download/v6.2-beta/InstallLibreCrypt_v62Beta.exe)  
[Download LibreCrypt Portable](https://github.com/t-d-k/doxbox/releases/download/v6.2-beta/LibreCryptExplorer_v6.2.zip)

### Features

- Full transparent encryption, containers appear as removable disks in Windows Explorer.
- Compatible with Linux encryption: dm-crypt and LUKS. Linux shell scripts support deniable encryption on Linux.
- Explorer program lets you browse containers when you don't have administrator permissions.
- Supports smartcards and security tokens.
- Encrypted containers can be a file, a partition, or a whole disk.
- Opens legacy volumes created with FreeOTFE
- Runs on Windows Vista onwards (see note below for 64 bit versions).
- Supports many hash (including SHA-512, RIPEMD-320, Tiger) and encryption algorithms (Including AES, Twofish, and Serpent) in several modes (CBC, LRW, and XTS).
- Optional 'key files' let you use a thumb-drive as a key.
- Portable mode doesn't need to be installed and leaves little trace on 3rd party PCs (administrator rights needed).
- Deniable encryption in case of 'rubber hose cryptanalysis'.
- Considered the most easy to use encryption program for Windows.

**Please note this is a Beta version with some known limitations. Particularly on 64 bit Windows the text 'Test Mode' is shown on the desktop.**

### New in version v6.3β

- Simplified open and create container dialogs by removing 'hidden' containers options
- Creating hidden containers is now through separate dialogs, which is easier and less error prone
- Added experimental feature to create LUKS containers
- Minor UI improvements, including the option to remember the window position
- Reviewed and simplified all the text used in the application to use less technical language
- A new menu time shows the recommended 'hidden' offset, so hidden containers can be used without memorizing a number
- More clearly separated LUKS and dm-crypt options in the UI, to prevent LUKs containers being accidentally opened as dm-crypt  

### New features in version 6.2β

- Change of name to 'LibreCrypt'
- Many UI bugs fixed - see [Issue 20](https://github.com/t-d-k/doxbox/issues/20)
- Improved support for GPT partitioned discs.
- Improved new password dialog.
- Improved partition information when running as non-admin.

### Release notes

_Important: LibreCrypt in Portable mode will not work on Windows Vista and later 64 bit versions without a extra step before use._

- LUKS partitions on LVM volumes, or LVM volumes in LUKS partitions cannot be accessed due to Windows limitations
- To run in portable mode, you need to have admin rights.
- LibreCrypt does not support encryption of the operating system partition, for this we recommend Ubuntu Linux or DiskCryptor.

_LibreCrypt installed on Windows Vista and later 64 bit versions adds the text "Test Mode" to the Windows desktop. Please see the documentation for details on removing this._

#### Known bugs

- LibreCrypt cannot access LVM containers without an additional filesystem driver that understands LVM. No such filesystem driver exists for Windows versions later than XP
- LibreCrypt cannot access ext2,3,4 volumes without an additional filesystem driver that can read ext2.
- Installing the LibreCrypt drivers may enable malware specifically written to take advantage of it to access files as administrator [see issue #38](https://github.com/t-d-k/LibreCrypt/issues/38)  
- LibreCrypt may not be able to access internal disks where a LUKS volume was created using the whole volume, instead of a partition [see issue #30](https://github.com/t-d-k/LibreCrypt/issues/30)

#### Installing

- On Windows 8 please turn off 'Safe Boot' and disklocker before installing.
- There has been a report that Kaspersky anti-virus falsely reports LibreCrypt as having the 'generic.Trojan' virus, please disable or replace this before installing.
- Please follow these instructions to run LibreCrypt in portable mode on 64 bit Windows; if you do not do this you will get the error "Windows requires a digitally signed driver" when starting the drivers. There is no need to do this if LibreCrypt is installed.
- Start LibreCrypt, click 'No' on the prompt to start the portable drivers, and 'OK' on the warning dialog about not having any loaded drivers.
- Click the Tools->"Allow Test-signed drivers" menu item.
- Reboot
- After rebooting the words "Test Mode" appear in the four corners of the Desktop. Please see the documentation for details on removing this.
- LibreCrypt needs to be run as administrator the first time it is run. After that it can be run as an ordinary user.

#### Upgrading

- This release has changes to the drivers, if upgrading from previous versions of LibreCrypt, DoxBox or FreeOTFE please completely uninstall the old version first
- Support for the following cyphers will be removed in a future version, please convert to another: xor, plain, single DES. Ditto for the 'plain' hash.
- Backwards compatibility with older versions of FreeOTFE (before 5.21) will be removed in version 6.3. Please convert any FreeOTFE volumes. This can be done by creating a new 'container' and copying the files across.

#### Passwords

_These issues relate to passwords (keyphrases) containing non-ASCII characters, e.g. accented letters and non Latin scripts, not to ASCII special characters like '$&^'._

- The handling of keyphrases containing non-ASCII characters will change in a future version. This change will not be backwards compatible. So in this version it is recommended to use only ASCII characters in keyphrases.
- There are possible bugs in opening volumes created with FreeOTFE with non-ASCII characters. If you experience problems, please use the legacy app to change the password to an ASCII one and retry. Alternatively move the files to a native container.

For more details, please see the [getting started guide]() and [FAQ]().
