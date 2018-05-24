# dependencies

This directory contains 3rd party source code required to build the FreeOTFE drivers.

In each case, two copies are included:

- The original 3rd party source release
- The above, uncompressed and preconfigured ready for use

Please note that this software is covered by the licences included, and by not the main FreeOTFE licence (for example, libtomcrypt is in the public domain, while twofish is uncopyrighted and license-free)

3rd party source included is:

## libtomcrypt

Tom's Crypto lib library (obtained from: [libtomcrypt.org](http://libtomcrypt.org/))

## twofish

Counterpane Twofish; the reference and optimised implementations (obtained from: [schneier.com](http://www.schneier.com/twofish.html))

## aes

Brian Gladman's AES First and Second Round Implementation Experience (obtained from: [fp.gladman.plus.com](http://fp.gladman.plus.com/cryptography_technology/aesr1/index.htm) and [fp.gladman.plus.com](http://fp.gladman.plus.com/cryptography_technology/aesr2/index.htm))
Note: The decompressed version has been modified to make it threadsafe

## ltc\_gladman\_xts

The files in this directory are a version of the LibTomCrypt XTS cypher mode library which has been modified to allow its use with the Gladman cypher libraries.
