# 🔥 CPU Stress Test Suite für Raspberry Pi & Linux

Es enthält drei Bash-Skripte zur Durchführung von CPU-Stresstests mit Logging, Visualisierung und optionaler Benachrichtigung per [ntfy.sh](https://ntfy.sh).

---

## 📦 Voraussetzungen (Siehe ## [Drittanbieter-Software](https://github.com/lastsamurai26/cpu-stress-suite?tab=readme-ov-file#drittanbieter-software) )

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

| Skriptname                | Beschreibung                                         | ntfy Benachrichtigung      | PDF Erstellung | Kommentar                      |
| ------------------------- | ---------------------------------------------------- | -------------------------- | -------------- | ------------------------------ |
| `cpu_stress_full_ntfy.sh` | Vollversion mit ntfy-Upload & optional PDF           | Ja (mit optionalen Upload) | Ja             | Nutzt ntfy zum Upload          |
| `cpu_stress_local.sh`     | Lokale Ausführung ohne ntfy, aber mit optionalem PDF | Nein                       | Ja             | Nur lokale Ausgabe             |
| `cpu_stress_basic.sh`     | Minimalversion ohne ntfy und PDF                     | Nein                       | Nein           | Nur CSV & PNG lokal, keine PDF |


## 🚀 Nutzung

```bash
chmod +x cpu_stress_full_ntfy.sh cpu_stress_local.sh cpu_stress_basic.sh
```

## Beispiele für die Skript-Ausführung:
** Vollversion mit ntfy-Benachrichtigung und PDF-Ausgabe: **
```bash
./cpu_stress_full_ntfy.sh --timeout=15 --cooldown=5 --pdf --upload
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


| Parameter              | Beschreibung                                      |
| ---------------------- | ------------------------------------------------- |
| `--prepare=<Minuten>`  | Dauer der Vorbereitungszeit                       |
| `--timeout=<Minuten>`  | Dauer des CPU-Stresstests                         |
| `--cooldown=<Minuten>` | Dauer der Abkühlphase danach                      |
| `--pdf`                | PDF-Bericht erstellen (optional)                  |
| `--upload`             | sendet das Ergeniss an NTFY Server (Default: Aus) |
| `--help`               | Hilfe und Parameter anzeigen                      |

## 📋 Funktionsweise
- Das Skript misst CPU-Temperatur, Frequenz und Auslastung während eines Stresstests.
- Daten werden in eine CSV-Datei geloggt.
- Aus den Daten wird ein Diagramm (PNG) erstellt.
- Optional wird aus dem PNG ein PDF-Bericht generiert.
- Bei der Vollversion werden die Dateien und eine Benachrichtigung per ntfy verschickt.

## 🔒 Sicherheit
Achte darauf, deinen echten ntfy Token und Topic in cpu_stress_full_ntfy.sh einzutragen.
Token niemals öffentlich im Internet freigeben!

## Drittanbieter-Software

Dieses Projekt nutzt folgende externe Programme, die separat installiert sein müssen:

- [stress-ng](https://manpages.ubuntu.com/manpages/latest/man1/stress-ng.1.html) (GPLv2)
- [gnuplot](http://www.gnuplot.info/) (GPL)
- [ImageMagick](https://imagemagick.org/) (Apache 2.0)
- [curl](https://curl.se/) (MIT)

Diese Tools sind nicht Teil dieses Repositories und unterliegen jeweils eigenen Lizenzbedingungen.

# Quellenverzeichnis für verwendete Tools

In den folgenden Bash-Skripten werden verschiedene Open Source Tools genutzt. Die Skripte selbst wurden von mir entwickelt; die Funktionsweise orientiert sich an den Möglichkeiten und Schnittstellen dieser Programme:

## Verwendete Tools

1. **stress-ng**
   - Zweck: Durchführung des CPU-Stresstests
   - Homepage: https://manpages.debian.org/unstable/stress-ng/stress-ng.1.en.html
   - Lizenz: GPL-2.0

2. **gnuplot**
   - Zweck: Erstellung von Diagrammen (PNG) aus den geloggten CSV-Daten
   - Homepage: http://www.gnuplot.info/
   - Lizenz: gnuplot-Lizenz (frei nutzbar)

3. **ImageMagick (convert)**
   - Zweck: Umwandlung von PNG-Bildern zu PDF-Berichten (optional)
   - Homepage: https://imagemagick.org/
   - Lizenz: Apache 2.0

4. **ntfy**
   - Zweck: Versand von Benachrichtigungen und Dateien per Push-Server (POST)
   - Homepage: https://ntfy.sh/
   - Lizenz: MIT

5. **curl**
   - Zweck: HTTP-Requests für Benachrichtigung und Upload (ntfy)
   - Homepage: https://curl.se/
   - Lizenz: curl-Lizenz (frei nutzbar)

## Hinweise
- Die Implementierung der Skripte wurde inspiriert durch die Dokumentation und Beispiele der genannten Projekte.
- Es wurde darauf geachtet, keine fremden Quelltextteile zu übernehmen, sondern ausschließlich auf veröffentlichte Schnittstellen/Befehle zurückzugreifen.
- Für alle genannten Tools gelten die jeweiligen Open Source Lizenzen.

---

**Stand: Mai 2025**
