unit unitp1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, sqlite3conn, sqldb, Sqlite3DS, FileUtil, Forms,
  Controls, Graphics, Dialogs, DBGrids, StdCtrls, ExtCtrls, dynlibs, sqlite3dyn;

const
{$IFDEF WINDOWS}
  Sqlite3Lib = 'libsqlcipher-0.dll';
{$else}
  Sqlite3Lib = 'libsqlcipher.' + sharedsuffix;
{$endif}

type

  { TfrmPersons }

  TfrmPersons = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Image1: TImage;
    logMemo1: TMemo;
    Sqlite3Dataset1: TSqlite3Dataset;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmPersons: TfrmPersons;
  pass: string;
  f1: TFileStream;

implementation

{$R *.lfm}

{ TfrmPersons }

procedure TfrmPersons.FormCreate(Sender: TObject);
var
  id: int64;
begin
  {$IFDEF WINDOWS}
  sqlite3dyn.SQLiteDefaultLibrary := GetCurrentDir() + PathDelim + 'libsqlcipher-0.dll';
  {$else}
  // sqlite3dyn.SQLiteDefaultLibrary := GetCurrentDir() + PathDelim + 'libsqlite3.so';
  sqlite3dyn.SQLiteDefaultLibrary :=
    GetCurrentDir() + PathDelim + 'libsqlcipher.' + sharedsuffix;
  {$endif}
  sqlite3dyn.InitializeSqlite();
  logMemo1.Clear;
  logMemo1.Append(GetCurrentDir() + PathDelim + 'libsqlcipher.' + sharedsuffix);
  pass := PasswordBox('Пароль к базе данных', 'Введите пароль:');
  Sqlite3Dataset1.FileName := GetCurrentDir() + PathDelim + 'persons.db';
  if not FileExists(Sqlite3Dataset1.FileName) then
    ShowMessage('File not found');

  Sqlite3Dataset1.ExecSQL('PRAGMA key = "' + Trim(pass) + '";');
  logMemo1.Append('PRAGMA key="' + Trim(pass) + '";');

  if not Sqlite3Dataset1.TableExists('persons') then
    Sqlite3Dataset1.ExecSQL(
      'CREATE TABLE persons (id INTEGER PRIMARY KEY AUTOINCREMENT,firstname VARCHAR(30) NOT NULL, middlename VARCHAR (30) NOT NULL, secondname VARCHAR (50) NOT NULL, datebirth  DATE NOT NULL, dateappend DATETIME, prim TEXT);');
  if not Sqlite3Dataset1.TableExists('photo') then
    Sqlite3Dataset1.ExecSQL(
      'CREATE TABLE photo (idphoto INTEGER PRIMARY KEY AUTOINCREMENT, photo BLOB NOT NULL, datephoto  DATE, dateappend DATETIME NOT NULL, idperson REFERENCES persons (id));');

  Sqlite3Dataset1.TableName := 'persons';
  Sqlite3Dataset1.Active := True;
  {
  id := Sqlite3Dataset1.LastInsertRowId + 1;
  begin
    f1 := TFileStream.Create(GetCurrentDir() + PathDelim + '74a4eb79.jpg', fmOpenRead);
    Sqlite3Dataset1.UpdateBlob('UPDATE photo SET photo = ? WHERE idpersons = ' +
      IntToStr(id), f1);
    f1.Free;
  end;
  mytable := Sqlite3Dataset1.GetTable('SELECT * FROM persons where id=' +
    IntToStr(id));
  ms := TMemoryStream.Create;
  sql := 'SELECT photo FROM photo WHERE ID=' + IntToStr(id);
  if Sqlite3Dataset1.GetTable(sql).FieldAsString(0) <> '' then
  begin
    ms := Sqlite3Dataset1.GetTable(sql).FieldAsBlob(0);
    ms.Position := 0;
    (frmPersons.Image1 as Timage).Picture.Bitmap.LoadFromStream(ms);
    ms.Free;
  end;
  }
end;

procedure TfrmPersons.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Sqlite3Dataset1.Close;
  Sqlite3Dataset1.Free;
end;

end.
