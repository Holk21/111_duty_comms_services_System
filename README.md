# services (Standalone + ox_lib)

Commands:
- /duty      → choose department (Police/FENZ/CAS/Tow/Civ) + callsign
- /111       → select one or more departments + enter job details; routes to the right teams and COMMS
- /comms     → register/unregister as COMMS for a department (receives all calls for that dept)
- /services  → prints counts of on-duty per department and civs

Install:
1) Ensure ox_lib is installed and started *before* this resource.
   server.cfg:
     ensure ox_lib
     ensure services

2) Drop this folder into resources/ and start it.

Config:
- Edit config.lua to change departments, colors, prefix, or COMMS whitelist.



IF you Have Any Issues Please Add Me On Discord And Create a Ticket 


Discord -- https://discord.com/channels/1315274115531407380/1316886816212647976
