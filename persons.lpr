program Persons;

{$mode objfpc}{$H+}

uses
  cmem,
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, unitp1, SQLite3, SQLiteTable3;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfrmPersons, frmPersons);
  Application.Run;
end.
