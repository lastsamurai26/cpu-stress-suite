# Quellenverzeichnis für verwendete Tools

In den folgenden Bash-Skripten werden verschiedene Open Source Tools genutzt. Die Skripte selbst wurden von mir (lastsamurai26) entwickelt; die Funktionsweise orientiert sich an den Möglichkeiten und Schnittstellen dieser Programme:

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