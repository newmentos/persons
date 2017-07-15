unit unitp1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, LCLType,
  Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Menus, SQLiteTable3;

const
{$IF Defined(MSWINDOWS)}
  SQLiteDLL = 'libsqlcipher.dll';
{$ELSEIF Defined(DARWIN)}
  SQLiteDLL = 'libsqlcipher.dylib';
  {$linklib libsqlite3}
{$ELSEIF Defined(UNIX)}
  SQLiteDLL = 'libsqlcipher.so';
{$IFEND}

type

  { TfrmPersons }

  TfrmPersons = class(TForm)
    Image1: TImage;
    logMemo1: TMemo;
    MainMenu1: TMainMenu;
    MenuItemAbout: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemChangePassDb: TMenuItem;
    MenuItemDelDb: TMenuItem;
    MenuItemOpenDb: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemCreateDb: TMenuItem;
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemChangePassDbClick(Sender: TObject);
    procedure MenuItemCreateDbClick(Sender: TObject);
    procedure MenuItemDelDbClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemOpenDbClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmPersons: TfrmPersons;
  pass: string;
  f1: TFileStream;
  db: TSQLiteDatabase;
  sql: string;
  dbfile: string;

implementation

{$R *.lfm}

{ TfrmPersons }

procedure TfrmPersons.FormCreate(Sender: TObject);
begin
  logMemo1.Clear;
  db := nil;
  dbfile := GetCurrentDir() + PathDelim + 'persons.db';
  // Есть файл базы данных ?
  if not FileExists(dbfile) then
    if Application.MessageBox('Файл базы данных не найден. Создать пустую базу данных?',
      'Ошибка', MB_ICONQUESTION + MB_YESNO) = idYes then
      MenuItemCreateDbClick(self)
    else
      Exit();
end;

procedure TfrmPersons.MenuItemChangePassDbClick(Sender: TObject);
var
  pass1, pass2: string;
begin
  pass1 := PasswordBox('Пароль к базе данных', 'Введите новый пароль:');
  pass2 := PasswordBox('Пароль к базе данных', 'Введите новый пароль еще раз:');
  if pass1 = pass2 then
    DB.ModifyDbPassword(PAnsiChar(pass1));
end;

procedure TfrmPersons.MenuItemCreateDbClick(Sender: TObject);
begin
  // Удаляем файл если он есть
  if FileExists(dbfile) then
    DeleteFile(dbfile);
  // Справшиваем пароль
  // pass := PasswordBox('Пароль к базе данных', 'Введите пароль:');
  pass := '12345';
  // Подключение к базе данных, если файл базы данных не существует, будет создана автоматически
  db := TSQLiteDatabase.Create(dbfile, PAnsiChar(pass));
  DB.ExecSQL(
    'CREATE TABLE USER(ID integer PRIMARY KEY AUTOINCREMENT NOT NULL,USERNAME VARCHAR(50),HOMEPAGE VARCHAR(255))');
  DB.ExecSQL('DROP TABLE IF EXISTS persons;');
  DB.ExecSQL(
    'CREATE TABLE persons (id INTEGER PRIMARY KEY AUTOINCREMENT,firstname VARCHAR(30) NOT NULL, middlename VARCHAR (30) NOT NULL, secondname VARCHAR (50) NOT NULL, datebirth  DATE NOT NULL, dateappend DATETIME, prim TEXT);');
  DB.ExecSQL('DROP TABLE IF EXISTS photo;');
  DB.ExecSQL(
    'CREATE TABLE photo (idphoto INTEGER PRIMARY KEY AUTOINCREMENT, photo BLOB NOT NULL, datephoto  DATE, dateappend DATETIME NOT NULL, idperson REFERENCES persons (id));');
{
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

procedure TfrmPersons.MenuItemDelDbClick(Sender: TObject);
begin
  DB.Free;
  DeleteFile(dbfile);
end;


procedure TfrmPersons.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPersons.MenuItemOpenDbClick(Sender: TObject);
begin
  // pass := PasswordBox('Пароль к базе данных', 'Введите пароль:');
  pass := '12345';
  // Подключение к базе данных, если файл базы данных не существует, будет создана автоматически
  db := TSQLiteDatabase.Create(dbfile, PAnsiChar(pass));
end;

procedure TfrmPersons.FormClose(Sender: TObject);
begin
  DB.Free;
  // Удаляем файл БД
  DeleteFile(dbfile);
end;

end.
