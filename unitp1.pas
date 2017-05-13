unit unitp1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, DBGrids,
  SQLite3, SQLiteTable3, DB, sqlite3conn, sqldb;

type

  { TfrmPersons }

  TfrmPersons = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmPersons: TfrmPersons;
  mybase: TSQLiteDatabase;

implementation

{$R *.lfm}

{ TfrmPersons }

procedure TfrmPersons.FormCreate(Sender: TObject);
begin
  mybase := TSQLiteDatabase.Create('persons.db');
  mybase.ExecSQL('PRAGMA key = "Yj z ,tlyzr b e vtyz kbim uhtps"');
end;

end.

