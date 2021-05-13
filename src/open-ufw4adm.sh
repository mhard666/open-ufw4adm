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
# v. 00.03.00 - 20210513 - mh - Prüfung Pfad zur tempDatei
# v. 00.04.00 - 20210513 - mh - Debug und Verbose Ausgabe als Funktion
#
# ToDo:
# - Statusabfrage --status
# - Hilfe --help
# - Schließen der geöffneten Verbindung erzwingen --disable
# - Ausführliche Ausgabe --verbose
# - Ausgabe unterdrücken --quiet
# - Prüfen auf SSH Verbindung. Keine SSH Verbindung nur zum schließen geöffneter Verbindungen erlaubt

### Konstanten

rERROR_None=0
rERROR_RunNotAsRoot=255
rERROR_PathNotExist=254

### Variablen

debugCounter=0
defaultTmpFile="/var/tmp/ufwadmcmd.tmp"          # Pfad zur Default-temp-Datei

### Funktionen

# Gibt Debuginformationen auf dem Bildschirm aus
function printDebug() {
    # Parameter prüfen
    if [ $# -lt 1 ]
    then
        echo "usage: $0 DEBUGTEXT"
        return $rERROR_WrongParameters
    fi

    debgText=$1

    if [ $clDebug -eq 1 ]; then
        # Counter formatieren...
        c="$(printf '%08d' "$debugCounter")"
        echo "D: $c: $debgText"
        ((debugCounter++))
    fi
}

# Gibt erweiterte Informationen auf dem Bildschirm aus
function printVerbose() {
    # Parameter prüfen
    if [ $# -lt 1 ]
    then
        echo "usage: $0 VERBOSETEXT"
        return $rERROR_WrongParameters
    fi

    verbText=$1

    if [ $clVerbose -eq 1 ]; then
        echo "$verbText"
    fi
}

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
clDebug=1
clVerbose=0
clQuiet=0
clFailure=0
clTmpFile=""

# Get command line parameters
while [ $# -gt 0 ]       #Solange die Anzahl der Parameter ($#) größer 0
do
    case $1 in 
        -h|--help )     printDebug "CmdlnParam: $1" 
                        clHelp=1 ;;
        -s|--status )   printDebug "CmdlnParam: $1" 
                        clStatus=1 ;;
        -d|--disable )  printDebug "CmdlnParam: $1" 
                        clDisable=1 ;;
        -v|--verbose )  printDebug "CmdlnParam: $1"
                        clVerbose=1 ;;
        -q|--quiet )    printDebug "CmdlnParam: $1"
                        clQuiet=1 ;;
        -t|--temp-file ) printDebug "CmdlnParam: $1 $2"
                        clTmpFile="$2"
                        shift ;;
        * )             printDebug "CmdlnParam Fehler"
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
#   if [clTmpFile]; then # detaillierte hilfe zu temp
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

# übergebene Kommandozeilenparameter (Debug)
printDebug "Hilfe: $clHelp"
printDebug "Status: $clStatus"
printDebug "Disable: $clDisable"
printDebug "Verbose: $clVerbose"
printDebug "Quiet: $clQuiet"
printDebug "Fehler: $clFailure"
printDebug "Tempfile: $clTmpFile"


# Temporäre Datei festlegen. Wurde ein individuelles tmpFile übergeben, dieses verwenden, sonst das globalTmpFile
# Prüfen, ob clTemp ungleich "" ist
if [ ! "$clTmpFile" = "" ]; then
    # clTemp ist ungleich "" -> tmpFile = clTemp
    tmpFile=$clTmpFile
else
    tmpFile=$defaultTmpFile
fi
printVerbose "TempFile: $tmpFile"

# Prüfen, ob dirname des Temp-Pfades nicht existiert (Fehler, da dann auch die tempDatei nicht existieren, bzw. angelegt werden kann)
tmpPath=$(dirname "$tmpFile")
printVerbose "TempPath: $tmpPath"
if [ ! -d $tmpPath ]; then
    # tempPath existiert nicht -> Abbruch und Fehler
    echo "Fehler: Das Verzeichnis, in dem die temporäre Datei bereitgestellt werden soll existiert nicht!"
    exit $rERROR_PathNotExist
fi

# Exit zum Testen der command line parameters
exit 99


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
if [ -f $tmpFile ]; then
    # es ist eine temporäre Datei vorhanden - Freigabe entfernen - temporäre Datei löschen
    
    # Commandline aus der temporären Datei lesen
    cmdline=$(cat $tmpFile)
    
    # Commandline in UFW entfernen
    ufw remove $cmdLine
    
    # Prüfen, ob Eintrag in UFW entfernen erfolgreich war
    if [ $? -eq 0 ]; then
        # erfolgreich -> löschen
        del $tmpFile
    fi
else
    # es ist keine temporäre Datei vorhanden - keine Freigabe gesetzt - neu setzen und tmp schreiben

    # Client-IP ermitteln
    client=$(echo $SSH_CLIENT | awk '{ print $1 }')

    # Freigeben (Eintrag an erster Stelle schreiben!)
    # ufw allow from $client

    cmdline="allow from $client"
    ufw $cmdLine
    # prüfen, ob Freigabe erfolgreich war 
    if [ $? -eq 0 ]; then
        # erfolgreich - cmdline temporär speichern...
        echo $cmdLine >> $tmpFile
    fi
fi