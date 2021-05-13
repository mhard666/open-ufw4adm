# Open UFW4Adm

Dieses Script öffnet die UFW-Firewall für einen administrativen Zugang per SSH für die Dauer der administrativen Tätigkeiten.

## Aufruf

`open-ufw4adm.sh [[-h|--help | -d|--disable | -s|--status] -t|--temp-file FILE] [-v|--verbose | -q|--quiet]`

`open-ufw4adm.sh`

Beim ersten Aufruf wird die Firewall für Datenverkehr von der IP-Adresse des SSH-Clients geöffnet. Beim erneuten Aufruf wird die Freigaberegel wieder entfernt.

`open-ufw4adm.sh -h|--help`

Gibt einen Hilfetext aus.

`open-ufw4adm.sh -d|--disable`

Schließt eine geöffnete Verbindung.

`open-ufw4adm.sh -s|--status`

Gibt den Status der Firewall für administrative SSH-Verbindung aus.

`open-ufw4adm.sh [...] -v|--verbose`

Gibt ausführliche Informationen zurück.

`open-ufw4adm.sh [...] -q|--quiet`

Unterdrückt Ausgaben.

`open-ufw4adm.sh --temp-file FILE`

legt ein individuelles Temp-File fest. Das individuelle Temp-File muss beim deaktivieren der FW-Freigabe ebenfalls angegeben werden!
