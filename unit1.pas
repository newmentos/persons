unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, sqldblib, sqldb, DB, sqlite3conn, FileUtil, Forms,
  Controls, Graphics, Dialogs, DBGrids, DBCtrls, ExtDlgs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, sqlite3backup;

{ TfMain }

type
  TfMain = class(TForm)
    btnExportData: TButton;
    btnLoadPhoto: TButton;
    btnImportData: TButton;
    btnSavePhoto: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBImage1: TDBImage;
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    MainMenu1: TMainMenu;
    miImportData: TMenuItem;
    miExportData: TMenuItem;
    miLine: TMenuItem;
    miData: TMenuItem;
    miRecoveryFromBackupDb: TMenuItem;
    miCreateBackupDb: TMenuItem;
    miVacuumDb: TMenuItem;
    miCreateDb: TMenuItem;
    miDB: TMenuItem;
    miAbout: TMenuItem;
    miExit: TMenuItem;
    miChangePass: TMenuItem;
    OpenDialog1: TOpenDialog;
    OpenPictureDialog1: TOpenPictureDialog;
    SaveDialog1: TSaveDialog;
    SavePictureDialog1: TSavePictureDialog;
    SQLDBLibraryLoader1: TSQLDBLibraryLoader;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure btnImportDataClick(Sender: TObject);
    procedure btnLoadPhotoClick(Sender: TObject);
    procedure btnSavePhotoClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure miChangePassClick(Sender: TObject);
    procedure miCreateBackupDbClick(Sender: TObject);
    procedure miCreateDbClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miRecoveryFromBackupDbClick(Sender: TObject);
    procedure miVacuumDbClick(Sender: TObject);
    procedure SaveDialog1Close(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure CloseDb;
    procedure InitDb;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMain: TfMain;
  databasefile: string;
  passdatabase: string;

implementation

procedure TfMain.CloseDb;
begin
  SQLTransaction1.CloseDataSets;
  SQLQuery1.Active := False;
  SQLQuery1.Close;
  SQLite3Connection1.CloseTransactions;
  SQLTransaction1.Active := False;
end;

procedure TfMain.InitDb;
begin
  // указываем путь к базе
  databasefile := ExtractFilePath(Application.ExeName) + 'database.db';
  SQLite3Connection1.DatabaseName := databasefile;
  // указываем рабочую кодировку
  SQLite3Connection1.CharSet := 'UTF8';
  try  // пробуем подключится к базе
    SQLIte3Connection1.Open;
    SQLTransaction1.Active := True;
    SQLIte3Connection1.Connected := True;
  except   // если не удалось то выводим сообщение о ошибке
    ShowMessage('Ошибка подключения к базе!');
  end;
  passdatabase := PasswordBox('Пароль базы данных',
    'Для входа введите Ваш текущий пароль:');
  SQLIte3Connection1.ExecuteDirect('PRAGMA key=' + QuotedStr(passdatabase) + ';');
end;

{$R *.lfm}

{ TfMain }

procedure TfMain.FormCreate(Sender: TObject);
begin
  {$IF Defined(MSWINDOWS)}
  SQLDBLibraryLoader1.LibraryName :=
    ExtractFilePath(Application.ExeName) + 'sqlite3.dll';
  {$ELSEIF Defined(UNIX)}
  SQLDBLibraryLoader1.LibraryName :=
    ExtractFilePath(Application.ExeName) + 'libwxsqlite3.so';
  {$IFEND}
  SQLDBLibraryLoader1.ConnectionType := 'SQLite3';
  SQLDBLibraryLoader1.LoadLibrary;
  SQLDBLibraryLoader1.Enabled := True;
  SQLQuery1.SQL.Text := 'select * from "person"';
  InitDb;
  SQLQuery1.Open;
end;

procedure TfMain.miAboutClick(Sender: TObject);
begin
  ShowMessage('Страница проекта' + #13#10 +
    'https://github.com/newmentos/persons.git');
end;

procedure TfMain.miChangePassClick(Sender: TObject);
var
  pass1, pass2: string;
begin
  InitDb;
  SQLQuery1.Open;
  pass1 := PasswordBox('Пароль базы данных',
    'Введите новый пароль:');
  pass2 := PasswordBox('Пароль базы данных',
    'Введите новый пароль еще раз:');
  if pass1 = pass2 then
  begin
    CloseDb;
    SQLIte3Connection1.ExecuteDirect('PRAGMA rekey=' + QuotedStr(pass2) + ';');
    InitDb;
    SQLQuery1.Open;
  end;
end;

procedure TfMain.miCreateBackupDbClick(Sender: TObject);
var
  f: string;
  BK: TSQLite3Backup;
begin
  f :=  ExtractFilePath(Application.ExeName)+'backup'+ PathDelim+ 'database-' + FormatDateTime('yyyy.mm.dd hh-nn-ss', Now) + '.dmp';
  BK := TSQLite3Backup.Create;
  BK.Backup(SQLite3Connection1, f);
  BK.Free;
end;

procedure TfMain.miCreateDbClick(Sender: TObject);
var
  sqlcreate: string;
begin
  CloseDb;
  if FileExists(databasefile) then
    DeleteFile(databasefile);
  sqlcreate := 'CREATE TABLE person (' +
    'id         INTEGER      PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,' +
    'family     VARCHAR (50),                                          ' +
    'name       VARCHAR (50),                                          ' +
    'middlename VARCHAR (50),                                          ' +
    'dbirth     DATE,                                                  ' +
    'photo      BLOB,                                                  ' +
    'dateappend DATETIME,                                              ' +
    'prim       TEXT);';
  SQLIte3Connection1.ExecuteDirect(sqlcreate);
  InitDb;
end;

procedure TfMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.miRecoveryFromBackupDbClick(Sender: TObject);
begin
  {
  TSQLite3Backup.Restore(FileName: string;Destination: TSQLite3Connection; LockUntilFinished: boolean;
  DestinationDBName: string): boolean;
  }
  //  SQLite3Connection1.Restore;
end;

procedure TfMain.miVacuumDbClick(Sender: TObject);
begin
  CloseDb;
  SQLIte3Connection1.ExecuteDirect('End Transaction');
  SQLIte3Connection1.ExecuteDirect('VACUUM');
  SQLIte3Connection1.ExecuteDirect('Begin Transaction');
  InitDb;
  SQLQuery1.Open;
end;

procedure TfMain.SaveDialog1Close(Sender: TObject);
begin
  if not SQLQuery1.RecordCount > 0 then
  begin
    SaveDialog1.Title := 'Экспорт данных в файл';
    SaveDialog1.InitialDir := GetCurrentDir;
    SaveDialog1.Filter := 'Excel file|*.xls';
    SaveDialog1.DefaultExt := 'xls';
    if SaveDialog1.Execute then
    begin

    end;
  end;
end;


procedure TfMain.Timer1Timer(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := DateToStr(now);
  StatusBar1.Panels[1].Text := TimeToStr(now);
  StatusBar1.Panels[2].Text :=
    'Всего записей:' + IntToStr(SQLQuery1.RecordCount);
end;

procedure TfMain.FormClose(Sender: TObject);
begin
  CloseDb;
  SQLite3Connection1.Connected := False;
  SQLite3Connection1.Close(True);
  SQLTransaction1.Free;
  SQLite3Connection1.Free;
  SQLDBLibraryLoader1.UnloadLibrary;
  SQLDBLibraryLoader1.Enabled := False;
  SQLDBLibraryLoader1.Free;
  OpenPictureDialog1.Free;
  SavePictureDialog1.Free;
  OpenDialog1.Free;
  SaveDialog1.Free;
end;

procedure TfMain.btnLoadPhotoClick(Sender: TObject);
var
  pictfilename: string;
  f1: TFileStream;
  bst: TStream;
begin
  OpenPictureDialog1.Title := 'Открыть файл с фото';
  OpenPictureDialog1.InitialDir := GetCurrentDir;
  OpenPictureDialog1.Filter := 'Jpeg file|*.jpg';
  OpenPictureDialog1.DefaultExt := 'jpg';
  if OpenPictureDialog1.Execute then
  begin
    if SQLQuery1.State <> dsEdit then
      SQLQuery1.Edit;
    pictfilename := OpenPictureDialog1.Filename;
    try
      f1 := TFileStream.Create(pictfilename, fmOpenRead);
      try
        try
          bst := SQLQuery1.CreateBlobStream(SQLQuery1.FieldByName('photo'), bmWrite);
          bst.CopyFrom(f1, f1.Size);
        except   // если не удалось то выводим сообщение о ошибке
          ShowMessage('Ошибка загрузки фото!');
        end;
      finally
        bst.Free;
      end;
    finally
      f1.Free;
    end;
  end;
end;

procedure TfMain.btnImportDataClick(Sender: TObject);
var
  xlsfile: string;
begin
  OpenDialog1.Title := 'Открыть файл с данными';
  OpenDialog1.InitialDir := GetCurrentDir;
  OpenDialog1.Filter := 'Excel file|*.xls';
  OpenDialog1.DefaultExt := 'xls';
  if SQLQuery1.RecordCount > 0 then
  begin
    if OpenDialog1.Execute then
    begin
      xlsfile := OpenDialog1.Filename;
      ShowMessage('Выбран файл ' + xlsfile);
    end;
  end;
end;

procedure TfMain.btnSavePhotoClick(Sender: TObject);
var
  JPEGImage: TJPEGImage;
  ms: TStream;
begin
  ms := nil;
  if not SQLQuery1.FieldByName('photo').IsNull then
  begin
    SavePictureDialog1.Title := 'Сохранить фото в файл';
    SavePictureDialog1.InitialDir := GetCurrentDir;
    SavePictureDialog1.Filter := 'Jpeg file|*.jpg';
    SavePictureDialog1.DefaultExt := 'jpg';
    if SavePictureDialog1.Execute then
    begin
      try
        try
          JPEGImage := TJPEGImage.Create;
          ms := SQLQuery1.CreateBlobStream(SQLQuery1.FieldByName('photo'), bmRead);
          ms.Position := 0;
          JPEGImage.LoadFromStream(ms);
          JPEGImage.SaveToFile(SavePictureDialog1.Filename);
        except
          ShowMessage('Ошибка сохранения фото!');
        end;
      finally
        JPEGImage.Free;
        ms.Free;
      end;
    end;
  end;
end;

end.
