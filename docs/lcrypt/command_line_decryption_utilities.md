<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
<meta name="keywords" content="disk encryption, security, transparent, AES, plausible deniability, virtual drive, Linux, MS Windows, portable, USB drive, partition">
<meta name="description" content="LibreCrypt: An Open-Source transparent encryption program for PCs. With this software, you can create one or more &quot;containers&quot; on your PC - which appear as disks, anything written to these disks is automatically encrypted before being stored on your hard drive.">

<meta name="author" content="Sarah Dean">
<meta name="copyright" content="Copyright 2004, 2005, 2006, 2007, 2008 Sarah Dean 2015 tdk">


<TITLE>Appendix F: Command Line Decryption Utilities</TITLE>

<link href="https://raw.githubusercontent.com/t-d-k/librecrypt/master/docs/styles_common.css" rel="stylesheet" type="text/css">

<link rel="shortcut icon" href="https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox.ico" type="image/x-icon">

<SPAN CLASS="master_link">
[![LibreCrypt logo](https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox128.png)](http://LibreCrypt.eu/)
</SPAN>
<SPAN CLASS="master_title">
_[LibreCrypt](http://LibreCrypt.eu/): Open-Source disk encryption for Windows_
</SPAN>

<SPAN class="tip">
The latest version of this document can be found at the [LibreCrypt project site](https://github.com/t-d-k/LibreCrypt)
</SPAN>
***
                
## Appendix F: Command Line Decryption Utilities

* * * 
<A NAME="level_3_heading_1">
### Overview
</A>

LibreCrypt comes complete with command line software which may be used to decrypt encrypted containers (provided the correct decryption key is known).

This software is designed to fulfil two main objectives:

  1. To ease peer review of LibreCrypt
  1. To enable testing of the ciphers in isolation
  3. To test some algorithms (notably key set up) using a diverse implementation
  
In addition it provides an extra insurance that data will be recoverable, because it is written in the portable C language, and uses minimal OS calls, it is less likely to need modification with later versions of Windows.  

Functionally, this software has one task: to decrypt the encrypted partition area of container files and to write out the plaintext version for examination.

This software is considerably easier to understand than the kernel mode drivers, and does **not** require the Microsoft SDK/DDK to be present. As a result, any competent software engineer should be able to confirm that data is being encrypted correctly by the LibreCrypt software.
This makes it possible to review and test the cryptographic code in isolation and verify both that it is identical to that used by the source libraries, and that it correctly implements the algorithm.  

This software is **not** intended for general public use, but by those who understand and can write C. In order to use it, modifications to the source code will most probably be required (to change the decryption keys used, if nothing else). For this purpose, the command line decryption utilities are not released in binary form, only as source code which must be compiled by the user.

* * * 
<A NAME="level_3_heading_2">
### Operation
</A>
Each of the command line decryption utilities is designed to operate in the following manner:

  1. Open the (input) encrypted container file.(The filename used is **hard coded** to "inFile.dat"; obviously this may be changed as required.)	
  2. Open/Create the (output) plaintext container file.(The filename used is **hard coded** to "outFile.dat"; obviously this may be changed as required.)	
  3. Generate an IV, if required. (The method of generating the IV may vary, depending on how the container was encrypted)
  4. Read in a sector's worth of data from the input (encrypted) file
  5. Decrypt the sector, block by block
   * The key used here is **hard coded** in the source, and must be the actual key that was used to encrypt the data (obviously!)
   * The way in which decryption is carried out is cypher, and cypher implementation dependent
  6. Write the decrypted sector to the output (plaintext) file
  7. Repeat steps 3-6 until all data has been decrypted
  8. Close the output file
  9. Close the input file

Please note:

 1. This software is focused only on decrypting data. They do **not** hash user keys, etc
 1. The hard coded keys must represent the actual encryption keys. In the case of Linux containers, this is the user's password hashed as appropriate. In the case of LibreCrypt containers, this is the "master key" stored in the container's "critical data block"

At time of writing, although a separate command line decryption utility to decode a container's CDB/keyfiles has not been implemented, the LibreCrypt GUI does incorporate this functionality allowing developers to extract all of the information required contained within a CDB/keyfile. **(Note: For obvious reasons, this requires the container's password and all other details that are required to use the CDB are known - it is simply not possible to decrypt this information otherwise)**



