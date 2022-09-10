unit UPDClientXMLRPC;

interface

uses
  Classes, SysUtils, UPDClient;

type

  { TPDClientXMLRPC }

  TPDClientXMLRPC = class(TPDClient)
    constructor Create(AOwner: TComponent); override;
  end;


implementation

{ TPDClientXMLRPC }

constructor TPDClientXMLRPC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BackendName := 'XMLRPC';
end;

end.

