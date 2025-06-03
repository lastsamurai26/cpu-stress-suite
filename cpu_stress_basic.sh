#!/bin/bash

# cpu_stress_basic.sh
# Einfacher CPU-Stresstest mit Logging und PNG-Diagramm (kein PDF, kein ntfy).

DEFAULT_TIMEOUT=20
DEFAULT_COOLDOWN=5
DEFAULT_PREPARE=1 

TIMEOUT_MINUTES=$DEFAULT_TIMEOUT
COOL_DOWN_MINUTES=$DEFAULT_COOLDOWN
PREPARE_MINUTES=$DEFAULT_PREPARE

for ARG in "$@"; do
    case $ARG in
        --prepare=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && PREPARE_MINUTES=$VAL ;;
        --timeout=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && TIMEOUT_MINUTES=$VAL ;;
        --cooldown=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && COOL_DOWN_MINUTES=$VAL ;;
        --help)
            echo "Usage: $0 [--timeout=MINUTES] [--cooldown=MINUTES] [--prepare=MINUTES]"
            echo "  --prepare=N   Vorbereitungszeit vor Test (Standard: $DEFAULT_PREPARE)"
            echo "  --timeout=N     Dauer Stresstest (Standard: $DEFAULT_TIMEOUT)"
            echo "  --cooldown=N    Dauer Abkühlung (Standard: $DEFAULT_COOLDOWN)"
            exit 0
            ;;
    esac
done


echo "===== Konfiguration ====="
echo "Vorbereitungszeit = ${PREPARE_MINUTES} Minute(n) (--prepare=)"
echo "Stresstestzeit = $TIMEOUT_MINUTES Minuten"
echo "Abkühlzeit     = $COOL_DOWN_MINUTES Minuten"
echo "========================="

TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
COOL_DOWN_SECONDS=$((COOL_DOWN_MINUTES * 60))
PREPARE_SECONDS=$((PREPARE_MINUTES * 60))
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
WORKDIR=$(pwd)
LOGFILE=$(realpath "cpu_temp_log_$TIMESTAMP.csv")
PLOTFILE=$(realpath "cpu_temp_plot_$TIMESTAMP.png")

echo "Zeit,Temperatur (°C),Frequenz (MHz),CPU-Last (%),Phase" > "$LOGFILE"

log_status() {
    PHASE=$1
    TEMP_C=$(vcgencmd measure_temp | grep -oP '[0-9.]+')
    FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    FREQ_MHZ=$((FREQ / 1000))
    CPU_USAGE=$(top -bn2 -d 0.2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8}')
    echo "$(date +%H:%M:%S),$TEMP_C,$FREQ_MHZ,$CPU_USAGE,$PHASE" | tee -a "$LOGFILE"
}

echo "Starte in $PREPARE_MINUTES Minute(n) mit dem CPU-Stresstest..."
SECONDS_ELAPSED=0
while [ $SECONDS_ELAPSED -lt $PREPARE_SECONDS ]; do
    log_status "Vorbereitung"
    sleep 20
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 20))
done


echo "Stresstest läuft..."
stress-ng -c 4 --timeout "${TIMEOUT_MINUTES}m" & STRESS_PID=$!
SECONDS_ELAPSED=0
while kill -0 $STRESS_PID 2>/dev/null && [ $SECONDS_ELAPSED -lt $TIMEOUT_SECONDS ]; do
    log_status "Stresstest"
    sleep 20
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 20))
done
wait $STRESS_PID

echo "Abkühlung..."
SECONDS_ELAPSED=0
while [ $SECONDS_ELAPSED -lt $COOL_DOWN_SECONDS ]; do
    log_status "Abkühlung"
    sleep 20
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 20))
done

echo "Erzeuge Diagramm..."
gnuplot <<EOF
set datafile separator ","
set terminal png size 1200,700
set output "$PLOTFILE"
set title "CPU Temperatur, Frequenz und Auslastung"
set xdata time
set timefmt "%H:%M:%S"
set format x "%H:%M"
set xlabel "Zeit"
set ylabel "Temperatur (°C)"
set yrange [0:100]
set ytics 10
set y2label "CPU-Last (%) / Frequenz (MHz)"
set y2tics
set grid
set key outside
set label "Temperaturgrenze 70°C" at graph 0.01, first 70 tc rgb "red"
plot \
    "$LOGFILE" using 1:2 title "Temperatur (°C)" with lines lc rgb "red", \
    "$LOGFILE" using 1:3 axes x1y2 title "Frequenz (MHz)" with lines lc rgb "blue", \
    "$LOGFILE" using 1:4 axes x1y2 title "CPU-Last (%)" with lines lc rgb "green", \
    70 title "Grenze 70°C" with lines lc rgb "#888888" dashtype 2
EOF

echo "Diagramm gespeichert unter: $PLOTFILE"
echo "CSV-Log gespeichert unter: $LOGFILE"

echo "Fertig."
