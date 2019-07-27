unit SDUEndianIntegers;

interface

uses
  Windows;  // Required for DWORD;

type
  // 32 bit big endian numbers
  TSDUBigEndian32 = array [0..(4-1)] of byte;

  // 32 bit big endian numbers
  TSDULittleEndian32 = array [0..(4-1)] of byte;

function SDUBigEndian32ToDWORD(number: TSDUBigEndian32): DWORD;
function SDUBigEndian32ToString(number: TSDUBigEndian32): Ansistring; { TODO 1 -otdk -cclean : use byte areays }
function SDUDWORDToBigEndian32(number: DWORD): TSDUBigEndian32;

implementation

// Convert from big-endian to DWORD
function SDUBigEndian32ToDWORD(number: TSDUBigEndian32): DWORD;
begin
  Result :=
            (number[0] * $01000000) +
            (number[1] * $00010000) +
            (number[2] * $00000100) +
            (number[3] * $00000001);
end;

function SDUBigEndian32ToString(number: TSDUBigEndian32): Ansistring;
begin
  Result :=
            Ansichar(number[0] * $01000000) +
            Ansichar(number[1] * $00010000) +
            Ansichar(number[2] * $00000100) +
            Ansichar(number[3] * $00000001);
end;


function SDUDWORDToBigEndian32(number: DWORD): TSDUBigEndian32;
begin
  Result[0] := (number and $FF000000) shr 24;
  Result[1] := (number and $00FF0000) shr 16;
  Result[2] := (number and $0000FF00) shr 8;
  Result[3] := (number and $000000FF);


end;

END.


