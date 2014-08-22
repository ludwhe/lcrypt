

<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
<meta name="keywords" content="disk encryption, security, transparent, AES, OTFE, plausible deniability, virtual drive, Linux, MS Windows, portable, USB drive, partition">
<meta name="description" content="DoxBox: An Open-Source 'on-the-fly' transparent disk encryption program for PCs. Using this software, you can create one or more &quot;virtual disks&quot; on your PC - anything written to these disks is automatically, and securely, encrypted before being stored on your computers hard drive.">

<meta name="author" content="Sarah Dean">
<meta name="copyright" content="Copyright 2004, 2005, 2006, 2007, 2008 Sarah Dean">
<meta name="ROBOTS" content="ALL">

<TITLE>Technical Details: Creating FreeOTFE Volumes</TITLE>

<link href="./styles_common.css" rel="stylesheet" type="text/css">

<link rev="made" href="mailto:sdean12@sdean12.org">
<link rel="shortcut icon" href="./images/favicon.ico" type="image/x-icon">

<SPAN CLASS="master_link">
[![DoxBox logo](./images/FreeOTFE.gif)](http://DoxBox.squte.com/)
[DoxBox](http://DoxBox.squte.com/)
</SPAN>
<SPAN CLASS="master_title">
_Open-Source disk encryption for Windows_
</SPAN>

      
            

### Technical Details: Creating FreeOTFE Volumes

To create a DoxBox file, a fairly significant amount of
information is required due to freedom that FreeOTFE gives you in
creating volume files. 

Broadly speaking, creating a DoxBox consists of three distinct stages:

<OL>

  * Creating
a file large enough on the local filesystem to store the encrypted
partition image (and CDB, if included as part of the volume).
  * Writing a CDB either to the volume file or a separate keyfile, depending on the user's choice.
  * Mounting the volume, formatting it, and "shredding" (overwriting) all free space.

</OL>

Stage 1 is straightforward; write data to the file until is has gained
the required size. This stage is skipped in the case of creating a
hidden volume or volume based on a partition.

Stage 2 is more complex; and is described below.

Stage 3 is required in set the volume up for use, and increase
security. This is largely a manual process carried out by the user,
depending on their needs.

<A NAME="level_4_heading_1">
#### Writing the CDB/keyfile
</A>

The following procedure is used to build up a FreeOTFE CDB/keyfile:

<OL>

* Obtain all the information which will be stored within the volume's "Volume details block"
* Derive
the "critical data key" by processing the user's password and salt with
PKCS #5 PBKDF2 (using HMAC with the user's choice of hash algorithm).

The derived key should be **ks** bits long (i.e. the cypher's keysize). If **ks**
is undefined, then 512 bits will be used. (Note: In this case, the
keysize used for encrypting/decrypting the encrypted partition image
must be specified by the user. The keysize for the critical data block
is fixed at 512 bits if **ks **is
undefined in order to simplify the "mount volume" dialog, and to reduce
the potential for user confusion as most cyphers have a fixed **ks**,
and asking users for this information may cause them to think this is
more information they have to memorise, which it wouldn't be)
* Create the plaintext version of the "Volume details block" in memory, including padding the end with random data as appropriate
  * Calculate the check MAC using HMAC, together with the derived key and user's choice of hash algorithm
* Truncate the MAC to 512 bits if it is longer, or right-pad to 512 bits with random data to if less.

  * Prepend the check MAC (and any random data appended to it) onto the beginning of the volume details
block to form a plaintext version
of the "Encrypted block"

  * Encrypt the plaintext "Encrypted block" using a null IV and the critical data key.
  * Prepend the salt bytes onto the end of the "Encrypted block", and pad out the end with random data to form the complete CDB
  * Write the CDB to either:

<UL>
  * The start of the user's volume

  * A keyfile

  * The user specified offset within the host volume, if creating a "hidden volume" which includes a CDB</UL>
</OL>


