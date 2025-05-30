# 🔥 CPU Stress Test Suite für Raspberry Pi & Linux

Dieses Repository enthält drei Bash-Skripte zur Durchführung von CPU-Stresstests mit Logging, Visualisierung und optionaler Benachrichtigung per [ntfy.sh](https://ntfy.sh).

---

## 📦 Voraussetzungen

Installiere die folgenden Pakete (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install stress-ng gnuplot imagemagick curl
```
- stress-ng: Für den CPU-Stresstest
- gnuplot: Für die Erstellung von Diagrammen (PNG)
- imagemagick: Für optionale PDF-Erstellung aus PNG
- curl: Für die Benachrichtigung via ntfy

## 📂 Enthaltene Skripte

| Skriptname                | Beschreibung                                         | ntfy Benachrichtigung | PDF Erstellung | Kommentar                      |
| ------------------------- | ---------------------------------------------------- | --------------------- | -------------- | ------------------------------ |
| `cpu_stress_full_ntfy.sh` | Vollversion mit ntfy-Upload & optional PDF           | Ja                    | Ja             | Nutzt ntfy zum Upload          |
| `cpu_stress_local.sh`     | Lokale Ausführung ohne ntfy, aber mit optionalem PDF | Nein                  | Ja             | Nur lokale Ausgabe             |
| `cpu_stress_basic.sh`     | Minimalversion ohne ntfy und PDF                     | Nein                  | Nein           | Nur CSV & PNG lokal, keine PDF |


## 🚀 Nutzung

```bash
chmod +x cpu_stress_full_ntfy.sh cpu_stress_local.sh cpu_stress_basic.sh
```

## Beispiele für die Skript-Ausführung:
** Vollversion mit ntfy-Benachrichtigung und PDF-Ausgabe: **
```bash
./cpu_stress_full_ntfy.sh --timeout=15 --cooldown=5 --pdf
```
Startet einen 15-minütigen Stresstest, 5 Minuten Abkühlung, erzeugt PDF und sendet Ergebnisse an ntfy-Server.

** Lokale Ausführung mit PDF (kein ntfy): **
```bash
./cpu_stress_local.sh --timeout=10 --cooldown=3 --pdf
```
Stresstest 10 Minuten, 3 Minuten Abkühlung, PDF wird erstellt, alles lokal gespeichert.


** Minimalversion ohne PDF und ntfy: **

```bash
./cpu_stress_basic.sh --timeout=12 --cooldown=4
```
Nur CPU-Stresstest für 12 Minuten plus 4 Minuten Abkühlung, Ausgabe als CSV und PNG lokal.

** Hilfe anzeigen:  (alle Skripte gleich)**

```bash
./cpu_stress_full_ntfy.sh --help
```

## ⚙️ Skript-Parameter


| Parameter              | Beschreibung                     |
| ---------------------- | -------------------------------- |
| `--timeout=<Minuten>`  | Dauer des CPU-Stresstests        |
| `--cooldown=<Minuten>` | Dauer der Abkühlphase danach     |
| `--pdf`                | PDF-Bericht erstellen (optional) |
| `--help`               | Hilfe und Parameter anzeigen     |

## 📋 Funktionsweise
- Das Skript misst CPU-Temperatur, Frequenz und Auslastung während eines Stresstests.
- Daten werden in eine CSV-Datei geloggt.
- Aus den Daten wird ein Diagramm (PNG) erstellt.
- Optional wird aus dem PNG ein PDF-Bericht generiert.
- Bei der Vollversion werden die Dateien und eine Benachrichtigung per ntfy verschickt.

## 🔒 Sicherheit
Achte darauf, deinen echten ntfy Token und Topic in cpu_stress_full_ntfy.sh einzutragen.
Token niemals öffentlich im Internet freigeben!
