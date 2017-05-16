CREATE TABLE persons (
    id         INTEGER      PRIMARY KEY AUTOINCREMENT,
    firstname  VARCHAR (30) NOT NULL,
    middlename VARCHAR (30) NOT NULL,
    secondname VARCHAR (50) NOT NULL,
    datebirth  DATE         NOT NULL,
    dateappend DATETIME DEFAULT (datetime('now','localtime')),
    prim       TEXT
);
CREATE TABLE photo (
    idphoto    INTEGER PRIMARY KEY AUTOINCREMENT,
    photo      BLOB    NOT NULL,
    datephoto  DATE,
    dateappend DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
    idperson           REFERENCES persons (id) 
);

