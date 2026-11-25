# Poznámky pro pedagoga: transakce v PostgreSQL

## Účel a materiály

Laboratoř vede studenty od viditelnosti nepotvrzených změn přes stabilní
snímek až k explicitním zámkům a serializaci. Je určena pro práci jednotlivě
nebo ve dvojicích; orientačně počítejte s 90 minutami podle zkušeností
studentů a prostoru pro diskusi.

- [Studentský návod](./laborator-transakce.md)
- [SQL scénář pro kopírování příkazů](./lab.sql)
- [Automatizovaný test scénáře](./test_lab.py) – pro vyučujícího, nikoli
  nutná součást práce studenta.

Příkazy scénáře byly ověřeny na PostgreSQL 18 ve dvou samostatných spojeních.
Klient může odlišně zobrazovat počet desetinných míst, odsazení `CHAR(6)`,
upozornění či okamžik, kdy po chybě zastaví provádění bloku.

## Příprava prostředí

1. Zajistěte testovací databázi, oprávnění `CREATE` pro vytvoření schématu
   a klienta, ve kterém lze otevřít dvě **nezávislá spojení** k téže databázi.
2. Přidělte každému studentovi nebo dvojici vlastní jméno schématu. Ve
   scénáři i návodu je výchozí `transakce_lab`; uživatel ho musí při použití
   jiného názvu změnit ve všech příkazech.
3. Vysvětlete, že `CREATE SCHEMA` má při existujícím schématu záměrně selhat.
   Studenti nesmí přebírat cizí schéma. Obnova používá `TRUNCATE`, který smaže
   všechny řádky v jejich cvičné tabulce.
4. Ověřte, že explicitně zahájená transakce zůstává mezi kroky otevřená.
   Zamezte situaci, kdy dvě okna sdílejí jedno spojení nebo klient průběžně
   potvrzuje transakci. Studentům doporučte označit si okna T1 a T2.
5. Před obnovou dat musí být dokončeny transakce v obou oknech.

## Doporučený průběh

| Fáze | Orientační čas | Postup |
|---|---:|---|
| Úvod a příprava | 15 min | Transakce, MVCC, dvě spojení, vlastní schéma. |
| Úlohy 1–3 | 20 min | Nepotvrzené změny a nový snímek v `READ COMMITTED`. |
| Úlohy 4–5 | 15 min | Stabilní snímek a phantom řádky. |
| Úloha 6 | 15 min | Zámek, čtení bez zámku a čekání. |
| Úloha 7 | 15 min | Konflikt serializace a nový pokus. |
| Shrnutí a úklid | 10 min | Diskuse, kontrolní otázky, odstranění vlastních objektů. |

Před každým pokusem chtějte po studentech **předpověď a zdůvodnění**.
Následně nechte zapsat pozorování a porovnat je s předpovědí. Nestačí, aby
student pouze přečetl očekávaný výsledek nebo postupně spustil bloky.

## Výsledky a výklad

### Úlohy 1 a 2: nepotvrzené změny

T1 vloží `lee040`, ale T2 před jeho potvrzením vidí pouze původní čtyři
řádky. Po `ROLLBACK` T1 je výsledek T2 stejný. PostgreSQL zpracovává
`READ UNCOMMITTED` stejně jako `READ COMMITTED`, a proto ani v úloze 1
nedojde ke špinavému čtení.

Upozorněte, že jde o dvě samostatné transakce T2, ne o srovnání dvou příkazů
v jedné transakci T2. Smyslem úloh je právě viditelnost nepotvrzeného vložení.

### Úloha 3: READ COMMITTED

T1 nejprve vypočítá `6.0`, po potvrzeném vložení v T2 pak `14.8`. Druhý
dotaz dostane nový snímek, ačkoliv T1 stále běží. Vložený řádek představuje
phantom v množině vstupující do agregace; oba výsledky vznikly z potvrzených
dat. Transakce navíc vidí i vlastní změny.

Ptejte se, zda by se výsledek změnil, kdyby T2 vložení místo potvrzení
zrušila. Očekávaná odpověď: nikoli v důsledku tohoto zrušeného vložení.

### Úlohy 4 a 5: REPEATABLE READ

V úloze 4 T1 dvakrát vidí `6.0`; po jejím ukončení nový dotaz vrátí `253.5`.
Snímek v PostgreSQL vzniká při prvním příkazu, který ho potřebuje, nikoli
automaticky samotným `BEGIN`. T1 přesto vidí i své vlastní následné změny.

V úloze 5 T1 před i po potvrzení T2 vidí pouze `swa005`. Nový dotaz po
ukončení T1 vidí také `lee020`. PostgreSQL `REPEATABLE READ` zabraňuje
phantomům v rámci snímku, ale **není obecně ekvivalentní `SERIALIZABLE`**:
stabilní snímek sám nevylučuje všechny anomálie souběžných zápisů.

### Úloha 6: explicitní zámek

T1 zamkne řádek `nor001` pomocí `FOR UPDATE`. Běžný `SELECT` v T2 řádek
přečte bez čekání; MVCC mu zpřístupní vhodnou viditelnou verzi. Následující
`SELECT ... FOR UPDATE` v T2 čeká, dokud T1 zámek neuvolní. Po `COMMIT` T1
se dokončí a následný `COMMIT` T2 uvolní i jeho zámek.

Otázka k diskusi: Co by změnil `ROLLBACK` T1? Také by uvolnil zámek; pokud by
T1 mezitím provedla změny, byly by navíc zrušeny. Obyčejné čtení není totéž
co získání zámku a `FOR UPDATE` nezamyká neexistující řádky odpovídající
podmínce.

### Úloha 7: SERIALIZABLE

Obě transakce přečtou počet `0`. T1 vloží `tx001` a potvrdí. Následný zápis
T2 je při daném rozvrhu odmítnut chybou serializace `40001`. Kdyby obě
původní transakce úspěšně skončily a obě přitom četly `0`, nebylo by možné
jejich pozorování vysvětlit žádným sériovým pořadím.

PostgreSQL používá **Serializable Snapshot Isolation (SSI)**: sleduje
závislosti mezi souběžnými transakcemi a některou může přerušit, aby zabránil
neserializovatelnému výsledku. Samotné jedno čtení a souběžný zápis ještě
automaticky neznamenají chybu serializace.

Před opakováním zůstává pouze `tx001`. T2 ukončí případnou neúspěšnou
transakci a zopakuje celé čtení i vložení. Tentokrát čte počet `1`, vložení
se může podařit a v tabulce jsou oba řádky. Při opakování musí aplikace
znovu vykonat i své rozhodování: kdyby například vložení záviselo na počtu
`0`, neměla by při novém výsledku `1` vkládat.

Vysvětlete rozdíl mezi chybou `40001`, kterou aplikace může řešit novým
pokusem o **celou transakci**, a libovolnou jinou chybou, kterou není správné
bez rozlišení opakovat.

## Typické potíže

- **Jiné výsledky než v návodu:** ověřte pořadí kroků, dokončení předchozích
  transakcí a obnovení dat příkazem v části 0. Zjistěte také, zda se obě okna
  připojují ke stejnému schématu ve stejné databázi.
- **T2 při `FOR UPDATE` nečeká:** T1 možná již provedla `COMMIT` nebo
  `ROLLBACK`, okna sdílejí relaci, anebo nebyl zamčen stejný řádek.
- **Klient zůstal čekat:** v úloze 6 je čekání T2 očekávané. Přepněte do T1
  a uvolněte zámek; nepouštějte reset dat, dokud transakce neskončí.
- **Příkaz neprojde po očekávané chybě:** transakce může být v chybovém
  stavu. Proveďte `ROLLBACK`; pokud již klient transakci ukončil, může pouze
  upozornit, že žádná neběží.
- **Schéma již existuje:** student musí zvolit jiné vlastní jméno nebo jinou
  testovací databázi; nesmí cizí schéma mazat ani používat.

## Kontrolní otázky a očekávané odpovědi

1. **Proč se v úloze 1 nepotvrzený řádek nezobrazil?**
   PostgreSQL provádí `READ UNCOMMITTED` jako `READ COMMITTED`.
2. **Proč se v úloze 3 změnil průměr, ale v úloze 4 ne?**
   První používá pro každý příkaz nový snímek, druhá stabilní snímek
   transakce.
3. **Proč běžný `SELECT` v úloze 6 nečeká?**
   Není konfliktním zámkem řádku a čte viditelnou verzi pomocí MVCC.
4. **Proč opakovat po `40001` celou transakci?**
   Předchozí čtení a rozhodnutí mohla vycházet ze snímku, který už pro nový
   pokus neplatí.

Na závěr studenti odstraní pouze svou cvičnou tabulku a vlastní prázdné
schéma podle návodu. Nepoužívejte úklid cizích objektů ani plošné mazání
v databázi.
