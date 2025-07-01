#!/bin/bash

# cpu_stress_full_ntfy.sh
# CPU-Stresstest mit Temperatur-Logging, Plot (PNG), optional PDF,
# und optionalem Upload von CSV, PNG und PDF an ntfy Server (POST Upload mit Dateiname).

# Standardwerte
DEFAULT_TIMEOUT=20
DEFAULT_COOLDOWN=5
DEFAULT_PREPARE=1 

# Konfiguration für ntfy
NTFY_SERVER="https://ntfy.sh/YOUR_TOPIC"   # ntfy Topic-URL (ohne Slash am Ende)
NTFY_TOKEN="Bearer YOUR_AUTH_TOKEN"        # z.B. "Bearer abcdef123456"

TIMEOUT_MINUTES=$DEFAULT_TIMEOUT
COOL_DOWN_MINUTES=$DEFAULT_COOLDOWN
PREPARE_MINUTES=$DEFAULT_PREPARE
INCLUDE_PDF=false
DO_UPLOAD=false  # Neu: Upload standardmäßig aus

# Argumente parsen
for ARG in "$@"; do
    case $ARG in
        --prepare=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && PREPARE_MINUTES=$VAL ;;
        --timeout=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && TIMEOUT_MINUTES=$VAL ;;
        --cooldown=*) VAL="${ARG#*=}"; [[ "$VAL" =~ ^[0-9]+$ ]] && COOL_DOWN_MINUTES=$VAL ;;
        --pdf) INCLUDE_PDF=true ;;
        --upload) DO_UPLOAD=true ;;
        --help)
            echo "Usage: $0 [--timeout=MINUTES] [--cooldown=MINUTES] [--prepare=MINUTES] [--pdf] [--upload]"
            echo "  --prepare=N   Vorbereitungszeit vor Test (Standard: $DEFAULT_PREPARE)"
            echo "  --timeout=N     Dauer Stresstest (Standard: $DEFAULT_TIMEOUT)"
            echo "  --cooldown=N    Dauer Abkühlung (Standard: $DEFAULT_COOLDOWN)"
            echo "  --pdf               PDF aus PNG erzeugen (optional)"
            echo "  --upload            Dateien nach Test an ntfy-Server hochladen (optional)"
            exit 0
            ;;
    esac
done

echo "===== Konfiguration ====="
echo "Vorbereitungszeit = ${PREPARE_MINUTES} Minute(n) (--prepare=)"
echo "Stresstestzeit = ${TIMEOUT_MINUTES} Minuten (--timeout=)"
echo "Abkühlzeit     = ${COOL_DOWN_MINUTES} Minuten (--cooldown=)"
echo "PDF-Erstellung = $( [ "$INCLUDE_PDF" = true ] && echo aktiviert || echo deaktiviert )"
echo "Upload an ntfy = $( [ "$DO_UPLOAD" = true ] && echo aktiviert || echo deaktiviert )"
echo "========================="

TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
COOL_DOWN_SECONDS=$((COOL_DOWN_MINUTES * 60))
PREPARE_SECONDS=$((PREPARE_MINUTES * 60))
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
WORKDIR=$(pwd)
LOGFILE=$(realpath "cpu_temp_log_$TIMESTAMP.csv")
PLOTFILE=$(realpath "cpu_temp_plot_$TIMESTAMP.png")
PDFFILE=$(realpath "cpu_temp_report_$TIMESTAMP.pdf")

echo "Zeit,Temperatur (°C),Frequenz (MHz),CPU-Last (%),Phase" > "$LOGFILE"

log_status() {
    PHASE=$1
    # read temperatur
        # Temperatur auslesen mit Fallback
    if command -v vcgencmd >/dev/null 2>&1; then
        TEMP_C=$(vcgencmd measure_temp | grep -oP '[0-9.]+')
    elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$(echo "scale=1; $TEMP_RAW / 1000" | bc)
    else
        TEMP_C="N/A"
    fi
    # read frequency
    FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    FREQ_MHZ=$((FREQ / 1000))
    # read CPU useage
    CPU_USAGE=$(top -bn2 -d 0.2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8}')
    TIME_NOW=$(date +%H:%M:%S)
    echo "$TIME_NOW,$TEMP_C,$FREQ_MHZ,$CPU_USAGE,$PHASE" | tee -a "$LOGFILE"
}

echo "Starte in $PREPARE_MINUTES Minute(n) mit dem CPU-Stresstest..."
SECONDS_ELAPSED=0
while [ $SECONDS_ELAPSED -lt $PREPARE_SECONDS ]; do
    log_status "Vorbereitung"
    sleep 20
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 20))
done

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

if $INCLUDE_PDF; then
    echo "Erzeuge PDF aus PNG..."
    convert "$PLOTFILE" "$PDFFILE"
fi

    echo "Sende Benachrichtigung und Dateien an ntfy Server..."

    # Nachricht senden
    curl -s -X POST "$NTFY_SERVER" \
         -H "Authorization: $NTFY_TOKEN" \
         -H "Title: CPU Stresstest abgeschlossen" \
         -H "Tags: chart" \
         -H "Markdown" \
         -H "Priority: 3" \
         -d "Stresstest: ${TIMEOUT_MINUTES} Min, Cooldown: ${COOL_DOWN_MINUTES} Min

CSV: \`$LOGFILE\`
PNG: \`$PLOTFILE\`$( [ "$INCLUDE_PDF" = true ] && echo -e "\nPDF: \`$PDFFILE\`" )"

if $DO_UPLOAD; then
    # Funktion für Datei-Upload via POST (mit Filename Header)
    upload_file() {
        local FILE=$1
        local MIMETYPE=$2
        echo "Sende Datei $FILE ..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "$NTFY_SERVER" \
            -H "Authorization: $NTFY_TOKEN" \
            -H "Title: Datei-Upload: $(basename "$FILE")" \
            -H "Filename: $(basename "$FILE")" \
            -H "Content-Type: $MIMETYPE" \
            --data-binary @"$FILE")
        echo " - fertig (HTTP $HTTP_CODE)."
    }

    upload_file "$LOGFILE" "text/csv"
    upload_file "$PLOTFILE" "image/png"

    if $INCLUDE_PDF; then
        upload_file "$PDFFILE" "application/pdf"
    fi
else
    echo "Upload an ntfy deaktiviert. Dateien wurden nicht hochgeladen."
fi

echo "Diagramm gespeichert unter: $PLOTFILE"
echo "CSV-Log gespeichert unter: $LOGFILE"
if $INCLUDE_PDF; then
    echo "PDF-Bericht gespeichert unter: $PDFFILE"
fi

echo "Fertig."
