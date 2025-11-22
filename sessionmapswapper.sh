#!/bin/bash
exec 2> /dev/null

# Session Map Swapper
# Bash script for swapping custom maps in Session: Skate Sim
# Requires the game to be patched with unreal mod unlocker from https://illusory.dev/

# Copyright (C) 2024-2025 Imhsan
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

# Configuration
# This should point to your Session directory (omit the trailing slash)
SESSIONPATH="$HOME/.local/share/Steam/steamapps/common/Session"

# Variables
sms_session_content_path="${SESSIONPATH}/SessionGame/Content"

# Functions

# Lists all the custom maps found
sms_list() {
    maps=$(find "${sms_session_content_path}/CustomMaps/" -name "*.umap")

    if [ -z "${maps}" ]; then
        printf "Could not find any maps in %s/CustomMaps/ ...\n" ${sms_session_content_path}
        return
    fi

    for map in ${maps}; do
        count=$((count + 1))
        list="${list}$(basename "${map}" ".umap") "
    done

    list=$(printf "%s\n" ${list} | sort)

    printf "Found %s maps in %s/CustomMaps/ ...\n" ${count} ${sms_session_content_path}
    printf "%s  " $list
    printf "\n"
}

# Resets back to the default map
sms_unload() {
    if [[ ! -f "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.umap" && ! -f "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.uexp" ]]; then
        return
    fi

    rm "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.umap"
    rm "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.uexp"

    printf "Unloaded current custom map ...\n"
}

# Loads a custom map, takes a mapname
sms_load() {
    map=$(find "${sms_session_content_path}/CustomMaps/" -name "${1}.umap")

    if [ -z "${map}" ]; then
        printf "Could not find map %s in %s/CustomMaps/ ...\n" ${1} ${sms_session_content_path}
        return
    fi

    if [ ! -d "${sms_session_content_path}/Art/Env/NYC" ]; then
        mkdir --parents "${sms_session_content_path}/Art/Env/NYC"
    fi

    sms_unload

    ln --symbolic "${map}" "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.umap"
    ln --symbolic "${map%.*}".uexp "${sms_session_content_path}/Art/Env/NYC/NYC01_Persistent.uexp"

    printf "Loaded custom map %s from %s/CustomMaps/ ...\n" ${1} ${sms_session_content_path}
}

# Displays a dialog prompting the user for a map to load
sms_dialog() {
    maps=$(find "${sms_session_content_path}/CustomMaps/" -name "*.umap")

    if [ -z "${maps}" ]; then
        zenity --info --title="Session Map Swapper" --text="Could not find any maps ..."
        return
    fi

    for map in ${maps}; do
        list="${list}$(basename "${map}" ".umap") "
    done

    list=$(printf "%s\n" ${list} | sort)

    choice=$(zenity --list --width="100" --height="400" --title="Session Map Swapper" --cancel-label="Quit" --ok-label="Load" --text="Select a map to load ..." --column="${sms_session_content_path}/CustomMaps/" Default ${list})

    if [ ! -z "${choice}" ]; then
        case "${choice}" in
            Default)
                sms_unload
                ;;
            *)
                sms_load "${choice}"
                ;;
        esac
    fi
}

# Prints a help message
sms_usage() {
    printf "Session Map Swapper\n"
    printf "Bash script for swapping custom maps in Session: Skate Sim\n"
    printf "Usage: %s [options]\n" ${0}
    printf " Options:\n"
    printf "  -h            Print this message\n"
    printf "  -l            List all available custom maps\n"
    printf "  -m <mapname>  Load a custom map\n"
    printf "  -r            Reset back to the default map\n"
    printf "  -z            Display a zenity dialog (gui)\n"
}

# Main
if [ ! "${1}" ]; then
    sms_usage
fi

while getopts ":hlm:rz" option; do
    case ${option} in
        h)
            sms_usage
            ;;
        l)
            sms_list
            ;;
        m)
            sms_load "${OPTARG}"
            ;;
        r)
            sms_unload
            ;;
        z)
            sms_dialog
            ;;
        :)
            printf "Missing argument for -%s ...\n" ${OPTARG}
            ;;
        *)
            printf "Invalid option -%s ...\n" ${OPTARG}
            ;;
    esac
done

shift $((OPTIND - 1))
if [ $# -gt 0 ]; then
    sms_usage
fi

exit 0
