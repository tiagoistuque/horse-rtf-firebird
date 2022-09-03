object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 150
  Width = 215
  object FDConnection1: TFDConnection
    Params.Strings = (
      
        'Database=D:\Users\Tiago\Documents\Embarcadero\Studio\Projects\Te' +
        'stFileRTF\db\db.fdb'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Protocol=TCPIP'
      'Server=localhost'
      'Port=3053'
      'OpenMode=OpenOrCreate'
      'CharacterSet=WIN1252'
      'DriverID=FB')
    Connected = True
    LoginPrompt = False
    Left = 72
    Top = 24
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'CREATE TABLE UPLOADS('
      'FILE BLOB SUB_TYPE 0,'
      'FILE_NAME VARCHAR(260),'
      'UPLOAD_METHOD VARCHAR(30)'
      ');')
    Left = 72
    Top = 80
  end
end
