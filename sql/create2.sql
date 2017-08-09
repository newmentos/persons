CREATE TABLE person (
    id         INTEGER      PRIMARY KEY AUTOINCREMENT
                            UNIQUE
                            NOT NULL,
    family     VARCHAR (50),
    name       VARCHAR (50),
    middlename VARCHAR (50),
    dbirth     DATE,
    photo      BLOB,
    dateappend DATETIME,
    prim       TEXT
);
