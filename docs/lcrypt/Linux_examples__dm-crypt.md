<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
<meta name="keywords" content="disk encryption, security, transparent, AES, plausible deniability, virtual drive, Linux, MS Windows, portable, USB drive, partition">
<meta name="description" content="LibreCrypt: An Open-Source transparent encryption program for PCs. With this software, you can create one or more &quot;containers&quot; on your PC - which appear as disks, anything written to these disks is automatically encrypted before being stored on your hard drive.">

<meta name="author" content="Sarah Dean">
<meta name="copyright" content="Copyright 2004, 2005, 2006, 2007, 2008 Sarah Dean 2015 tdk">


<TITLE>Linux Examples: dm-crypt</TITLE>

<link href="https://raw.githubusercontent.com/t-d-k/LibreCrypt/master/docs/styles_common.css" rel="stylesheet" type="text/css">


<link rel="shortcut icon" href="https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox.ico" type="image/x-icon">

<SPAN CLASS="master_link">
[![LibreCrypt logo](https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox128.png)](http://LibreCrypt.eu/)
</SPAN>
<SPAN CLASS="master_title">
_[LibreCrypt](http://LibreCrypt.eu/): Open-Source disk encryption for Windows_
</SPAN>
***

## Linux Examples: dm-crypt

This section gives a series of examples of how to create Linux dm-crypt containers, and then open them using LibreCrypt.

These examples have been tested using Fedora Core 3, with a v2.6.11.7 kernel installed; though they should work for all compatible Linux distributions.


  * [Initial Setup](#level_3_heading_1)
  * [Defaults](#level_3_heading_2)
  * [Example #1: Opening a dm-crypt Container Encrypted Using dm-crypt's Default Encryption](#level_3_heading_3)
  * [Example #2: Opening a dm-crypt Container Encrypted Using 128 bit AES](#level_3_heading_4)
  * [Example #3: Opening a dm-crypt Container Encrypted Using 256 bit AES, using SHA256 ESSIV](#level_3_heading_5)
  * [Example #4: Opening a dm-crypt Container Encrypted Using 448 bit Blowfish](#level_3_heading_6)
  * [Example #5: Opening a dm-crypt Container Encrypted Using 256 bit Twofish and Offset](#level_3_heading_7)
  * [Example #6: Opening a dm-crypt Container Encrypted Using 256 bit AES with MD5 Password Hashing](#level_3_heading_8)
  * [Example #7: Opening a dm-crypt Container Encrypted Using 448 bit Blowfish, MD5 Password Hashing and SHA-256 ESSIV](#level_3_heading_9)
  * [Example #8: Opening a dm-crypt Container Encrypted Using AES-256 in XTS Mode (aka XTS-AES-256)](#level_3_heading_10)


* * * 
<A NAME="level_3_heading_1">
### Initial Setup
</A>

To begin using dm-crypt under Linux, ensure that the various kernel modules are installed:

<blockquote>
<pre>
modprobe cryptoloop

modprobe deflate
modprobe zlib_deflate
modprobe twofish
modprobe serpent
modprobe aes_i586
modprobe blowfish
modprobe des
modprobe sha256
modprobe sha512
modprobe crypto_null
modprobe md5
modprobe md4
modprobe cast5
modprobe cast6
modprobe arc4
modprobe khazad
modprobe anubis

modprobe dm_mod **(this should give you dm_snapshot, dm_zero and dm_mirror?)**
modprobe dm_crypt
</pre>
</blockquote>

At this point, typing "dmsetup targets" should give you something along the lines of:

<pre>
crypt            v1.0.0
striped          v1.0.1
linear           v1.0.1
error            v1.0.1
</pre>

Typing "lsmod" will show you which modules are currently installed.

* * * 
<A NAME="level_3_heading_2">
### Defaults
</A>

If not overridden by the user, dm-crypt defaults to encrypting with:

<TABLE style="text-align: left;">
  <TBODY>
    <TR>
      <TH>Cypher:</TH>
      <TD>AES</TD>
    </TR>
    <TR>
      <TH>Cypher keysize:</TH>
      <TD>256 bit</TD>
    </TR>
    <TR>
      <TH>User key processed with:</TH>
      <TD>RIPEMD-160 (**not** "RIPEMD-160 (Linux; Twice, with A)").  "Hash with "A"s, if hash output is too short" option - selected       </TD>
    </TR>
    <TR>
      <TH>IV generation:</TH>
      <TD>32 bit sector ID</TD>
    </TR>
  </TBODY>
</TABLE>

* * * 
<A NAME="level_3_heading_3">
### Example #1: Opening a dm-crypt Container Encrypted Using dm-crypt's Default Encryption
</A>

This example demonstrates use of a dm-crypt container using the dm-crypt's
default encryption system: AES128 with the user's password hashed with
RIPEMD160, using the 32 bit sector IDs as encryption IVs

Creating the container file under Linux:

	
	dd if=/dev/zero of=./containers/vol_default.vol bs=1K count=100
	losetup /dev/loop0 ./containers/vol_default.vol
	echo password1234567890ABC | cryptsetup create myMapper /dev/loop0
	dmsetup ls
	dmsetup table
	dmsetup status
	losetup /dev/loop1 /dev/mapper/myMapper 
	mkdosfs /dev/loop1
	mkdir ./test_mountpoint
	mount /dev/loop1 ./test_mountpoint
	cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
	cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
	cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
	cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
	umount ./test_mountpoint
	losetup -d /dev/loop1
	cryptsetup remove myMapper
	losetup -d /dev/loop0
	rm -rf ./test_mountpoint


Opening the container under LibreCrypt:



1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:


	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile  blank
	* Leave seed blank
	* Select the "RIPEMD-160 (160/512)" hash
	* Ensure "Hash with "A"s, if hash output is too short" is checked.
	* Leave iteration count at 0

1. "Encryption" tab:

		* Select the "AES (CBC; 256/128)" cypher
		* Select "32 bit sector ID" as the IV generation method* Set "Sector zero location" to "Start of encrypted data"

2. "File options" tab:


		* Leave offset at 0
		* Leave sizelimit at 0


3. "Open options" tab:

	
	* Select any unused drive letter
	* Leave readonly unchecked

4. Click the "OK" button


* * *

<A NAME="level_3_heading_4">
### Example #2: Opening a dm-crypt Container Encrypted Using 128 bit AES
</A>

This example demonstrates use of a dm-crypt AES128 container.

Creating the container file under Linux:

	dd if=/dev/zero of=./containers/vol_aes128.vol bs=1K count=100
	losetup /dev/loop0 ./containers/vol_aes128.vol
	echo password1234567890ABC | cryptsetup  -c aes -s 128 create myMapper /dev/loop0
	dmsetup ls
	dmsetup table
	dmsetup status
	losetup /dev/loop1 /dev/mapper/myMapper 
	mkdosfs /dev/loop1
	mkdir ./test_mountpoint
	mount /dev/loop1 ./test_mountpoint
	cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
	cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
	cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
	cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
	umount ./test_mountpoint
	losetup -d /dev/loop1
	cryptsetup remove myMapper
	losetup -d /dev/loop0
	rm -rf ./test_mountpoint

Opening the container under LibreCrypt:

1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

	+ Enter "password1234567890ABC" as the key
	+ Leave GPG executable blank
	+ Leave GPG keyfile  blank
	+ Leave seed blank
	+ Select the "RIPEMD-160 (160/512)" hash.
	+ Ensure "Hash with "A"s, if hash output is too short" is checked.
	+ Leave iteration count at 0

1. "Encryption" tab:

	+ Select the "AES (CBC; 128/128)" cypher
	+ Select "32 bit sector ID" as the IV generation method* Set "Sector zero location" to "Start of encrypted data"

1. "File options" tab:

	+ Leave offset at 0
	+ Leave sizelimit at 0

1. "Open options" tab:

	+ Select any unused drive letter
	+ Leave readonly unchecked

1. Click the "OK" button



* * * 
<A NAME="level_3_heading_5">
### Example #3: Opening a dm-crypt Container Encrypted Using 256 bit AES, using SHA256 ESSIV
</A>

This example demonstrates use of a dm-crypt AES256 container using SHA-256 ESSIV sector IVs.

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_aes_essiv_sha256.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_aes_essiv_sha256.vol
echo password1234567890ABC | cryptsetup  -c aes-cbc-essiv:sha256 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:



1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile  blank
	* Leave seed blank
	* Select the "RIPEMD-160 (160/512)" hash

			* Ensure "Hash with "A"s, if hash output is too short" is checked.
	* Leave iteration count at 0

1. "Encryption" tab:

	* Select the "AES (CBC; 256/128)" cypher	
	* Select "ESSIV" as the IV generation method
	* Set "Sector zero location" to "Start of encrypted data"	
	* Select "SHA-256 (256/512)" as the IV hash
	* Select "AES (CBC; 256/128)" as the IV cypher


1. "File options" tab:

	* Leave offset at 0
	* Leave sizelimit at 0

1. "Open options" tab:

	* Select any unused drive letter
	* Leave readonly unchecked

1. Click the "OK" button


* * * 
<A NAME="level_3_heading_6">
### Example #4: Opening a dm-crypt Container Encrypted Using 448 bit Blowfish
</A>

This example demonstrates use of a dm-crypt Blowfish 448 container.

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_blowfish_448.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_blowfish_448.vol
echo password1234567890ABC | cryptsetup -c blowfish -s 448 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:

1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile  blank
	* Leave seed blank
	* Select the "RIPEMD-160 (160/512)" hash	
	* Ensure "Hash with "A"s, if hash output is too short" is checked.
	* Leave iteration count at 0

1. "Encryption" tab:

	* Select the "Blowfish (CBC; 448/64)" cypher
	* Select "32 bit sector ID" as the IV generation method* Set "Sector zero location" to "Start of encrypted data"

1. "File options" tab:

	* Leave offset at 0
	* Leave sizelimit at 0

1. "Open options" tab:

	* Select any unused drive letter
	* Leave readonly unchecked

1. Click the "OK" button


* * * 
<A NAME="level_3_heading_7">
### Example #5: Opening a dm-crypt Container Encrypted Using 256 bit Twofish and Offset
</A>

This example demonstrates use of a dm-crypt Twofish 256 container, with the
encrypted container beginning at an offset of 3 sectors (3 x 512 = 1536 bytes) into the container
file.

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_twofish_o3.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_twofish_o3.vol
echo password1234567890ABC | cryptsetup -c twofish -o 3 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:

1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:
	
	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile  blank
	* Leave seed blank
	* Select the "RIPEMD-160 (160/512)" hash

    * Ensure "Hash with "A"s, if hash output is too short" is checked.

  * Leave iteration count at 0

1. "Encryption" tab:

	* Select the "Twofish (CBC; 256/128)" cypher
	* Select "32 bit sector ID" as the IV generation method* Set "Sector zero location" to "Start of encrypted data"

1. "File options" tab:

	* Set offset to 1536 bytes (i.e. 3 sectors, each of 512 bytes)* Leave sizelimit at 0

1. "Open options" tab:

	* Select any unused drive letter
	* Leave readonly unchecked

1. Click the "OK" button


* * * 
<A NAME="level_3_heading_8">
### Example #6: Opening a dm-crypt Container Encrypted Using 256 bit AES with MD5 Password Hashing
</A>

This example demonstrates use of a dm-crypt Twofish 256 container, with the
user's password processed with MD5.

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_aes_md5.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_aes_md5.vol
echo password1234567890ABC | cryptsetup -c aes -h md5 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:


1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile blank
	* Leave seed blank
	* Select the "MD5 (128/512)" hash
	* Ensure "Hash with "A"s, if hash output is too short" is checked.
	
	* Leave iteration count at 0

1. "Encryption" tab:

	* Select the "AES (CBC; 256/128)" cypher		
	* Select "32 bit sector ID" as the IV generation method
	* Set "Sector zero location" to "Start of encrypted data"


1. "File options" tab:

		* Leave offset at 0
    * Leave sizelimit at 0


1. "Open options" tab:

	* Select any unused drive letter
	* Leave readonly unchecked

1. Click the "OK" button

* * * 
<A NAME="level_3_heading_9">
### Example #7: Opening a dm-crypt Container Encrypted Using 448 bit Blowfish, MD5 Password Hashing and SHA-256 ESSIV
</A>

This example demonstrates use of a dm-crypt Blowfish 448 container, with the
user's password processed with MD5 and ESSIV using SHA-256.

Note that although the main cypher is Blowfish 448, Blowfish 256 is used as the IV cypher as the IV hash outputs 256 bytes

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_blowfish_448_essivsha256_md5.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_blowfish_448_essivsha256_md5.vol
echo password1234567890ABC | cryptsetup -c blowfish-cbc-essiv:sha256 -s 448 -h md5 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:


1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

	* Enter "password1234567890ABC" as the key
	* Leave GPG executable blank
	* Leave GPG keyfile blank
	* Leave seed blank
	* Select the "MD5 (128/512)" hash
	* Ensure "Hash with "A"s, if hash output is too short" is checked.
	
	* Leave iteration count at 0

1. "Encryption" tab:

		* Select the "Blowfish (CBC; 448/64)" cypher
    * Select "ESSIV" as the IV generation method
    * Set "Sector zero location" to "Start of encrypted data"
    * Select "SHA-256 (256/512)" as the IV hash
    * Select "Blowfish (CBC; 256/64)" as the IV cypher


1. "File options" tab:

1. Leave offset at 0

    * Leave sizelimit at 0


1. "Open options" tab:

		* Select any unused drive letter
		* Leave readonly unchecked

1. Click the "OK" button


* * * 
<A NAME="level_3_heading_10">
### Example #8: Opening a dm-crypt Container Encrypted Using AES-256 in XTS Mode (aka XTS-AES-256)
</A>

This example demonstrates use of a dm-crypt AES-256 container in XTS mode (aka XTS-AES-256) and using SHA-512 for hashing

Creating the container file under Linux:

<blockquote>
<pre>
dd if=/dev/zero of=./containers/vol_aes_xts.vol bs=1K count=100
losetup /dev/loop0 ./containers/vol_aes_xts.vol
echo password1234567890ABC | cryptsetup -h sha512 -c aes-xts-plain --key-size 512 create myMapper /dev/loop0
dmsetup ls
dmsetup table
dmsetup status
losetup /dev/loop1 /dev/mapper/myMapper 
mkdosfs /dev/loop1
mkdir ./test_mountpoint
mount /dev/loop1 ./test_mountpoint
cp ./test_files/SHORT_TEXT.txt        ./test_mountpoint
cp ./test_files/BINARY_ZEROS.dat      ./test_mountpoint
cp ./test_files/BINARY_ABC_RPTD.dat   ./test_mountpoint
cp ./test_files/BINARY_00_FF_RPTD.dat ./test_mountpoint
umount ./test_mountpoint
losetup -d /dev/loop1
cryptsetup remove myMapper
losetup -d /dev/loop0
rm -rf ./test_mountpoint
</pre>
</blockquote>

Opening the container under LibreCrypt:


1. Select "Linux | Open..."
1. Select the container file
1. "Key" tab:

		* Enter "password1234567890ABC" as the key
		* Leave GPG executable blank
		* Leave GPG keyfile  blank
		* Leave seed blank
		* Select the "SHA-512 (512/1024)" hash
		* Ensure "Hash with "A"s, if hash output is too short" is checked.
		* Leave iteration count at 0

1. "Encryption" tab:

		* Select the "AES (256 bit XTS)" cypher
		* Select "Null IV" as the IV generation method

1. "File options" tab:

		* Leave offset at 0
		* Leave sizelimit at 0

1. "Open options" tab:

		* Select any unused drive letter
		* Leave readonly unchecked

1. Click the "OK" button




