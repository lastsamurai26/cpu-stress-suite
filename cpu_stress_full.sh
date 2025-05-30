#!/bin/bash

# cpu_stress_full.sh
# CPU Stresstest mit Temperatur-Logging, PNG-Plot, optional PDF, und Upload an ntfy Server

# Konfiguration
DEFAULT_TIMEOUT=20
DEFAULT_COOLDOWN=5

# ntfy-Konfiguration anpassen:
NTFY_SERVER="https://ntfy.sh/YOUR_TOPIC"
NTFY_TOKEN="Bearer YOUR_AUTH_TOKEN"

TIMEOUT_MINUTES=$DEFAULT_TIMEOUT
COOL_DOWN_MINUTES=$DEFAULT_COOLDOWN
INCLUDE_PDF=false

# Argumente parsen
for ARG in "$@"; do
    case $ARG in
        --timeout=*)
            VALUE="${ARG#*=}"
            [[ "$VALUE" =~ ^[0-9]+$ ]] && TIMEOUT_MINUTES=$VALUE
            ;;
        --cooldown=*)
            VALUE="${ARG#*=}"
            [[ "$VALUE" =~ ^[0-9]+$ ]] && COOL_DOWN_MINUTES=$VALUE
            ;;
        --pdf)
            INCLUDE_PDF=true
            ;;
    esac
done

echo "===== Konfiguration ====="
echo "Stresstestzeit = ${TIMEOUT_MINUTES} Minuten"
echo "Abkühlzeit     = ${COOL_DOWN_MINUTES} Minuten"
echo "PDF-Erstellung = $( [ "$INCLUDE_PDF" = true ] && echo aktiviert || echo deaktiviert )"
echo "========================="

TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
COOL_DOWN_SECONDS=$((COOL_DOWN_MINUTES * 60))

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="cpu_temp_log_$TIMESTAMP.csv"
PLOTFILE="cpu_temp_plot_$TIMESTAMP.png"
PDFFILE="cpu_temp_report_$TIMESTAMP.pdf"

echo "Zeit,Temperatur (°C),Frequenz (MHz),CPU-Last (%),Phase" > "$LOGFILE"

log_status() {
    PHASE=$1
    TEMP_RAW=$(vcgencmd measure_temp)
    TEMP_C=$(echo "$TEMP_RAW" | grep -oP '[0-9.]+')
    FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    FREQ_MHZ=$((FREQ / 1000))
    CPU_USAGE=$(top -bn2 -d 0.2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8}')
    TIME_NOW=$(date +%H:%M:%S)
    echo "$TIME_NOW,$TEMP_C,$FREQ_MHZ,$CPU_USAGE,$PHASE" | tee -a "$LOGFILE"
}

echo "Starte in 1 Minute mit dem CPU-Stresstest..."
for i in {1..3}; do log_status "Vorbereitung"; sleep 20; done

echo "Starte CPU-Stresstest für $TIMEOUT_MINUTES Minuten..."
stress-ng -c 4 --timeout "${TIMEOUT_MINUTES}m" & STRESS_PID=$!

SECONDS_ELAPSED=0
while kill -0 $STRESS_PID 2>/dev/null && [ $SECONDS_ELAPSED -lt $TIMEOUT_SECONDS ]; do
    log_status "Stresstest"
    sleep 20
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 20))
done

wait $STRESS_PID 2>/dev/null

echo "Abkühlung für $COOL_DOWN_MINUTES Minuten..."
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
set yrange [0:90]
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

if $INCLUDE_PDF; then
    echo "Erzeuge PDF aus PNG..."
    convert "$PLOTFILE" "$PDFFILE"
fi

echo "Sende Benachrichtigung und Dateien an ntfy Server..."

curl -X POST "$NTFY_SERVER" \
     -H "Authorization: $NTFY_TOKEN" \
     -H "Title: CPU Stresstest abgeschlossen" \
     -H "Priority: 4" \
     -H "Tags: chart,cpu" \
     -d "Stresstest: ${TIMEOUT_MINUTES} Min, Cooldown: ${COOL_DOWN_MINUTES} Min."

curl -X PUT "$NTFY_SERVER/$(basename $LOGFILE)" \
     -H "Authorization: $NTFY_TOKEN" \
     --upload-file "$LOGFILE"

curl -X PUT "$NTFY_SERVER/$(basename $PLOTFILE)" \
     -H "Authorization: $NTFY_TOKEN" \
     --upload-file "$PLOTFILE"

if $INCLUDE_PDF; then
    curl -X PUT "$NTFY_SERVER/$(basename $PDFFILE)" \
         -H "Authorization: $NTFY_TOKEN" \
         --upload-file "$PDFFILE"
fi

echo "Fertig."
