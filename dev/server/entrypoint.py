import os
import pty
import sys

SERVERDIR = os.getenv('SERVERDIR')
MAXPLAYERS = os.getenv('MAXPLAYERS')
MAP = os.getenv('MAP')
GAMEMODE = os.getenv('GAMEMODE')
PORT = os.getenv('PORT')

def read(fd):
    while True:
        data = os.read(fd, 1024)
        if not data:  # Exit loop on EOF
            break
        sys.stdout.write(data.decode())
        sys.stdout.flush()

def main():
    command = [
        f"{SERVERDIR}/srcds_run",
        "-console",
        "-game", "garrysmod",
        "+maxplayers", MAXPLAYERS,
        "+map", MAP,
        "+gamemode", GAMEMODE,
        "-port", PORT
    ]
    pty.spawn(command, read)

if __name__ == "__main__":
    main()