# CPU-Stresstest-Skripte

Zwei Skripte zur Überwachung der CPU-Temperatur bei Belastung (Linux, z.B. Raspberry Pi):

- `cpu_stress_full.sh`  
  Mit ntfy Server Upload (Benachrichtigung + Dateien)  
  - Benötigt `curl`, `stress-ng`, `gnuplot`, `imagemagick` (`convert` für PDF)

- `cpu_stress_local.sh`  
  Nur lokale Speicherung (CSV, PNG, optional PDF) ohne Upload  
  - Benötigt `stress-ng`, `gnuplot`, `imagemagick` (optional für PDF)

---

## Nutzung

```bash
chmod +x cpu_stress_full.sh cpu_stress_local.sh
