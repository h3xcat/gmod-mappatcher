#!/usr/bin/env python3

import os
import subprocess
import winreg

APP_ROOT= os.path.dirname(os.path.abspath(__file__))
WORKSHOP_ID = '1572250342'

def find_garrys_mod_dir() -> str:
    try:
        with winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 4000",
            0,
            winreg.KEY_READ
        ) as skey:
            return winreg.QueryValueEx(skey, 'InstallLocation')[0]
    except OSError:
        raise FileNotFoundError("Garry's Mod directory not found.")

def find_addon_dir(start_dir: str) -> str:
    current_dir = start_dir
    while True:
        addon_json_path = os.path.join(current_dir, 'addon.json')
        if os.path.exists(addon_json_path):
            return current_dir  # Return the directory containing addon.json
        
        parent_dir = os.path.dirname(current_dir)
        if parent_dir == current_dir:
            # We've reached the root and didn't find addon.json
            raise FileNotFoundError("addon.json not found.")
        
        current_dir = parent_dir  # Move up to the parent directory

def pack_addon(gmod_dir: str, addon_dir: str) -> str:
    addon_name = os.path.basename(addon_dir)
    gma_output_path = os.path.join(addon_dir, f'{addon_name}.gma')
    gmad_path = os.path.join(gmod_dir, 'bin', 'gmad.exe')
    command = [gmad_path, 'create', '-folder', addon_dir, '-out', gma_output_path]
    subprocess.run(command, check=True)
    return gma_output_path

def update_addon(gmod_dir: str, gma_path: str, workshop_id: str):
    gmpublish_path = os.path.join(gmod_dir, 'bin', 'gmpublish.exe')
    command = [gmpublish_path, 'update', '-addon', gma_path, '-id', workshop_id]
    subprocess.run(command, check=True)

def main():
    try:
        gmod_dir = find_garrys_mod_dir()
        addon_dir = find_addon_dir(APP_ROOT)

        print(f'Garry\'s Mod directory: {gmod_dir}')
        print(f'Addon directory: {addon_dir}')

        gma_path = pack_addon(gmod_dir, addon_dir)
        print(f'Packed addon: {gma_path}')

        update_addon(gmod_dir, gma_path, WORKSHOP_ID)
        print('Uploaded addon to workshop.')
    except FileNotFoundError as e:
        print(e)
    except subprocess.CalledProcessError as e:
        print(f'Error: {e}')

if __name__ == "__main__":
    main()