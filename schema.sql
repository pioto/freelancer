-- Schema for the Freelancer project:

CREATE TABLE Addresses (
    addr_id integer PRIMARY KEY AUTOINCREMENT,
    addr1 varchar(250) NOT NULL,
    addr2 varchar(250),
    city varchar(100) NOT NULL,
    state varchar(25) NOT NULL,
    zip varchar(10) NOT NULL,
    country_code varchar(3)
);

CREATE TABLE Users (
        user_id integer PRIMARY KEY AUTOINCREMENT,
        first_name      varchar(30) NOT NULL,
        last_name       varchar(30) NOT NULL,
        phone           varchar(15) NOT NULL,
        password        varchar(10) NOT NULL,
        email           varchar(100) UNIQUE,
        biz_name        varchar(30),
        biz_desc        varchar(250),
        addr_id integer,

        FOREIGN KEY (addr_id) REFERENCES Addresses (addr_id)
            on delete CASCADE on update CASCADE
);

CREATE TABLE Customers (
    cust_id integer,
    user_id integer,
    first_name varchar(30) NOT NULL,
    last_name varchar(30) NOT NULL,
    cust_since date NOT NULL,
    email varchar(20) NOT NULL,
    phone varchar(30) NOT NULL,
    company varchar(250),
    addr_id integer,

    PRIMARY KEY (cust_id, user_id),
    FOREIGN KEY (user_id) REFERENCES Users (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (addr_id) REFERENCES Addresses (addr_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Services (
        serv_id                 integer PRIMARY KEY AUTOINCREMENT,
        serv_name               varchar(30) NOT NULL,
        serv_desc               varchar(100) NOT NULL,
        user_id                 integer,
        unit                    varchar(50) NOT NULL,
        price_perunit   decimal(10,4) NOT NULL,

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
