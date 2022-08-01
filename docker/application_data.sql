CREATE DATABASE app
    ENCODING UTF8
    TEMPLATE template0;
\c app
CREATE TABLE films (
    id          integer,
    title       varchar(40) NOT NULL
);
INSERT INTO films VALUES
    ('1', 'Pandas');
INSERT INTO films VALUES
    ('2', 'Cats');
INSERT INTO films VALUES
    ('3', 'Parrots');
INSERT INTO films VALUES
    ('4', 'Dogs');
INSERT INTO films VALUES
    ('5', 'Bears');
INSERT INTO films VALUES
    ('6', 'Terminator');
INSERT INTO films VALUES
    ('7', '39 Sisa Talk');
INSERT INTO films VALUES
    ('8', 'reaskills');
INSERT INTO films VALUES
    ('9', 'atomskills');
INSERT INTO films VALUES
    ('10', 'WSHT');