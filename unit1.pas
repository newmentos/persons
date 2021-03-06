unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, sqldblib, sqldb, DB, typinfo, FileUtil, Forms,
  Controls, Graphics, Dialogs, DBGrids, DBCtrls, ExtDlgs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, sqlite3backup, sqlite3conn, AbUnzper, AbZipper,
  AbBrowse, AbZBrows, AbUtils, AbZipTyp, AbArcTyp,
  fpspreadsheet, fpsexport, fpsTypes;

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
    FPSExport1: TFPSExport;
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
    procedure btnExportDataClick(Sender: TObject);
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
    procedure miExportDataClick(Sender: TObject);
    procedure miRecoveryFromBackupDbClick(Sender: TObject);
    procedure miVacuumDbClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure CloseDb;
    procedure InitDb;
    procedure VacuumDb;
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  OUTPUT_FORMAT = sfExcel8;
  {
   sfExcel2, sfExcel5, sfExcel8, sfExcelXML, sfOOXML, sfOpenDocument, sfCSV,
   sfHTML, sfWikiTable_Pipes, sfWikiTable_WikiMedia, sfUser
  }

  sqldrop: string = 'DROP TABLE person;';
  sqlcreate: string = 'CREATE TABLE person (' +
    'id         INTEGER      PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,' +
    'family     VARCHAR (50),                                          ' +
    'name       VARCHAR (50),                                          ' +
    'middlename VARCHAR (50),                                          ' +
    'dbirth     DATE,                                                  ' +
    'photo      BLOB,                                                  ' +
    'dateappend DATETIME,                                              ' +
    'prim       TEXT);';

var
  fMain: TfMain;
  databasefile: string;
  passdatabase: string;
  CurDir: string;

implementation

procedure TfMain.VacuumDb;
begin
  CloseDb;
  SQLIte3Connection1.ExecuteDirect('End Transaction');
  SQLIte3Connection1.ExecuteDirect('VACUUM');
  SQLIte3Connection1.ExecuteDirect('Begin Transaction');
  InitDb;
  SQLQuery1.Open;
end;

procedure TfMain.CloseDb;
begin
  SQLTransaction1.CloseDataSets;
  SQLQuery1.Active := False;
  SQLQuery1.Close;
  //  SQLite3Connection1.CloseTransactions;
  SQLTransaction1.Active := False;
end;

procedure TfMain.InitDb;
begin
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
var
  enabletables: boolean;
begin
  CurDir := ExtractFilePath(Application.ExeName);
  {$IFDEF WINDOWS}
  SQLDBLibraryLoader1.LibraryName :=
    CurDir + 'sqlite3.dll';
  {$else}
  SQLDBLibraryLoader1.LibraryName :=
    CurDir + 'libsqlite3.so';
  {$endif}
  SQLDBLibraryLoader1.ConnectionType := 'SQLite3';
  SQLDBLibraryLoader1.LoadLibrary;
  SQLDBLibraryLoader1.Enabled := True;
  // указываем путь к базе
  databasefile := CurDir + 'database.db';
  enabletables := True;
  if not FileExists(databasefile) then
    enabletables := False;
  SQLite3Connection1.DatabaseName := databasefile;
  // указываем рабочую кодировку
  SQLite3Connection1.CharSet := 'UTF8';
  SQLite3Connection1.Transaction := SQLTransaction1;
  SQLTransaction1.DataBase := SQLite3Connection1;
  SQLQuery1.DataBase := SQLite3Connection1;
  InitDb;
  if not enabletables then
    SQLIte3Connection1.ExecuteDirect(sqlcreate);
  SQLQuery1.SQL.Text := 'select * from "person"';
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
  pass1 := PasswordBox('Пароль базы данных', 'Введите новый пароль:');
  pass2 := PasswordBox('Пароль базы данных', 'Введите новый пароль еще раз:');
  if pass1 = pass2 then
  begin
    CloseDb;
    SQLIte3Connection1.ExecuteDirect('PRAGMA rekey=' + QuotedStr(pass2) + ';');
    ShowMessage('Пароль успешно изменен!');
    InitDb;
    SQLQuery1.Open;
  end;
end;

procedure TfMain.miCreateBackupDbClick(Sender: TObject);
var
  dumpfile, zipfile: string;
  BK: TSQLite3Backup;
  zip: TAbZipper;
begin
  // Сжимаем базу перед созданием дампа
  VacuumDb;
  // Создаем дамп базы данных
  dumpfile := 'database-' + FormatDateTime('yyyy.mm.dd hh-nn-ss', Now) + '.dmp';
  zipfile := CurDir + 'backup' + PathDelim + 'database-' +
    FormatDateTime('yyyy.mm.dd hh-nn-ss', Now) + '.zip';
  BK := TSQLite3Backup.Create;
  try
    BK.Backup(SQLite3Connection1, dumpfile);
    // Упаковываем в архив с паролем
    zip := TAbZipper.Create(Application);
    zip.ArchiveType := atZip;
    zip.FileName := zipfile;
    zip.AddFiles(dumpfile, 1);
    zip.ZipfileComment := 'Дамп базы данных от ' + FormatDateTime(
      'yyyy.mm.dd hh-nn-ss', Now);
    zip.CompressionMethodToUse := smBestMethod;
    zip.DeflationOption := doMaximum;
    Zip.Password := passdatabase;
    zip.Save;
    zip.CloseArchive;
    // Удаляем дамп
    DeleteFile(dumpfile);
    ShowMessage('Создан файл резервной копии ' + zipfile);
  finally
    zip.Free;
    BK.Free;
  end;
  SQLQuery1.Open;
end;

procedure TfMain.miCreateDbClick(Sender: TObject);
begin
  CloseDb;
  // Пересоздаем БД
  SQLIte3Connection1.ExecuteDirect(sqldrop);
  SQLIte3Connection1.ExecuteDirect(sqlcreate);
  InitDb;
  SQLQuery1.Open;
end;

procedure TfMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.miExportDataClick(Sender: TObject);
begin
  // Экспорт данных в файл
  // уже реализовано кнопкой
  btnExportDataClick(self);
end;

procedure TfMain.miRecoveryFromBackupDbClick(Sender: TObject);
var
  zipfile, dumpfile: string;
  UnZip: TAbUnZipper;
  BK: TSQLite3Backup;
begin
  OpenDialog1.Title := 'Открыть файл дампа';
  OpenDialog1.InitialDir := CurDir + PathDelim + 'backup';
  OpenDialog1.Filter := 'Zip file|*.zip';
  OpenDialog1.DefaultExt := 'zip';
  if OpenDialog1.Execute then
  begin
    // Выбираем архивный файл с дампом
    zipfile := OpenDialog1.Filename;
    dumpfile := ChangeFileExt(zipfile, '.dmp');
    // Распаковываем файл с дампом
    UnZip := TAbUnZipper.Create(nil);
    UnZip.BaseDirectory := CurDir + 'backup';
    UnZip.ExtractOptions := [eoCreateDirs, eoRestorePath];
    UnZip.FileName := zipfile;
    UnZip.Password := passdatabase;
    try
      UnZip.ExtractFiles('*.dmp');
      // Восстанавливаем БД
      if FileExists(dumpfile) then
      begin
        BK := TSQLite3Backup.Create;
        try
          CloseDb;
          BK.Restore(dumpfile, SQLite3Connection1);
          InitDb;
          SQLQuery1.Open;
          ShowMessage('База успешно восстановлена из файла ' + dumpfile);
        finally
          BK.Free
        end;
        DeleteFile(dumpfile);
      end
      else
        ShowMessage('Файл ' + dumpfile + ' не распаковался');
    finally
      UnZip.Free;
    end;
  end;
end;

procedure TfMain.miVacuumDbClick(Sender: TObject);
begin
  VacuumDb;
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
  OpenPictureDialog1.InitialDir := CurDir;
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
  OpenDialog1.InitialDir := CurDir;
  OpenDialog1.Filter := 'Excel file|*.xls';
  OpenDialog1.DefaultExt := 'xls';
  if OpenDialog1.Execute then
  begin
    xlsfile := OpenDialog1.Filename;
    ShowMessage('Выбран файл ' + xlsfile);
  end;
end;

procedure TfMain.btnExportDataClick(Sender: TObject);
var
  exportxlsfile, tmpjpgfile: string;
  ExpWorkbook: TsWorkbook;
  ExpWorksheet: TsWorksheet;
  i: integer;
  j: longint;
  ftype: TFieldType;
  ms: TStream;
  JPEGImage: TJPEGImage;
  {
  Exp: TFPSExport;
  ExpSettings: TFPSExportFormatSettings;
  }
begin
  // Экспорт данных в файл
  if SQLQuery1.RecordCount > 0 then
  begin
    SaveDialog1.Title := 'Экспорт данных в файл';
    SaveDialog1.InitialDir := CurDir;
    SaveDialog1.Filter := 'Excel file|*.xls';
    SaveDialog1.DefaultExt := 'xls';
    SaveDialog1.FileName := CurDir + FormatDateTime('yyyy.mm.dd hh-nn-ss',
      Now) + '.xls';
    if SaveDialog1.Execute then
    begin
      exportxlsfile := SaveDialog1.FileName;
      SQLQuery1.First;
      {
      Exp := TFPSExport.Create(nil);
      ExpSettings := TFPSExportFormatSettings.Create(True);
      try
        ExpSettings.ExportFormat := efXLSX; // efXLS efODS efXLSX choose file format
        ExpSettings.HeaderRow := True; // include header row with field names
        Exp.FormatSettings := ExpSettings; // apply settings to export object
        Exp.Dataset := SQLQuery1; // specify source
        Exp.FileName := exportxlsfile;
        Exp.Execute; // run the export
      finally
        Exp.Free;
        ExpSettings.Free;
      end;
      }
      ms := nil;
      ExpWorkbook := TsWorkbook.Create;
      ExpWorksheet := ExpWorkbook.AddWorksheet('export');
      ExpWorkbook.Options := [boFileStream];
      // Перебираем столбцы БД для имен столбцов
      for i := 0 to SQLQuery1.FieldCount - 1 do
      begin
        ExpWorksheet.WriteCellValueAsString(0, i,
          SQLQuery1.Fields[i].FieldName + ' (' +
          Fieldtypenames[SQLQuery1.Fields.Fields[i].DataType] + ')');
      end;
      // Перебираем строки БД для вывода строк
      for j := 0 to SQLQuery1.RecordCount - 1 do
      begin
        for i := 0 to SQLQuery1.FieldCount - 1 do
        begin
          // Определяем тип поля
          ftype := SQLQuery1.Fields[i].DataType;
          if ftype = ftBlob then
            // Если тип поля BLOB
          begin
            // Проверяем есть ли изображение в ячейке
            if not SQLQuery1.FieldByName('photo').IsNull then
            begin
              try
                JPEGImage := TJPEGImage.Create;
                ms := SQLQuery1.CreateBlobStream(SQLQuery1.FieldByName('photo'), bmRead);
                ms.Position := 0;
                JPEGImage.LoadFromStream(ms);
                tmpjpgfile := CurDir + IntToStr(j) + '.jpg';
                // Сохраняем изображение во временный файл
                JPEGImage.SaveToFile(tmpjpgfile);
                // Загружаем из временного файла изображение в таблицу
                //                ExpWorksheet.WriteImage(j + 1, i, tmpjpgfile);
              finally
                JPEGImage.Free;
                ms.Free;
                if FileExists(tmpjpgfile) then
                  DeleteFile(tmpjpgfile);
              end;
            end;
          end
          else
            // Если тип поля НЕ BLOB
            ExpWorksheet.WriteCellValueAsString(j + 1, i, SQLQuery1.Fields[i].AsString);
        end;
        SQLQuery1.Next;
      end;
      // Записываем все в файл
      ExpWorkbook.WriteToFile(exportxlsfile, OUTPUT_FORMAT);
      ExpWorkbook.Free;
    end;
    ShowMessage('Файл ' + exportxlsfile + ' сохранен.');
    SQLQuery1.First;
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
    SavePictureDialog1.InitialDir := CurDir;
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
