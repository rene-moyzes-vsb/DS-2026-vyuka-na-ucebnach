# Read-only kontrola existence tabulky lego.uspresident ve vybranych databazich.
# Pouziti:  .\kontrola-uspresident.ps1 -Uzivatel admin
# Vyzaduje nainstalovany psql (PostgreSQL client) v PATH. Heslo se zepta jednou.
param(
    [Parameter(Mandatory = $true)][string]$Uzivatel,
    [string]$Server = 'bayer.cs.vsb.cz',
    [int]$Port = 5432,
    # Heslo se vezme z pgpass.conf misto dotazu
    [switch]$BezHesla
)

$databaze = @(
    'AXM0015','BAL0344','BIA0040','BLA0401','CAJ0038','CEC0184','CIA0014','CZE0047','DAN0229','DAU0020',
    'DIH0016','DRO0116','DUO0012','FIE0038','FIL0207','FIT0007','FOJ0149','FOL0195','FOL0196','GEN0024',
    'GRE0168','GRY0128','GUB0007','HAD0067','HAN0413','HAV0306','HNI0031','HOL0621','HOL0622','HOM0085',
    'HOR0640','HOR0642','IGN0009','IND0045','JAL0045','JAN0993','JAN1033','JAR0193','JEZ0086','KAL0324',
    'KAL0382','KAL0383','KAM0117','KAT0031','KLA0136','KNE0063','KNI0030','KOB0082','KOL0607','KON0530',
    'KOT0339','KOV0449','KOV0450','KOZ0394','KRA0775','KRC0099','KUB0813','KUC0456','LUK0202','LUZ0037',
    'MAY0031','MEL0097','MIK0598','MUK0014','MYL0012','NED0078','NGU0406','NIK0073','NOS0046','NOV0818',
    'OLE0063','OND0325','OTA0039','PER0228','PET0519','PET0520','PIN0110','POL0622','POT0077','PRO0419',
    'REH0153','RYB0136','SAV0037','SEI0103','SEN0091','SER0086','SCH0470','SCH0471','SCH0493','SKR0171',
    'SLA0399','SLA0400','SME0169','SPA0211','SRU0045','STU0210','STU0221','SZA0044','TOM0526','TVR0054',
    'VAC0312','VAL0555','VAN0393','VIL0103','ZAK0132','ZID0108','ZMI0010'
)

if (-not $BezHesla) {
    $heslo = Read-Host -Prompt "Heslo pro $Uzivatel" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($heslo))
}

$dotaz = "SELECT to_regclass('lego.uspresident') IS NOT NULL"
$vysledky = foreach ($db in $databaze) {
    # Spojeni je read-only i na urovni session
    $odpoved = psql -h $Server -p $Port -U $Uzivatel -d $db -w -t -A `
        -c "SET default_transaction_read_only = on; $dotaz" 2>&1 |
        Where-Object { $_ -ne 'SET' }
    $text = ($odpoved | Out-String).Trim()
    [pscustomobject]@{
        Databaze = $db
        Existuje = switch ($text) { 't' { 'ANO' } 'f' { 'ne' } default { "CHYBA: $text" } }
    }
}

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue

$vysledky | Where-Object Existuje -eq 'ANO' | Format-Table -AutoSize
"Celkem s tabulkou: $(@($vysledky | Where-Object Existuje -eq 'ANO').Count) z $($databaze.Count)"
$chyby = @($vysledky | Where-Object { $_.Existuje -like 'CHYBA*' })
if ($chyby.Count) { "Chyb pripojeni: $($chyby.Count)"; $chyby | Format-Table -AutoSize }
