# lslworld


- VLAN 10: guest voor het gastennetwerk
- VLAN 20: trust voor mijn vertrouwde apparaten
- VLAN 30: iot voor camera' s, deurbel etc..
- VLAN 40: app voor applicatie servers
- VLAN 50: db voor database servers
- VLAN 60: ext voor externe communicatie
- VLAN 70: nas voor mijn nas fileserver
- VLAN 80: pve voor mijn proxmox host
- VLAN 90: mgmt voor admins
- VLAN 100: dns voor mijn pi-hole dns server

Hier zijn enkele algemene firewallregels voor elk VLAN om de beveiliging te verbeteren:

- Blokkeer alle inkomende verkeer vanaf het internet, tenzij specifiek toegestaan
- Sta alleen inkomend verkeer toe vanaf specifieke IP-adressen of subnets, indien nodig
- Sta alleen uitgaand verkeer toe naar specifieke IP-adressen of subnets, indien nodig
- Sta alleen verkeer tussen VLAN's toe als dit nodig is voor functionaliteit

Voordat we kunnen starten met het inrichten van firewall regels hebben we 3 regels nodig, voeg deze toe in volgorde:

- Allow established and related connections

Type: LAN in
Description: Allow established and related sessions
Action: Accept
Source Type: Port/IP Group
IPv4 Address Group: Any
Port Group: Any
Destination Type: Port/IP Group
IPv4 Address Group: Any
Port Group: Any
Under Advanced: select Match State Established and Match State Related

- Drop invalid state connections
Type: LAN in
Description: Drop invalid state
Action: Drop
Source Type: Port/IP Group
IPv4 Address Group: Any
Port Group: Any
Destination Type: Port/IP Group
IPv4 Address Group: Any
Port Group: Any
Under Advanced: select Match State Invalid

- Allow  main VLAN to access all VLANs
Type: LAN in
Description: Allow main VLAN access to all VLAN
Action: Accept
Source Type: Network
Network: Default
Network Type: IPv4 Subnet
Destination Type: Port/IP Group
IPv4 Address Group: All Private IPs (192.168.0.0/16)
Port Group: Any

Specifieke firewallregels voor elk VLAN:

VLAN 10: Gastennetwerk

- Blokkeer alle inkomende verkeer vanaf alle andere VLAN's
- Sta alleen uitgaand verkeer toe naar het internet en specifieke IP-adressen of subnets, indien nodig
- Stel een captive portal in voor gasten om zich aan te melden voordat ze toegang hebben tot het netwerk.

VLAN 20: Managementnetwerk voor admin

- Sta alleen inkomend verkeer toe vanaf specifieke IP-adressen of subnets, bijvoorbeeld vanaf uw werkstation thuis.
- Sta alleen uitgaand verkeer toe naar specifieke IP-adressen of subnets, bijvoorbeeld uw thuisnetwerk en internet.

VLAN 30: IoT-netwerk voor camera's, deurbellen, etc.

- Blokkeer alle inkomende verkeer vanaf andere VLAN's, behalve als dit nodig is voor het functioneren van de applicaties.
- Sta alleen uitgaand verkeer toe naar specifieke IP-adressen of subnets, indien nodig voor het functioneren van de apparaten.

VLAN 40: Applicatieservernetwerk

- Sta alleen inkomend verkeer toe vanaf specifieke IP-adressen of subnets, bijvoorbeeld uw thuisnetwerk of een extern subnet dat u gebruikt.
- Sta alleen uitgaand verkeer toe naar specifieke IP-adressen of subnets, indien nodig.

VLAN 50: Databasenetwerk

- Sta alleen inkomend verkeer toe vanaf specifieke IP-adressen of subnets, bijvoorbeeld uw applicatieservernetwerk of een extern subnet dat u gebruikt.
- Sta alleen uitgaand verkeer toe naar specifieke IP-adressen of subnets, indien nodig.

VLAN 60: VLAN voor externe communicatie

- Sta alleen inkomend verkeer toe vanaf specifieke IP-adressen of subnets, bijvoorbeeld uw internetprovider of een externe server waarmee u communiceert.
- Blokkeer alle uitgaande verkeer naar andere VLAN's om dit netwerk volledig te isoleren van de rest van uw netwerk.

Het is belangrijk om de regels voor elke VLAN zo nauwkeurig mogelijk in te stellen, om de be
