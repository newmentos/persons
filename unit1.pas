unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, sqldblib, sqldb, DB, sqlite3conn, FileUtil, Forms,
  Controls, Graphics, Dialogs, DBGrids, DBCtrls, ExtDlgs, StdCtrls, ExtCtrls,
  ComCtrls;

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
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

procedure TfMain.FormCreate(Sender: TObject);
begin
  SQLDBLibraryLoader1.LibraryName :=
    ExtractFilePath(Application.ExeName) + 'sqlite3.dll';
  SQLDBLibraryLoader1.ConnectionType := 'SQLite3';
  SQLDBLibraryLoader1.LoadLibrary;
  SQLDBLibraryLoader1.Enabled := True;

  // указываем путь к базе
  SQLite3Connection1.DatabaseName :=
    ExtractFilePath(Application.ExeName) + 'database.db';
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
  SQLQuery1.Open;

end;

procedure TfMain.Timer1Timer(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := TimeToStr(now);
  StatusBar1.Panels[1].Text := DateToStr(now);
  StatusBar1.Panels[2].Text := 'Всего записей:'+IntToStr(SQLQuery1.RecordCount);

end;

procedure TfMain.FormClose(Sender: TObject);
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
