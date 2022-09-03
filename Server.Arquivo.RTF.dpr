program Server.Arquivo.RTF;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Horse.HandleException,
  Server.Arquivo.DataModule in 'src\Server.Arquivo.DataModule.pas' {DataModule1: TDataModule},
  Server.Arquivo.Upload.Controller in 'src\Server.Arquivo.Upload.Controller.pas',
  Server.Arquivo.Consts in 'src\Server.Arquivo.Consts.pas',
  Server.Arquivo.Download.Controller in 'src\Server.Arquivo.Download.Controller.pas';

begin
  {$IFDEF MSWINDOWS}
  IsConsole := False;
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  THorse
    .Use(Jhonson)
    .Use(HandleException);

  TUploadController.Registry;
  TDownloadController.Registry;

  THorse.Listen(9000,
    procedure(Horse: THorse)
    begin
      Writeln(Format('Server is runing on %s:%d', [Horse.Host, Horse.Port]));
      Readln;
    end);

end.
