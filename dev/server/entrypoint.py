import os
import pty
import sys
from pathlib import Path

SERVERDIR = os.getenv('SERVERDIR')
MAXPLAYERS = os.getenv('MAXPLAYERS')
MAP = os.getenv('MAP')
GAMEMODE = os.getenv('GAMEMODE')
PORT = os.getenv('PORT')
GSLT_TOKEN = Path('/.gslt_token').read_text().strip()

def read(fd):
    try:
        while True:
            data = os.read(fd, 1024)
            if not data:  # Exit loop on EOF
                break
            sys.stdout.write(data.decode())
            sys.stdout.flush()
    except KeyboardInterrupt:
        pass

def main():
    command = [
        f"{SERVERDIR}/srcds_run",
        "-console",
        "-game", "garrysmod",
        "+maxplayers", MAXPLAYERS,
        "+map", MAP,
        "+gamemode", GAMEMODE,
        "-norestart",
        "+sv_lan", "0",
        "-port", PORT,
        "+sv_setsteamaccount", GSLT_TOKEN
    ]
    pty.spawn(command, read)

if __name__ == "__main__":
    main()