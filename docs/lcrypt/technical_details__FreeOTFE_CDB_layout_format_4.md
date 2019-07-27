

<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
<meta name="keywords" content="disk encryption, security, transparent, AES, plausible deniability, virtual drive, Linux, MS Windows, portable, USB drive, partition">
<meta name="description" content="LibreCrypt: An Open-Source transparent encryption program for PCs. With this software, you can create one or more &quot;containers&quot; on your PC - which appear as disks, anything written to these disks is automatically encrypted before being stored on your hard drive.">

<meta name="author" content="Sarah Dean">
<meta name="copyright" content="Copyright 2004, 2005, 2006, 2007, 2008 Sarah Dean 2015 tdk">


<TITLE>Technical Details: FreeOTFE Header ( Critical Data Block / CDB) Layout (CDB Format ID 4)</TITLE>

<link href="https://raw.githubusercontent.com/t-d-k/librecrypt/master/docs/styles_common.css" rel="stylesheet" type="text/css">


<link rel="shortcut icon" href="https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox.ico" type="image/x-icon">

<SPAN CLASS="master_link">
[![LibreCrypt logo](https://github.com/t-d-k/librecrypt/raw/master/src/Common/Common/images/DoxBox128.png)](http://LibreCrypt.eu/)
</SPAN>
<SPAN CLASS="master_title">
_[LibreCrypt](http://LibreCrypt.eu/): Open-Source disk encryption for Windows_
</SPAN>
***

      
            

### Technical Details: LibreCrypt Critical Data Block (CDB) Layout (CDB Format ID 4)

*This format is used by FreeOTFE v5, and is the default 'FreeOTFE' format used by LibreCrypt. LibreCrypt supports only this FreeOTFE volume format*

CDB layout format 4 is identical to CDB layout format 3, with the one exception that the Master key stored within the Volume details block may include multiple keys, one after the other

For example:

  * An LRW encrypted volume's "Master key" will be the encryption key, followed immediately by the tweak key.
  * An XTS encrypted volume's "Master key" will be the two XTS encryption keys, one after the other

In all cases, the Master key length will indicate the total length of all keys. It is the responsibility of the cypher driver to determine how the key material is used.

FreeOTFE v3.0 (and later) create volumes using this layout.



<A NAME="level_4_heading_1">
#### Overview
</A>

A FreeOTFE container header consists of **CDL** bits of data. The following table describes the high-level layout of a container header:

<TABLE style="width: 100%;">
	
	<TBODY>
	<TR>
	<TD style="background-color: rgb(255, 204, 204);">Header:
		<TABLE>
			<TBODY>
			<TR>
				<TD>Password salt</TD>
				
				<TD style="background-color: rgb(153, 255, 255);">Encrypted block:
				<TABLE>
					<TBODY>
					<TR>
						<TD>Check MAC</TD> 
						<TD>Random padding #3                   </TD>
						<TD>Volume details block: 
						<TABLE>
							<TBODY>
							<TR>
								<TD>CDB format ID </TD>
								<TD>Volume flags</TD>
								<TD>Encrypted partition image length</TD>
								<TD>Master key length</TD>
								<TD>Master key</TD>
								<TD>Requested drive letter</TD>		
								<TD>Volume IV length</TD>		
								<TD>Volume IV</TD>
								<TD>Sector IV generation method</TD>
								<TD>Random padding #2</TD>		
							</TR>
							</TBODY>
						</TABLE>
						</TD>	
					</TR>
					</TBODY>
				</TABLE>
			</TD>
			<TD>Random padding #1</TD>	
		</TR>
		</TBODY>
		</TABLE>
	</TD>	
	</TR>
	</TBODY>
</TABLE>

Color key:

<TABLE>
	
	<TBODY>
	<TR> 
		<TH>Color </TH> <TH>Encryption used </TH> 
	</TR>
	
	<TR> 
		<TD style="background-color: rgb(255, 204, 204);">	</TD> 
		<TD>Red items are not encrypted</TD> 
	</TR>
	<TR> 
		<TD style="background-color: rgb(153, 255, 255);">	</TD> 
		<TD>Blue items are encrypted with the user's chosen cypher together with a "critical data key" generated using PKCS#5 PBKDF2 (with HMAC PRF) together with the user's password, salt, and chosen hash algorithm</TD> 
	</TR>	
	</TBODY>
</TABLE>

Seem intimidating? Read on, and all will become clear... When broken down into its component parts, the Header structure is reasonably straightforward to understand.

Note: Throughout this document, the following definitions apply:

<TABLE>

  <TBODY>
    <TR> <TH>Variable </TH> <TH>Definition </TH> </TR>
    <TR> <TD>_CDL_</TD> <TD>Critical Data Length (in bits)  This is defined as 4096 bits.</TD> </TR>
    <TR> <TD>_MML_</TD> <TD>Maximum MAC Length (in bits)  This is defined as 512 bits.</TD> </TR>
    <TR> <TD>**sl**</TD> <TD>Salt length (in bits)  This is the user specified salt length, as specified by the user when the Header is created</TD> </TR>
    <TR> <TD>**cbs**</TD> <TD>Cypher Block Size (in bits)  The block size of the cypher used to encrypt the volume</TD> </TR>
    <TR> 
    	<TD>**cks**</TD> 
    	<TD>Cypher Key Size (in bits)  The key size of the cypher used to encrypt the volume.  If the cypher accepts variable length keysizes, this is set to a user-specified value up to a maximum of 512.</TD> 
    </TR>
    <TR> <TD>**ml**</TD> <TD>MAC length (in bits)  This is the length of MAC generated</TD> </TR>
  </TBODY>
</TABLE>

* * *

#### Breakdown: Header layout

<TABLE>

<TBODY>
	<TR> <TD>Password salt</TD> <TD>Encrypted block</TD><TD>Random padding #1</TD> </TR>
</TBODY>
</TABLE>

<TABLE>

<TBODY>
	<TR> 
		<TH>Item name</TH> <TH>Size (in bits)</TH> <TH>Description</TH> 
	</TR>
	
	<TR>
		<TD>Password salt</TD> 
		<TD>**sl**  (User specified to a max 512)</TD> 
		<TD>This data is used together with the user's password to derive the "critical data key". This key is then used to encrypt/decrypt the "Encrypted block".</TD> 
	</TR>
	
	<TR> 
		<TD>Encrypted block</TD> 
		<TD>If **cbs**&gt;8 then:  ((**CDL** - **sl**) div **cbs)** * **cbs**  If **cbs**&lt;=8 then:  (**CDL** - **sl**)  This size is referred to as "**leb**"</TD> 
		<TD>This block contains the actual key which is used to encrypt/decrypt the encrypted partition image. See below for further breakdown. </TD> 
	</TR>
	
	<TR> 
		<TD>Random padding #1</TD> 
		<TD>((**CDL**- **sl**) - **leb**)</TD> 
		<TD>Random "padding" data. Required to pad out any remaining, unused, bits in the **"critical data block"**</TD> 
	</TR>
	
	<TR> 
		<TD>*_Total size:_*</TD> 
		<TD>**CDL**</TD> 
		<TD></TD> 
	</TR>
	
	</TBODY>
</TABLE>

* * *

#### Breakdown: Encrypted block layout

<TABLE>

<TBODY>
<TR> <TD>Check MAC</TD> <TD>Random padding #3</TD> <TD>Volume details block</TD> </TR>
</TBODY>
</TABLE>

As described above, this entire block is encrypted using the user's password, salt, and chosen hash and cypher algorithms. 

As this block is encrypted, its length (in bits) must be a multiple of the cypher's blocksize.

<TABLE>
<TBODY>
	<TR>
		<TH>Item name</TH>
		<TH>Size (in bits)</TH>
		<TH>Description</TH>
	</TR>
	<TR>
		<TD>Check MAC</TD><TD>_ml  _Up to a maximum of **MML **bits_        _ </TD>
		<TD>This is the MAC of the plaintext version of the "Volume details block".  If **hk** is zero or undefined, then this hash will be either truncated to **MML **bits, or right-padded with 0 bits up to a maximum of **MML **bits</TD>
	</TR>
	<TR> 
		<TD>Random padding #3</TD> <TD>**MML** - **ml**</TD> 
		<TD>Random "padding" data. Required to pad out the check MAC to a predetermined number of bits.</TD> 
	</TR>
	<TR>
		<TD>Volume details</TD><TD>**leb** - **MML ** </TD>
		<TD>This stores the details of how to encrypt/decrypt the encrypted partition.</TD>
	</TR>
	<TR>
		<TD>*_Total size:_*</TD><TD>**leb** </TD><TD>       </TD>
	</TR>
</TBODY>
</TABLE>
* * *

#### Breakdown: Volume details block layout

<TABLE>

<TBODY>
<TR>
	<TD>CDB format ID</TD>	
	<TD>Volume flags</TD>
	<TD>Encrypted partition image length</TD>
	<TD>Master key length</TD>
	<TD>Master key</TD>
	<TD>Requested drive letter</TD>
	<TD>Volume IV length</TD>
	<TD>Volume IV</TD>
	<TD>Sector IV generation method</TD>
	<TD>Random padding #2</TD>
</TR>

</TBODY>
</TABLE>

Finally, we reach the details that the critical data block was designed to protect. All of the items within this block have bit order: MSB first.

<TABLE>
<TBODY>

<TR>
	<TH>Item name</TH> 
	<TH>Size (in bits)</TH> 
	<TH>Description</TH> 
</TR>

<TR>
	<TD>CDB format ID</TD>	
	<TD>8</TD>
	<TD>This is a version ID which identifies the layout of the remainder of the volume details block. When this layout format is used, this will always be set to 4.  				
			Later volume file layouts may have different items in this section, or the layout may change; in which case a different version ID will be used here.
	</TD>
</TR>

<TR>
	<TD>Volume flags</TD> 
	<TD>32</TD> 
	<TD>Bitmap flagging various items.
	
	Bit - Description
	
	0 - (unused)
	
	1 - Sector ID zero is at the start of the file
		0 = Sector ID zero is at the start of the encrypted data  	   				 
		1 = Sector ID zero is at the start of the host volume file/partition  
	2 - (unused) 
	3 - (unused)  
	4 - Volume file timestamps normal operation  						 
		0 = On dismount, volume file timestamps will be reset to the values they were when mounted
		1 = On dismount, volume file timestamps will be left as-is (i.e. will indicate the date/time the volume was last written to)
		Note: This bit gets ignored by the GUI, which will operate it according to the user options set at the time the volume is mounted
	</TD>

</TR>

<TR>
	<TD>Encrypted partition image length</TD>
	<TD>64</TD>
	<TD>This stores the **length** of the encrypted partition image **in bytes.**</TD>
</TR>

<TR>
	<TD>Master key length</TD>
	<TD>32</TD>
	<TD>This will be set to the length of the master key **in bits**.</TD>
</TR>

<TR>
	<TD>Master key</TD>
	<TD>_cks_</TD>
	<TD>This is set to the random data generated when the volume was created; and is the en/decryption key used to encrypt the encrypted partition image</TD>
</TR>

<TR>
	<TD>Requested drive letter</TD>
	<TD>8</TD>
	<TD>The drive letter the volume should be normally be mounted as.  Set to 0x00 if there is no particular drive letter the volume should be mounted as (i.e. mount using the first available drive letter).</TD>
</TR>

<TR>
	<TD>Volume IV length</TD>
	<TD>32</TD>
	<TD> This will be set to the length of the Volume IV **in bits**.  If the cypher's blocksize is &gt;= 0, this will be set to the cypher's blocksize.  Otherwise, this will be set to 0.</TD>
</TR>

<TR>
	<TD>Volume IV</TD>
	<TD>If (**cbs** &gt; 0), then:_  cbs        _If (**cbs** &lt;= 0), then  0_        _       </TD>
	<TD>This is set to the random data generated when the volume was created. When each sector of the encrypted partition is encrypted/decrypted, this value will be XORd with any (hashed or unhashed) sector ID before being used as the sector IV.  This guarantees that every sector within the encrypted partition has a non-predictable IVs.</TD>
</TR>

<TR>
	<TD>Sector IV generation method</TD>
	<TD>8</TD>
	<TD>This is set to indicate the method of generating sector IVs. Note that if a volume IV is present, then it will be XORd with the IV generated using this method, before it is used for encryption/decryption. In all cases, the sector IV generated will be right-padded/truncated to the cypher's blocksize.  If the cypher's blocksize is &lt;= 0, then this must be set to 0.  
	0 - No sector IVs (Null sector IV)  
	1 - Sector IV is the 32 bit sector ID (LSB first)  
	2 - Sector IV is the 64 bit sector ID (LSB first)  
	3 - Hash of the 32 bit sector ID (sector ID is LSB first)  
	4 - Hash of the 64 bit sector ID (sector ID is LSB first)  
	5 - ESSIV  The "Volume flags" item is used to determine the location of sector zero (start of encrypted data, or start of host file/partition)</TD>
</TR>

<TR>
	<TD>Random padding #2</TD>
	<TD></TD>
	<TD>Random "padding" data. Required to pad out the encrypted block to a multiple of **bs**, and to increase the size of this block to the maximum length that can fit within the "critical data block".</TD>
</TR>

<TR>
	<TD>*_Total size:_*</TD>	
	<TD>**(leb****** - **MML)**  </TD>
	<TD>       	</TD>
</TR>

</TBODY></TABLE>

* * *

<A NAME="level_4_heading_2">
#### Miscellaneous Comments Regarding the Header Layout
</A>

The design of the critical data layout eliminates the need for the cypher/hash used to be stored anywhere, denying an attacker this information and increasing the amount of work required to attack a volume file.

The "password salt" appears **before** the "encrypted block", and no indication of the length of salt used is stored anywhere in order to prevent an attacker from even knowing where the "encrypted block" starts within the Header.

The "Check MAC" is limited to 512 bits. This is limited for practical reasons as some kind of limit is required if the critical data block is to be of a predetermined size. See section on mounting volume files for how multiple matching MACs are handled.

The "Password salt" is (fairly arbitrarily) limited to 512 bits. Again, this is primarily done for practical reasons.

Although at time of writing (March 2005) this limit to the length of salt used should be sufficient, the format of the critical data block (with included layout version ID) does allow future scope for modification in order to allow the critical data block to be extended (e.g. from 4096 to 8192 bits), should this limit be deemed inadequate..

The "Encrypted block" does contain a certain amount of data that may be reasonably guessed by an attacker (e.g. the CDB format ID), however this would be of very limited use to an attacker launching a "known plaintext" attack as the amount of this data is minimal, and as with pretty much any transparent encryption system the encrypted partition image can reasonably expected to contain significantly more known plaintext than the header anyway (e.g. the partition's boot sector)

##### Header Encryption

The encrypted data block within a header is encrypted using:

* A key derived from the user's password
* A NULL IV

The key is derived as follows:

1. The user's password is passed through "n" iterations (where "n" is user specified) of PKCS#5 PBKDF2 using HMAC as the PRF, which is turn employs the user's choice of hash algorithm. In doing so, the user's password is supplied as the password to PBKDF2, and the salt bits are used as the PBKDF2 salt.

<A NAME="level_5_heading_1">
##### Check MAC
</A>

The check bytes are calculated by passing the volume details block through HMAC with the user's choice of hash algorithm. In doing so, the derived key used to encrypt/decrypt the header is used as the HMAC key.




