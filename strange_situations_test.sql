CREATE SCHEMA IF NOT EXISTS lab3;
SET search_path = lab3, public;

CREATE TABLE IF NOT EXISTS tx_demo (
  id int PRIMARY KEY,
  val int NOT NULL
);

CREATE TABLE IF NOT EXISTS tx_phantom (
  id bigserial PRIMARY KEY,
  grp text NOT NULL
);

INSERT INTO tx_demo(id, val)
VALUES (1, 100)
ON CONFLICT (id) DO UPDATE SET val = excluded.val;

TRUNCATE tx_phantom;
INSERT INTO tx_phantom(grp)
SELECT 'open' FROM generate_series(1, 5);

-- 1
--t1
SET search_path = lab3, public;

UPDATE tx_demo SET val = 100 WHERE id = 1;

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT val AS t1_first_read
FROM tx_demo
WHERE id = 1;

SELECT pg_sleep(6);

SELECT val AS t1_second_read
FROM tx_demo
WHERE id = 1;

COMMIT;
--t2
SET search_path = lab3, public;

SELECT pg_sleep(2);

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE tx_demo
SET val = val + 10
WHERE id = 1;

COMMIT;
--new t1
SET search_path = lab3, public;

UPDATE tx_demo SET val = 100 WHERE id = 1;

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT val AS t1_first_read
FROM tx_demo
WHERE id = 1;

SELECT pg_sleep(6);

SELECT val AS t1_second_read
FROM tx_demo
WHERE id = 1;

COMMIT;
--2
--t1
SET search_path = lab3, public;

TRUNCATE tx_phantom;
INSERT INTO tx_phantom(grp)
SELECT 'open' FROM generate_series(1, 5);

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT count(*) AS t1_first_count
FROM tx_phantom
WHERE grp = 'open';

SELECT pg_sleep(6);

SELECT count(*) AS t1_second_count
FROM tx_phantom
WHERE grp = 'open';

COMMIT;
--t2
SET search_path = lab3, public;

SELECT pg_sleep(2);

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO tx_phantom(grp)
SELECT 'open' FROM generate_series(1, 3);

COMMIT;
--new t1
SET search_path = lab3, public;

TRUNCATE tx_phantom;
INSERT INTO tx_phantom(grp)
SELECT 'open' FROM generate_series(1, 5);

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT count(*) AS t1_first_count
FROM tx_phantom
WHERE grp = 'open';

SELECT pg_sleep(6);

SELECT count(*) AS t1_second_count
FROM tx_phantom
WHERE grp = 'open';

COMMIT;
--3
--t1
SET search_path = lab3, public;

UPDATE tx_demo SET val = 100 WHERE id = 1;

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

CREATE TEMP TABLE t1_read(val int) ON COMMIT DROP;
INSERT INTO t1_read(val)
SELECT val FROM tx_demo WHERE id = 1;

SELECT pg_sleep(6);

UPDATE tx_demo
SET val = (SELECT val FROM t1_read) + 10
WHERE id = 1;

COMMIT;

SELECT val AS final_after_t1 FROM tx_demo WHERE id = 1;
--t2
SET search_path = lab3, public;

SELECT pg_sleep(2);

BEGIN;
SET LOCAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

CREATE TEMP TABLE t2_read(val int) ON COMMIT DROP;
INSERT INTO t2_read(val)
SELECT val FROM tx_demo WHERE id = 1;

SELECT pg_sleep(2);

UPDATE tx_demo
SET val = (SELECT val FROM t2_read) + 20
WHERE id = 1;

COMMIT;

SELECT val AS final_after_t2 FROM tx_demo WHERE id = 1;
--new t1
BEGIN;

SELECT val
FROM tx_demo
WHERE id = 1
FOR UPDATE;

SELECT pg_sleep(8);

UPDATE tx_demo
SET val = val + 10
WHERE id = 1;

COMMIT;
