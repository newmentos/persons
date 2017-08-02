unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, sqldblib, sqldb, DB, sqlite3conn, FileUtil, Forms,
  Controls, Graphics, Dialogs, DBGrids, DBCtrls, ExtDlgs, StdCtrls, ExtCtrls,
  ComCtrls, Menus;

{ TfMain }

type
  TfMain = class(TForm)
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
    OpenPictureDialog1: TOpenPictureDialog;
    SavePictureDialog1: TSavePictureDialog;
    SQLDBLibraryLoader1: TSQLDBLibraryLoader;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure btnLoadPhotoClick(Sender: TObject);
    procedure btnSavePhotoClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure miCreateDbClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miVacuumDbClick(Sender: TObject);
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

implementation

procedure TfMain.CloseDb;
begin
  SQLTransaction1.CloseDataSets;
  SQLQuery1.Active := False;
  SQLQuery1.Close;
  SQLite3Connection1.CloseTransactions;
  SQLTransaction1.Active := False;
  SQLite3Connection1.Connected := False;
  SQLite3Connection1.Close(True);

  SQLTransaction1.Free;
  SQLite3Connection1.Free;
end;

procedure TfMain.InitDb;
begin
  // указываем путь к базе
  databasefile := ExtractFilePath(Application.ExeName) + 'database.db';
  SQLite3Connection1.DatabaseName := databasefile;
  // указываем рабочую кодировку
  SQLite3Connection1.CharSet := 'UTF8';

  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'select * from "person"';

  try  // пробуем подключится к базе
    SQLIte3Connection1.Open;
    SQLTransaction1.Active := True;
    SQLIte3Connection1.Connected := True;
  except   // если не удалось то выводим сообщение о ошибке
    ShowMessage('Ошибка подключения к базе!');
  end;
  SQLIte3Connection1.ExecuteDirect('PRAGMA key=' + QuotedStr('12345') + ';');
  SQLTransaction1.Active := True;
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
  InitDb;
  SQLQuery1.Open;
end;

procedure TfMain.miAboutClick(Sender: TObject);
begin
  ShowMessage('Страница проекта' + #13 +
    'https://github.com/newmentos/persons.git');
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
    'dateappend DATETIME DEFAULT (datetime("now","localtime")),        ' +
    'prim       TEXT);';
  SQLIte3Connection1.ExecuteDirect(sqlcreate);
  InitDb;
end;

procedure TfMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.miVacuumDbClick(Sender: TObject);
begin
  CloseDb;
  SQLIte3Connection1.ExecuteDirect('VACUUM');
  InitDb;
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
  SQLDBLibraryLoader1.UnloadLibrary;
  SQLDBLibraryLoader1.Enabled := False;
  SQLDBLibraryLoader1.Free;
end;

procedure TfMain.btnLoadPhotoClick(Sender: TObject);
var
  pictfilename: string;
  f1: TFileStream;
  bst: TStream;
begin
  if OpenPictureDialog1.Execute then
  begin
    if SQLQuery1.State <> dsEdit then
      SQLQuery1.Edit;
    pictfilename := OpenPictureDialog1.Filename;
    try
      f1 := TFileStream.Create(pictfilename, fmOpenRead);
      try
        bst := SQLQuery1.CreateBlobStream(SQLQuery1.FieldByName('photo'), bmWrite);
        bst.CopyFrom(f1, f1.Size);
      finally
        bst.Free;
      end;
    finally
      f1.Free;
    end;
  end;
end;

procedure TfMain.btnSavePhotoClick(Sender: TObject);
var
  JPEGImage: TJPEGImage;
  ms: TStream;
begin
  if not SQLQuery1.FieldByName('photo').IsNull then
  begin
    if SavePictureDialog1.Execute then
    begin
      try
        JPEGImage := TJPEGImage.Create;
        ms := SQLQuery1.CreateBlobStream(SQLQuery1.FieldByName('photo'), bmRead);
        ms.Position := 0;
        JPEGImage.LoadFromStream(ms);
        JPEGImage.SaveToFile(SavePictureDialog1.Filename);
      finally
        JPEGImage.Free;
        ms.Free;
      end;
    end;
  end;
end;

end.
