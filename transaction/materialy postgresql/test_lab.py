"""Ověření lab.sql dvěma nezávislými PostgreSQL spojeními.

Spuštění: python test_lab.py
Vyžaduje psycopg 3. Heslo lze zadat do souboru .env vedle tohoto skriptu,
uložit do pgpass.conf, nastavit v PGPASSWORD nebo zadat skrytě v terminálu.
Použije se databáze MOY001 na bayer.cs.vsb.cz. Test vytvoří a následně
odstraní vlastní jedinečné schéma; existující objekty nemění.
"""

from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
from getpass import getpass
from pathlib import Path
from time import monotonic
from uuid import uuid4

import psycopg
from psycopg import sql


LAB = Path(__file__).with_name("lab.sql")
ENV_FILE = Path(__file__).with_name(".env")
TEST_SCHEMA = f"labtest_{uuid4().hex}"
CONNECT = {
    "host": "bayer.cs.vsb.cz",
    "port": 5432,
    "dbname": "MOY001",
    "user": "MOY001",
    "connect_timeout": 10,
    "autocommit": True,
}


def block(start: str, end: str) -> str:
    """Vrátí příkazy z označené části skutečného studentského scénáře."""
    text = LAB.read_text(encoding="utf-8")
    start_index = text.index(start)
    end_index = text.index(end, start_index + len(start))
    lines = text[start_index:end_index].splitlines()
    return "\n".join(line for line in lines if not line.lstrip().startswith("--"))


def run(connection, commands: str):
    results = []
    commands = commands.replace("transakce_lab", TEST_SCHEMA)
    for statement in commands.split(";"):
        if statement.strip():
            with connection.cursor() as cursor:
                cursor.execute(statement)
                if cursor.description:
                    results.append(cursor.fetchall())
    return results


def step(connection, number: str, following: str):
    return run(connection, block(f"-- Krok {number}", f"-- Krok {following}"))


def expect(actual, expected, description):
    if actual != expected:
        raise AssertionError(f"{description}: očekáváno {expected!r}, získáno {actual!r}")


def setup(connection):
    return run(connection, block("-- Krok 0.2", "-- Krok 0.4"))


def reset(connection):
    run(connection, block("-- Krok 0.4", "-- 1. READ UNCOMMITTED"))


def validate(t1, t2):
    baseline = setup(t1)
    expect(baseline, [[(4, 6)]], "výchozí data")

    for section in ("1", "2"):
        step(t1, f"{section}.1", f"{section}.2")
        before = step(t2, f"{section}.2", f"{section}.3")
        expect(len(before[0]), 4, f"{section}: čtení nepotvrzených dat")
        step(t1, f"{section}.3", f"{section}.4")
        after = step(t2, f"{section}.2", f"{section}.3")
        expect(after, before, f"{section}: čtení po rollbacku")
        print(f"OK {section}: nepotvrzeny radek neni viditelny")

    expect(step(t1, "3.1", "3.2"), [[(6,)]], "3.1")
    step(t2, "3.2", "3.3")
    expect(step(t1, "3.3", "3.4"), [[(Decimal("14.8"),)]], "3.3")
    run(t1, block("-- Krok 3.4", "-- Otázka k zamyšlení"))
    print("OK 3: READ COMMITTED vidi zmenu v novem prikazu")

    reset(t1)
    expect(step(t1, "4.1", "4.2"), [[(6,)]], "4.1")
    step(t2, "4.2", "4.3")
    expect(step(t1, "4.3", "4.4"), [[(6,)]], "4.3")
    expect(
        run(t1, block("-- Krok 4.4", "-- 5. REPEATABLE READ")),
        [[(Decimal("253.5"),)]],
        "4.4",
    )
    print("OK 4: REPEATABLE READ zachovava puvodni snimek")

    reset(t1)
    first = step(t1, "5.1", "5.2")
    expect(first, [[("swa005", 10, 1)]], "5.1")
    step(t2, "5.2", "5.3")
    expect(step(t1, "5.3", "5.4"), first, "5.3")
    after = run(t1, block("-- Krok 5.4", "-- 6. EXPLICITNÍ"))
    expect(after, [[("lee020", 6, 10), ("swa005", 10, 1)]], "5.4")
    print("OK 5: novy radek je viditelny az po ukonceni transakce")

    reset(t1)
    expect(step(t1, "6.1", "6.2"), [[("nor001", 10)]], "6.1")
    expect(step(t2, "6.2", "6.3"), [[("nor001", 10)]], "6.2")
    t2_pid = t2.info.backend_pid
    with ThreadPoolExecutor(max_workers=1) as executor:
        waiting = executor.submit(step, t2, "6.3", "6.4")
        try:
            deadline = monotonic() + 10
            while True:
                if waiting.done():
                    raise AssertionError(f"6.3: příkaz nečekal: {waiting.result()!r}")
                blockers = t1.execute("SELECT pg_blocking_pids(%s)", (t2_pid,)).fetchone()[0]
                if t1.info.backend_pid in blockers:
                    break
                if monotonic() >= deadline:
                    raise TimeoutError("6.3: čekání na zámek nebylo potvrzeno")
            run(t1, block("-- Krok 6.4", "-- 7. SERIALIZABLE"))
            expect(waiting.result(timeout=10), [[("nor001", 10)]], "6.3 po uvolnění")
        finally:
            if t1.info.transaction_status != psycopg.pq.TransactionStatus.IDLE:
                t1.execute("ROLLBACK")
    print("OK 6: bezne cteni neceka, FOR UPDATE ceka a nasledne pokracuje")

    reset(t1)
    expect(step(t1, "7.1", "7.2"), [[(0,)]], "7.1")
    expect(step(t2, "7.2", "7.3"), [[(0,)]], "7.2")
    step(t1, "7.3", "7.4")
    try:
        run(t2, block("-- Krok 7.4", "-- Kontrola v nové transakci"))
    except psycopg.errors.SerializationFailure:
        t2.execute("ROLLBACK")
    else:
        raise AssertionError("7.4: očekávaná chyba serializace 40001 nenastala")
    expect(
        run(t1, block("-- Kontrola v nové transakci", "-- Krok 7.5")),
        [[("tx001 ", 42)]],
        "7: výsledek po chybě serializace",
    )
    expect(step(t2, "7.5", "7.6"), [[(1,)]], "7.5: opakované čtení")
    expect(
        run(t1, block("-- Krok 7.6", "-- 8. SHRNUTÍ")),
        [[("tx001 ", 42), ("tx002 ", 42)]],
        "7.6: výsledek po opakování transakce",
    )
    print("OK 7: konflikt vyvolal chybu serializace 40001")


def main():
    schema = TEST_SCHEMA
    password = None
    if ENV_FILE.exists():
        lines = [
            line for line in ENV_FILE.read_text(encoding="utf-8-sig").splitlines()
            if line and not line.lstrip().startswith("#")
        ]
        if len(lines) != 1 or not lines[0].startswith("PGPASSWORD="):
            raise ValueError("Soubor .env musí obsahovat jeden řádek PGPASSWORD=heslo.")
        password = lines[0].removeprefix("PGPASSWORD=") or None

    try:
        t1 = psycopg.connect(**CONNECT, password=password)
    except psycopg.OperationalError as error:
        if password is not None or "no password supplied" not in str(error):
            raise
        password = getpass("Heslo PostgreSQL (nezobrazuje se): ")
        t1 = psycopg.connect(**CONNECT, password=password)

    with t1:
        with psycopg.connect(**CONNECT, password=password) as t2:
            execute_test(t1, t2, schema)
    print("Docasne schema odstraneno.")


def execute_test(t1, t2, schema):
    t1.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
    try:
        for connection in (t1, t2):
            connection.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))
            connection.execute("SET statement_timeout = '15s'")
        validate(t1, t2)
    finally:
        for connection in (t1, t2):
            if connection.info.transaction_status != psycopg.pq.TransactionStatus.IDLE:
                connection.execute("ROLLBACK")
        t1.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))


if __name__ == "__main__":
    main()
