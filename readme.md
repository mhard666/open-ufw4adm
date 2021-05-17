# Open UFW4Adm

Dieses Script öffnet die UFW-Firewall für einen administrativen Zugang per SSH für die Dauer der administrativen Tätigkeiten.

## Aufruf

`open-ufw4adm.sh [-h|--help] [-o|--open | -c|--close | -A|--close-all | -D|--close-disconnected |-s|--status] [-d|--debug] [-v|--verbose | -q|--quiet]`

`open-ufw4adm.sh`

Beim ersten Aufruf wird die Firewall für Datenverkehr von der IP-Adresse des SSH-Clients geöffnet. Beim erneuten Aufruf wird die Freigaberegel wieder entfernt.

`open-ufw4adm.sh -h|--help`

Gibt einen Hilfetext aus.

`open-ufw4adm.sh -o|--open`

Öffent die Firewall für alle Verbindungen des verbundenen Clients. Eine geöffnete Verbindung wird nicht geschlossen.

`open-ufw4adm.sh -c|--close`

Entfernt die Freigabe für alle Verbindungen des verbundenen Clients aus der Firewall. Ist kein Eintrag für den Client vorhanden,
wird auch kein neuer Eintrag zur Verbindungsfreigabe erstellt.

`open-ufw4adm.sh -A|--close-all`

Entfernt alle Freigaben für jegliche Clients aus der Firewall, die über das Script angelegt wurden.

`open-ufw4adm.sh -D|--close-disconnected`

Entfernt alle Freigaben aus der Firewall, wenn die Clients nicht mehr connected sind.

`open-ufw4adm.sh -s|--status`

Gibt den Status der Firewall für administrative SSH-Verbindung aus.

`open-ufw4adm.sh [...] -v|--verbose`

Gibt ausführliche Informationen zurück.

`open-ufw4adm.sh [...] -q|--quiet`

Unterdrückt Ausgaben.
