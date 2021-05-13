#!/bin/bash
#
# open-ufw4adm.sh
#
# Öffnet die UFW-Firewall für den administrativ zugreifenden Client. Ist die Firewall bereits geöffnet, wird die Freigabe wieder entfernt.
#
# v. 00.01.00 - 20210512 - mh - Initiale Version
#
# ToDo:
# - Statusabfrage --status
# - Hilfe --help
# - Schließen der geöffneten Verbindung erzwingen --disable
# - Ausführliche Ausgabe --verbose
# - Ausgabe unterdrücken --quiet
# - Aufruf nur von einer SSH

# Konstanten
rERROR_RunNotAsRoot=2000


# Check if script is running as root...
SYSTEM_USER_NAME=$(id -un)
if [[ "${SYSTEM_USER_NAME}" != 'root'  ]]
then
    # log "regular" "ERROR" "Script nicht mit root-Privilegien gestartet - Abbruch"
    echo 'You are running the script not as root'
    # exit $rERROR_RunNotAsRoot
fi

help=0
status=0
disable=0
verbose=0
quiet=0
failure=0
temp=""

# Get command line parameters
while [ $# -gt 0 ]       #Solange die Anzahl der Parameter ($#) größer 0
do
    case $1 in 
        -h|--help )  echo $1 
                        help=1 ;;
        -s|--status )   echo $1 
                        status=1 ;;
        -d|--disable )  echo $1 
                        disable=1 ;;
        -v|--verbose )  echo $1
                        verbose=1 ;;
        -q|--quiet )    echo $1
                        quiet=1 ;;
        -t|--temp-file ) echo $1 $2
                        temp="$2"
                        shift ;;
        * )             echo "Fehler"
                        failure=1 ;;
    esac
    echo $1                #Ausgabe des ersten Parameters
    shift                  #Parameter verschieben $2->$1, $3->$2, $4->$3,...
done

# if [v == u]; then # kann nicht verbose und unterdrückt sein -> fehler
# if [status == close]; then # kann nicht status und close sein -> fehler 

# if [fehler]; then # Fehlerangabe und hilfe=1 anzeigen

# if [help]; then
#   if [status]; then # detaillierte Hilfe zu status
#   if [disable]; then # detaillierte hilfe zu disable
#   if [verbose]; then # detaillierte hilfe zu verbose
#   if [quiet]; then # detaillierte hilfe zu quiet
#   if [temp]; then # detaillierte hilfe zu temp
#   if [failure]; then # fehler und standardhilfe anzeigen
#   else; standard hilfe
# fi

echo "Hilfe: $help"
echo "Status: $status"
echo "Disable: $disable"
echo "Verbose: $verbose"
echo "Quiet: $quiet"
echo "Fehler: $failure"
echo "Tempfile: $temp"


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