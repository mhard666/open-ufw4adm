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
# v. 00.05.00 - 20210516 - mh - temp file nicht mehr benötigt. ufw kommentar verwendet. zusätzliche funktionen
# v. 00.05.01 - 20210516 - mh - Fehlerbehebungen
# v. 00.06.00 - 20210517 - mh - neue Parameter, hilfe
# v. 00.07.00 - 20210517 - mh - alle Parameter und Funktionen implementiert, alte Funktionen und Parameter entfernt
# v. 00.07.01 - 20210518 - mh - Fehlerbehebungen
# v. 00.07.02 - 20210518 - mh - Fehlerbehebungen
#
version="0.7.02"

# ToDo:
# - Ausführliche Ausgabe --verbose
# - Ausgabe unterdrücken --quiet
# - Parameter -I|--open-ip-address IPADDRESS (öffnet die FW für eine bestimmte IP-Adresse)

### Konstanten
rERROR_None=0
rERROR_RunNotAsRoot=255
rERROR_PathNotExist=254
rERROR_CommandFails=253
rERROR_WrongParameters=252


### Variablen
appString="open-ufw4adm, Version: $version, by mhard666\n\n"
defaultHelpText="open-ufw4adm.sh [-h|--help] [-o|--open | -c|--close | -A|--close-all | -D|--close-disconnected | -s|--status] [-d|--debug] [-v|--verbose | -q|--quiet]\n
        \n
        -h|--help                Zeigt diese Hilfe an\n
        -o|--open                Öffnet ufw für die aktuelle Verbindung, sofern sie nicht schon geöffnet ist. Wenn sie offen ist, wird sie nicht geschlossen.\n
        -c|--close               Schließt ufw für die aktuelle Verbindung, sofern sie nicht schon geschlossen ist. Wenn sie geschlossen ist, wird sie nicht geöffnet.\n
        -A|--close-all           Schließt alle offenen Verbindungen in der ufw.\n
        -D|--close-disconnectet  Schließt alle offenen Verbindungen in der ufw, sofern keine SSH-Verbindung zwischen Client und Server mehr besteht.\n
        -s|--status              Zeigt den Status der Firewall an.\n
        -d|--debug               Debug Modus aktivieren.\n
        -v|--verbose             Ausführliche Ausgaben aktivieren.\n
        -q|--quiet               Ausgaben unterdrücken.\n
        "

debugCounter=0
defaultTmpFile="/var/tmp/ufwadmcmd.tmp"          # Pfad zur Default-temp-Datei
ufwComment="open_all4ssh"


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

# Terminal ermitteln
function getTerminal() {
    terminal=$(ps u | grep "ps u" | grep -v grep | awk '{print $7}')
    echo $terminal
}

# IP-Adresse ermitteln
function getClientIpAddress() {
    # Parameter prüfen
    if [ $# -lt 1 ]; then
        echo "usage: $0 TERMINAL"
        return $rERROR_WrongParameters
    fi

    ipClientAddress=$(w | grep $1 | awk '{print $3}')
    echo $ipClientAddress
}

# alle Einträge in ufw zurückgeben, die über dieses script geschrieben wurden
function getOpenUfwEntries() {
    # Parameter prüfen
    if [ $# -lt 1 ]; then
        echo "usage: $0 UFW-COMMENT"
        return $rERROR_WrongParameters
    fi

    ufwStatus=$(ufw status | grep $1)
    echo $ufwStatus
}

# bestimmten Eintrag aus den ufw Einträgen zurückgeben, die über dieses Script geschrieben wurden
# Parameter:    ip address     IP-Adresse des Clients
#               ufw comment    Kommentarzeile in dem Eintrag in der ufw-Firewall
# Ausgabe:      Eintrag in der ufw Firewall, generiert aus der Status-Ausgabe (ufw status)
# Errorlevel:   0                           alles iO
#               rERROR_WrongParameters      Fehler bei Parameterübergabe
#
function getOpenUfwEntry() {
    # Parameter prüfen
    if [ $# -lt 2 ]; then
        echo "usage: $0 IP-ADDRESS UFW-COMMENT"
        return $rERROR_WrongParameters
    fi

    ufwEntry=$(ufw status | grep $2 | grep $1 | awk '{ print $3 }')
    echo $ufwEntry
}

# alle IPs aus den ufw Einträgen zurückgeben, die über dieses Script geschrieben wurden
function getOpenUfwAddresses() {
    # Parameter prüfen
    if [ $# -lt 1 ]; then
        echo "usage: $0 UFW-COMMENT"
        return $rERROR_WrongParameters
    fi

    ufwAddresses=$(ufw status | grep $1 | awk '{ print $3 }')
    echo $ufwAddresses
}

# bestimmte IP aus den ufw Einträgen zurückgeben, die über dieses Script geschrieben wurden
function getOpenUfwAddress() {
    # Parameter prüfen
    if [ $# -lt 2 ]; then
        echo "usage: $0 IP-ADDRESS UFW-COMMENT"
        return $rERROR_WrongParameters
    fi

    ufwAddress=$(ufw status | grep $2 | grep $1 | awk '{ print $3 }')
    echo $ufwAddress
}

### Start

# Anwendungsinformation ausgeben
echo -e $appString

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
clOpen=0
clClose=0
clCloseAll=0
clCloseDisconnected=0
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
        -o|--open )     printDebug "CmdlnParam: $1" 
                        clOpen=1 ;;
        -c|--close )    printDebug "CmdlnParam: $1" 
                        clClose=1 ;;
        -A|--close-all )  printDebug "CmdlnParam: $1" 
                        clCloseAll=1 ;;
        -D|--close-disconnected )  printDebug "CmdlnParam: $1" 
                        clCloseDisconnected=1 ;;
        -d|--debug )    printDebug "CmdlnParam: $1"
                        clDebug=1 ;;
        -v|--verbose )  printDebug "CmdlnParam: $1"
                        clVerbose=1 ;;
        -q|--quiet )    printDebug "CmdlnParam: $1"
                        clQuiet=1 ;;
#        -t|--temp-file ) printDebug "CmdlnParam: $1 $2"
#                        clTmpFile="$2"
#                        shift ;;
        * )             printDebug "CmdlnParam Fehler"
                        clFailure=1 ;;
    esac
    shift   # Parameter verschieben $2->$1, $3->$2, $4->$3,...
done

# Prüfen, ob clVerbose und clQuiet gleich sind und clVerbose ungleich 0 (Parameter --verbose und --quiet gesetzt)
if [ $(($clVerbose + $clQuiet)) -gt 1 ]; then    # kann nicht verbose und quiet gleichzeitig sein -> fehler
    echo "Fehler: Die Parameter --verbose und --quiet können nicht gleichzeitig verwendet werden."
    echo ""
    clFailure=1
fi

# Prüfen, ob clStatus, clOpen, clClose, clCloseAll, clCloseDisconnected zusammen gesetzt sind (mehr als ein Parameter von --status, --open, --close, --close-all und --close-disconnected gesetzt)
if [ $(($clStatus + $clOpen + $clClose + $clCloseAll + $clCloseDisconnected)) -gt 1 ]; then
    echo "Fehler: Die Parameter --status, --open, --close, --close-all und --close-disconnected können nicht gleichzeitig verwendet werden."
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
        errorLevel=$rERROR_WrongParameters
        helpText=$defaultHelpText
    
#   if [status]; then # detaillierte Hilfe zu status
#   if [disable]; then # detaillierte hilfe zu disable
#   if [verbose]; then # detaillierte hilfe zu verbose
#   if [quiet]; then # detaillierte hilfe zu quiet
#   if [clTmpFile]; then # detaillierte hilfe zu temp
    else    # standard hilfe
        helpText=$defaultHelpText
    fi

    echo -e $helpText
    exit $errorLevel
fi

# übergebene Kommandozeilenparameter (Debug)
printDebug "Hilfe: $clHelp"
printDebug "Status: $clStatus"
printDebug "Open: $clOpen"
printDebug "Close: $clClose"
printDebug "Close All: $clCloseAll"
printDebug "Close Diconnected: $clCloseDisconnected"
printDebug "Verbose: $clVerbose"
printDebug "Quiet: $clQuiet"
printDebug "Fehler: $clFailure"

# - aktuelles Terminal holen
trm=$(getTerminal)

# - Client IP Adresse des aktuellen Terminals holen
addr=$(getClientIpAddress "$trm")

# - Eintrag aus der ufw holen
entry=$(getOpenUfwEntry $addr $ufwComment)

# Exit zum Testen der command line parameters
# exit 99

# Statusinformation ausgeben
if [ $clStatus -eq 1 ]; then
	ufw=$(ufw status | grep $ufwComment)

    echo "Terminal: $trm"
    echo "IP-Address: $addr"
    echo "ufw Status:"
    echo $ufw

    exit 0
fi

# Alle offenen Verbindungen beenden
if [ $clCloseAll -eq 1 ]; then
    # echo "not implemented yet."
    # exit $rERROR_None

    # Alle Verbindungen holen
    entries=$(ufw status | grep $ufwComment)
    
    # Prüfen, ob entries leer ist -> Abbruch
    if [ "$entries" = "" ]; then
        echo "nothing to do..."
        exit $rERROR_None
    fi

    # alle Zeilen in der Variable $entries durchlaufen
    while read -r line 
    do
        # IP Addresse aus der aktuellen Zeile auslesen
        addr=$(echo $line | awk '{print $3}')

        # ufw-Commandline zusammenbauen
        cmdLine="allow from $addr comment $ufwComment"

        # Eintrag löschen
        ufw delete $cmdLine
        if [ $? -ne 0 ]; then echo "ufw delete command fails..."; exit $rERROR_CommandFails; fi

    done <<<"$entries"

    # Beenden des Scripts ohne Fehler
    exit $rERROR_None
fi

# Disconected offene Verbindungen schließen
if [ $clCloseDisconnected -eq 1 ]; then
    # echo "not implemented yet."
    # exit $rERROR_None

    # Alle Verbindungen holen
    entries=$(ufw status | grep $ufwComment)
    
    # Prüfen, ob entries leer ist -> Abbruch
    if [ "$entries" = "" ]; then
        echo "nothing to do..."
        exit $rERROR_None
    fi

    # alle Zeilen in der Variable $entries durchlaufen
    while read -r line 
    do
        # IP Addresse aus der aktuellen Zeile auslesen
        addr=$(echo $line | awk '{print $3}')

        # Prüfen, ob w keinen Eintrag mit der ermittelten IP-Adresse liefert (dann gibt es keine Verbindung mehr und die FW wird wieder geschlossen)
        if [ "$(w | grep $addr)" = "" ]; then

            # kein Eintrag vorhanden, FW schließen

            # ufw-Commandline zusammenbauen
            cmdLine="allow from $addr comment $ufwComment"

            # Eintrag löschen
            ufw delete $cmdLine
            if [ $? -ne 0 ]; then echo "ufw delete command fails..."; exit $rERROR_CommandFails; fi
        fi
    done <<<"$entries"

    # Beenden des Scripts ohne Fehler
    exit $rERROR_None
fi


# Standardbehandlung: Öffnen oder Schließen der FW für die aktuelle Verbindung

# - ist ein Eintrag vorhanden?
if [ ! "$entry" = "" ]; then
    # - JA -> diesen löschen
    # Prüfen, ob --open übergeben wurde (dann dürfen nur neue Verbindungen geöffnet werden)
    if [ ! $clOpen -eq 1 ]; then        # nur wenn nicht --open übergeben wurde
        cmdLine="allow from $addr comment $ufwComment"
        ufw delete $cmdLine
        if [ $? -ne 0 ]; then echo "ufw delete command fails..."; exit $rERROR_CommandFails; fi
    fi
else
    # - NEIN -> einen anlegen
    # Prüfen, ob --close übergeben wurde (dann dürfen nur offene Verbindungen geschlossen werden)
    if [ ! $clClose -eq 1 ]; then       # nur wenn nicht --close übergeben wurde.
        cmdLine="allow from $addr comment $ufwComment"
        ufw insert 1 $cmdLine
        if [ $? -ne 0 ]; then echo "ufw insert command fails..."; exit $rERROR_CommandFails; fi
    fi
fi

exit 0

