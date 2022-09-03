unit Server.Arquivo.Consts;

interface

type
  TUploadMethod = (JsonContent, StreamContent);

  TUploadMethodHelper = record helper for TUploadMethod
  public
    function ToString: string;
  end;

implementation

{ TUploadMethodHelper }

function TUploadMethodHelper.ToString: string;
begin
  case Self of
    JsonContent: Result := 'JsonBase64';
    StreamContent: Result := 'Stream';
  end;
end;

end.
