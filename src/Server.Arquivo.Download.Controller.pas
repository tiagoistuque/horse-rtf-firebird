unit Server.Arquivo.Download.Controller;

interface

uses
  Classes, DB, System.JSON,
  Horse;

type
  TDownloadController = class
  private
    class procedure DownloadStreamFileRTF(Req: THorseRequest; Res: THorseResponse);
    class procedure GetFileRTF(Req: THorseRequest; Res: THorseResponse);

    class function _GetFirstFileStreamInDatabase(out AFileName: string): TMemoryStream;
  public
    class procedure Registry;
  end;

implementation

{ TDownloadController }

uses
  Horse.Commons,
  System.NetEncoding,
  Server.Arquivo.DataModule;

class procedure TDownloadController.DownloadStreamFileRTF(Req: THorseRequest; Res: THorseResponse);
const
  Content_Type = 'application/rtf';
var
  LStream: TStream;
  LFileName: string;
begin
  LStream := _GetFirstFileStreamInDatabase(LFileName);
  if not Assigned(LStream) then
    raise EHorseException.New
      .Title('No content')
      .Error('No content encountered in database')
      .Status(THTTPStatus.BadRequest);
  Res.Download(LStream, LFileName, Content_Type);
end;

class procedure TDownloadController.GetFileRTF(Req: THorseRequest; Res: THorseResponse);
var
  LStream: TStream;
  LFileName: string;
  LJsonObject: TJSONObject;
  LFileObj: TJSONObject;
  LStringStream: TStringStream;
begin
  LStream := _GetFirstFileStreamInDatabase(LFileName);
  LStringStream := TStringStream.Create;
  try
    if not Assigned(LStream) then
      raise EHorseException.New
        .Title('No content')
        .Error('No content encountered in database')
        .Status(THTTPStatus.BadRequest);

    TNetEncoding.Base64.Encode(LStream, LStringStream);

    LFileObj := TJSONObject.Create;
    LFileObj.AddPair('fileName', LFileName);
    LFileObj.AddPair('data',  LStringStream.DataString);

    LJsonObject := TJSONObject.Create;
    LJsonObject.AddPair('file', LFileObj);
    Res.Send<TJSONObject>(LJsonObject);
  finally
    LStream.Free;
    LStringStream.Free;
  end;
end;

class procedure TDownloadController.Registry;
begin
  THorse.Group
    .Prefix('/download')
    .Get('/stream', DownloadStreamFileRTF);
  THorse.Group
    .Prefix('/files')
    .Get(':fileName', GetFileRTF);
end;

class function TDownloadController._GetFirstFileStreamInDatabase(out AFileName: string): TMemoryStream;
var
  LDM: TDataModule1;
begin
  Result := nil;
  LDM := TDataModule1.Create(nil);
  try
    LDM.FDQuery1.SQL.Text := 'SELECT FIRST 1 * FROM UPLOADS WHERE FILE IS NOT NULL';
    LDM.FDQuery1.Open;
    if LDM.FDQuery1.RecordCount > 0 then
    begin
      Result := TMemoryStream.Create;
      AFileName := LDM.FDQuery1.FieldByName('FILE_NAME').AsString;
      TBlobField(LDM.FDQuery1.FieldByName('FILE')).SaveToStream(Result);
      Result.Position := 0;
    end;
  finally
    LDM.Free;
  end;
end;

end.
