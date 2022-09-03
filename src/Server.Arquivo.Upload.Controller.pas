unit Server.Arquivo.Upload.Controller;

interface

uses
  Classes, SysUtils,
  Horse, Server.Arquivo.Consts;

type
  TUploadController = class
  private
    class procedure SaveRTFFileInFirebird(Req: THorseRequest; Res: THorseResponse);
    class procedure DoPostDocument(Req: THorseRequest; Res: THorseResponse);
    class procedure _SaveToDB(const AStream: TStream; const AFileName: string; const AMethod: TUploadMethod);
  public
    class procedure Registry;
  end;

implementation

{ TUploadController }

uses
  Horse.Commons,
  System.JSON,
  System.NetEncoding,
  DB, Math,
  Server.Arquivo.DataModule;

class procedure TUploadController.DoPostDocument(Req: THorseRequest; Res: THorseResponse);
const
  Content_Type = 'application/json';
var
  LBytesStream: TBytesStream;
  LFileStream: TFileStream;
  LJSON: TJSONValue;
  LObjectFile: TJSONObject;
  LContentInBase64: string;
  LTemporaryFileName: string;
  LStream: TMemoryStream;
  LFileName: string;
begin
  if not(Req.RawWebRequest.ContentType = Content_Type) then
    raise EHorseException.New
      .Title('Invalid content type')
      .Error('Only .rtf files are accepted. Tip: Add the Content-Type=application/json header')
      .Status(THTTPStatus.BadRequest);

  try
    LJSON := TJSONObject.ParseJSONValue(Req.Body);
  except
    raise EHorseException.New
      .Title('Invalid JSON')
      .Error('The content is not a valid JSON')
      .Status(THTTPStatus.BadRequest);
  end;

  if not Assigned(LJSON) then
  begin
    raise EHorseException.New
      .Title('Invalid JSON')
      .Error('The content is not a valid JSON')
      .Status(THTTPStatus.BadRequest);
  end;

  LJSON.TryGetValue<TJSONObject>('file', LObjectFile);
  if not Assigned(LObjectFile) then
  begin
    raise EHorseException.New
      .Title('Invalid JSON')
      .Error('The content is not a valid JSON')
      .Status(THTTPStatus.BadRequest);
  end;
  LObjectFile.TryGetValue<string>('fileName', LFileName);
  LObjectFile.TryGetValue<string>('data', LContentInBase64);
  if LFileName.IsEmpty then
    LFileName := Format('%s.rtf', [FormatDateTime('yyyymmddmmnnsszzz', Now)]);
  LStream := TMemoryStream.Create;
  LBytesStream := TBytesStream.Create(TNetEncoding.Base64.DecodeStringToBytes(LContentInBase64));
  LFileStream := TFileStream.Create(LFileName, fmCreate or fmShareExclusive);
  try
    LBytesStream.Position := 0;
    LFileStream.CopyFrom(LBytesStream, LBytesStream.Size);
    LFileStream.Free;
    LStream.LoadFromFile(LFileName);
    _SaveToDB(LStream, LFileName, TUploadMethod.JsonContent);
  finally
    DeleteFile(LFileName);
    LStream.Free;
    LBytesStream.Free;
  end;

end;

class procedure TUploadController.SaveRTFFileInFirebird(Req: THorseRequest; Res: THorseResponse);
const
  Content_Type = 'application/rtf';
var
  LStream: TMemoryStream;
  LContentLength: Integer;
  LBytesRead: Integer;
  LBuffer: array [0 .. 1023] of Byte;
  LFileName: string;
begin
  if not(Req.RawWebRequest.ContentType = Content_Type) then
    raise EHorseException.New
      .Title('Invalid content type')
      .Error('Only .rtf files are accepted. Tip: Add the Content-Type=application/rtf header');

  LFileName := Req.Headers.Field('x-filename').Required(True).RequiredMessage('x-filename header needs to be informed with the file name.').AsString;


  {$IF CompilerVersion <= 28}
  Assert(Length(Req.RawWebRequest.RawContent) = Req.RawWebRequest.ContentLength);
  {$ELSE}
  Req.RawWebRequest.ReadTotalContent;
  {$ENDIF}
  LStream := TMemoryStream.Create;
  try

    LContentLength := Req.RawWebRequest.ContentLength;
    while LContentLength > 0 do
    begin
      LBytesRead := Req.RawWebRequest.ReadClient(LBuffer[0], Min(LContentLength, SizeOf(LBuffer)));
      if LBytesRead < 1 then
        Break;
      LStream.WriteBuffer(LBuffer[0], LBytesRead);
      Dec(LContentLength, LBytesRead);
    end;
    LStream.Position := 0;
    _SaveToDB(LStream, LFileName, TUploadMethod.StreamContent);

  finally
    LStream.Free;
  end;
end;

class procedure TUploadController._SaveToDB(const AStream: TStream; const AFileName: string; const AMethod: TUploadMethod);
var
  LDM: TDataModule1;
begin
  if AStream.Size = 0 then
    raise EHorseException.New
      .Title('Invalid stream')
      .Error('Sent an invalid stream content');

  LDM := TDataModule1.Create(nil);
  try
    LDM.FDQuery1.SQL.Text := 'INSERT INTO UPLOADS(FILE, FILE_NAME, UPLOAD_METHOD) VALUES(:pContent, :pFileName, :pMethod)';
    LDM.FDQuery1.Params.ParamByName('pContent').LoadFromStream(AStream, ftBLob);
    LDM.FDQuery1.Params.ParamByName('pFileName').AsString := AFileName;
    LDM.FDQuery1.Params.ParamByName('pMethod').AsString := AMethod.ToString;
    LDM.FDQuery1.ExecSQL;
  finally
    LDM.Free;
  end;
end;

class procedure TUploadController.Registry;
begin
  THorse.Group
    .Prefix('/upload')
    .Post('/stream', SaveRTFFileInFirebird)
    .Post('/json', DoPostDocument);
end;

end.
