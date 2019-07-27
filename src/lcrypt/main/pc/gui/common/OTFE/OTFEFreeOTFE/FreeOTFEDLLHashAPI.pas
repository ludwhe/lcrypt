unit FreeOTFEDLLHashAPI;

// API ported from FreeOTFE4PDAHashAPI.h

interface

uses
  FreeOTFEHashDriverAPI, Windows;


 //#define DLLEXPORT_HASH_IDENTIFYDRIVER  TEXT("HashIdentifyDriver")
 //typedef DWORD (* PHashDLLFnIdentifyDriver)(
 //                                 DIOC_HASH_IDENTIFYDRIVER*
 //                                );
const
  DLLEXPORT_HASH_IDENTIFYDRIVER = 'HashIdentifyDriver';

type
  PHashDLLFnIdentifyDriver = function(Buffer: PDIOC_HASH_IDENTIFYDRIVER): DWORD; CDECL;


 //#define DLLEXPORT_HASH_IDENTIFYSUPPORTED TEXT("HashIdentifySupported")
 //typedef DWORD (* PHashDLLFnIdentifySupported)(
 //                                 DWORD,
 //                                 DIOC_HASH_IDENTIFYSUPPORTED*
 //                                );
const
  DLLEXPORT_HASH_IDENTIFYSUPPORTED = 'HashIdentifySupported';

type
  PHashDLLFnIdentifySupported = function(BufferSize: DWORD;  // In bytes
    Buffer: PDIOC_HASH_IDENTIFYSUPPORTED): DWORD; CDECL;


 //#define DLLEXPORT_HASH_GETHASHDETAILS TEXT("HashGetHashDetails")
 //typedef DWORD (* PHashDLLFnGetHashDetails)(
 //                                 GUID*,
 //                                 HASH*
 //                                );
const
  DLLEXPORT_HASH_GETHASHDETAILS = 'HashGetHashDetails';

type
  PHashDLLFnGetHashDetails = function(HashGUID: PGUID; HashDetails: PHASH): DWORD; CDECL;

 //#define DLLEXPORT_HASH_HASH TEXT("HashHash")
 //typedef DWORD (* PHashDLLFnHash)(
 //                          GUID*,
 //                          unsigned int,
 //                          FREEOTFEBYTE*,
 //                          unsigned int*,
 //                          FREEOTFEBYTE*
 //                         );
const
  DLLEXPORT_HASH_HASH = 'HashHash';

type
  PHashDLLFnHash = function(HashGUID: PGUID; BufferSizeIn: Cardinal;
    BufferIn: PByte; ptrBufferSizeOut: PCardinal; BufferOut: PByte): DWORD; CDECL;


implementation

end.
