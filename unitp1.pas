unit unitp1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Sqlite3DS, DB, FileUtil, Forms, Controls, Graphics,
  Dialogs, DBGrids, StdCtrls;

type

  { TfrmPersons }

  TfrmPersons = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
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

implementation

{$R *.lfm}

{ TfrmPersons }

procedure TfrmPersons.FormCreate(Sender: TObject);
begin
  logMemo1.Clear;
  pass := PasswordBox('Пароль к базе данных', 'Введите пароль:');
  Sqlite3Dataset1.FileName := GetCurrentDir() + PathDelim + 'persons.db';
  if not FileExists(Sqlite3Dataset1.FileName) then
    ShowMessage('File not found');
  Sqlite3Dataset1.TableName := 'persons';
  Sqlite3Dataset1.ExecuteDirect('PRAGMA key = "' + pass + '"; pragma kdf_iter=64000;');
  Sqlite3Dataset1.Active := True;
end;

procedure TfrmPersons.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Sqlite3Dataset1.Close;
end;

end.

