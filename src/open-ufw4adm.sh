#!/bin/bash
#
# open-ufw4adm.sh
#
# Öffnet die UFW-Firewall für den administrativ zugreifenden Client. Ist die Firewall bereits geöffnet, wird die Freigabe wieder entfernt.
#
# v. 00.01.00 - 20210512 - mh - Initiale Version
# v. 00.02.00 - 20210513 - mh - Auswertung der Kommandozeilenparameter
# v. 00.02.01 - 20210513 - mh - Korrekturen bei Auswertung Cmdline Parameters
# v. 00.02.02 - 20210513 - mh - Auswertung Cmdline Parameter und Hilfe funktionieren im Wesentlichen
#
# ToDo:
# - Statusabfrage --status
# - Hilfe --help
# - Schließen der geöffneten Verbindung erzwingen --disable
# - Ausführliche Ausgabe --verbose
# - Ausgabe unterdrücken --quiet
# - Prüfen auf SSH Verbindung. Keine SSH Verbindung nur zum schließen geöffneter Verbindungen erlaubt

# Konstanten
rERROR_None=0
rERROR_RunNotAsRoot=2000


# Check if script is running as root...
SYSTEM_USER_NAME=$(id -un)
if [[ "${SYSTEM_USER_NAME}" != 'root'  ]]
then
    # log "regular" "ERROR" "Script nicht mit root-Privilegien gestartet - Abbruch"
    echo 'You are running the script not as root'
    # exit $rERROR_RunNotAsRoot
fi

clHelp=0
clStatus=0
clDisable=0
clVerbose=0
clQuiet=0
clFailure=0
clTemp=""

# Get command line parameters
while [ $# -gt 0 ]       #Solange die Anzahl der Parameter ($#) größer 0
do
    case $1 in 
        -h|--help )  echo $1 
                        clHelp=1 ;;
        -s|--status )   echo $1 
                        clStatus=1 ;;
        -d|--disable )  echo $1 
                        clDisable=1 ;;
        -v|--verbose )  echo $1
                        clVerbose=1 ;;
        -q|--quiet )    echo $1
                        clQuiet=1 ;;
        -t|--temp-file ) echo $1 $2
                        clTemp="$2"
                        shift ;;
        * )             echo "Fehler"
                        clFailure=1 ;;
    esac
    shift   # Parameter verschieben $2->$1, $3->$2, $4->$3,...
done

# Prüfen, ob clVerbose und clQuiet gleich sind und clVerbose ungleich 0 (Parameter --verbose und --quiet gesetzt)
if [ $clVerbose -eq $clQuiet ] && [ $clVerbose -ne 0 ]; then    # kann nicht verbose und quiet gleichzeitig sein -> fehler
    echo "Fehler: Die Parameter --verbose und --quiet können nicht gleichzeitig verwendet werden."
    echo ""
    clFailure=1
fi

# Prüfen, ob clStatus und clDisable gleich sind und clStatus ungleich 0 (Parameter --status und --disable gesetzt)
if [ $clStatus -eq $clDisable ] && [ $clStatus -ne 0 ]; then    # kann nicht status und disable sein -> fehler
    echo "Fehler: Die Parameter --status und --disable können nicht gleichzeitig verwendet werden."
    echo ""
    clFailure=1
fi

# Prüfen, ob clFailure gleich 1 ist (Fehler aufgetreten)
if [ $clFailure -eq 1 ]; then # Fehlerangabe und hilfe=1 anzeigen
    echo "Fehler aufgetreten, Script wird abgebrochen..."
    echo ""
    clHelp=1
fi

# Prüfen, ob clHelp gleich 1 ist (Hilfe anzeigen)
if [ $clHelp -eq 1 ]; then
    # Default Errorlevel (0) zum Beenden des Scripts setzen
    errorLevel=$rERROR_None

    # Prüfen, ob clFailure gleich 1 ist (Fehler aufgetreten)
    if [ $clFailure -eq 1 ]; then    # zuerst fehler und standardhilfe anzeigen; errorlevel setzen!; andere cl-Variablen zurücksetzen!
        # Errorlevel setzen
        errorLevel=2001
        helpText="Aufruf ....\n
        \n
        param1\n
        param2\n
        param3\n
        "
    
#   if [status]; then # detaillierte Hilfe zu status
#   if [disable]; then # detaillierte hilfe zu disable
#   if [verbose]; then # detaillierte hilfe zu verbose
#   if [quiet]; then # detaillierte hilfe zu quiet
#   if [temp]; then # detaillierte hilfe zu temp
    else    # standard hilfe
        helpText="open-ufw4adm.sh [[-h|--help | -d|--disable | -s|--status] -t|--temp-file FILE] [-v|--verbose | -q|--quiet]\n
        \n
        -h|--help             Zeigt diese Hilfe an\n
        -d|--disable          Deaktiviert die Regel, welche alle Verbindungen für den Zugriff freigegeben hat\n
        -s|--status           Zeigt den Status der Firewall an\n
        -t|--temp-file FILE   Gibt einen individuellen Dateinamen für die temporäre Datei an\n
        -v|--verbose          Ausführliche Ausgaben aktivieren\n
        -q|--quiet            Ausgaben unterdrücken\n
        "
    fi

    echo -e $helpText
    # Errorlevel zum Beenden des Scripts setzen
    errorLevel=$rERROR_None
    exit $errorLevel
fi

echo "Hilfe: $clHelp"
echo "Status: $clStatus"
echo "Disable: $clDisable"
echo "Verbose: $clVerbose"
echo "Quiet: $clQuiet"
echo "Fehler: $clFailure"
echo "Tempfile: $clTemp"


# Exit zum Testen der command line parameters
exit 99


# temporäre Datei festlegen
tmpfile=/var/tmp/ufwadmcmd.tmp

# Statusinformation ausgeben
# if [ $1 == "--status" ]; then
#	wenn $tmpfile existiert, einlesen und ufw status nach dessen inhalt grepen
#		$cmdline=$(cat $tmpfile)
#		ufw status | grep $cmdline
#
#	wenn $tmpfile nicht existiert, ssh-client-ip ermitteln und ufw status nach adresse grepen
#		ufw status | grep $client
# fi

# prüfen ob temporäre datei existiert
if [ -f $tmpfile ]; then
    # es ist eine temporäre Datei vorhanden - Freigabe entfernen - temporäre Datei löschen
    
    # Commandline aus der temporären Datei lesen
    cmdline=$(cat $tmpfile)
    
    # Commandline in UFW entfernen
    ufw remove $cmdline
    
    # Prüfen, ob Eintrag in UFW entfernen erfolgreich war
    if [ $? -eq 0 ]; then
        # erfolgreich -> löschen
        del $tmpfile
    fi
else
    # es ist keine temporäre Datei vorhanden - keine Freigabe gesetzt - neu setzen und tmp schreiben

    # Client-IP ermitteln
    client=$(echo $SSH_CLIENT | awk '{ print $1 }')

    # Freigeben (Eintrag an erster Stelle schreiben!)
    # ufw allow from $client

    cmdline="allow from $client"
    ufw $cmdline
    # prüfen, ob Freigabe erfolgreich war 
    if [ $? -eq 0 ]; then
        # erfolgreich - cmdline temporär speichern...
        echo $cmdline >> $tmpfile
    fi
fi