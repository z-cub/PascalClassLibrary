{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit PinConnection;

interface

uses
  USerialPort, UPacketBurst, UCommFrame, UCommHub, UCommPin, UCommSerialPort, 
  UCommThread, UCommConcentrator, UCommDelay, UCommTCPClient, UCommTCPServer, 
  UCommTelnet, UCommTelnetComPortOption, UCommMark, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('PinConnection', @Register);
end.
