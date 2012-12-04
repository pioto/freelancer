-- Schema for the Freelancer project:

CREATE TABLE Users (
        user_id integer PRIMARY KEY AUTOINCREMENT,
        first_name      varchar(30) NOT NULL,
        last_name       varchar(30) NOT NULL,
        phone           varchar(15) NOT NULL,
        password        varchar(10) NOT NULL,
        email           varchar(100) UNIQUE,
        biz_name        varchar(30),
        biz_desc        varchar(250),
        address         varchar(100) NOT NULL
);


CREATE TABLE Customers (
        cust_id                 integer AUTOINCREMENT,
        first_name              varchar(30) NOT NULL,
        last_name               varchar(30) NOT NULL,
        user_id                 integer,
        cust_since              date NOT NULL,
        email                   varchar(20) NOT NULL,
        phone                   varchar(30) NOT NULL,
        street_address  varchar(250) NOT NULL,
        state                   char(15) NOT NULL,
        zip                             integer NOT NULL,
        company                 varchar(250),

        PRIMARY KEY (cust_id, user_id),
        FOREIGN KEY (user_id) REFERENCES Users
                on delete CASCADE on update CASCADE );

CREATE TABLE Services (
        serv_id                 integer AUTOINCREMENT,
        serv_name               varchar(30) NOT NULL,
        serv_desc               varchar(100) NOT NULL,
        user_id                 integer,
        unit                    varchar(50) NOT NULL,
        price_perunit   decimal(10,4) NOT NULL,

        PRIMARY KEY (serv_id, user_id),
        FOREIGN KEY (user_id) REFERENCES Users
                on delete CASCADE on update CASCADE  );

CREATE TABLE Given_Services (
        serv_id         integer,
        cust_id                 integer,
        date                    date NOT NULL,
        amount          integer NOT NULL,
        invoice_id              integer,

        CHECK (amount != 0),

        PRIMARY KEY (serv_id, cust_id, date),
        FOREIGN KEY (serv_id) REFERENCES Services
                on delete SET DEFAULT on update CASCADE,
        FOREIGN KEY (cust_id) REFERENCES Customers
                on delete SET DEFAULT on update CASCADE,
        FOREIGN KEY (invoice_id) REFERENCES Invoices
                on delete SET NULL on update CASCADE );

CREATE TABLE Invoices (
        invoice_id              integer AUTOINCREMENT,
        user_id                 integer,
        issue_date              date NOT NULL,
        due_date                date NOT NULL,
        status                  varchar(15) NOT NULL,

        PRIMARY KEY (invoice_id, user_id),
        FOREIGN KEY (user_id) REFERENCES Users
                on delete CASCADE on update CASCADE );

CREATE TABLE Payments (
        payment_num     integer AUTOINCREMENT,
        invoice_id              integer,
        pay_date                date NOT NULL,
        amount          decimal(10,4) NOT NULL,
        method          varchar(15) NOT NULL,

        PRIMARY KEY (payment_num, invoice_id),
        FOREIGN KEY (invoice_id) REFERENCES Invoices
                on delete SET DEFAULT on update CASCADE );
