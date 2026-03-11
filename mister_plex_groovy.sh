#!/bin/bash

if [[ -f "/media/fat/Scripts/MiSTer_SAM_on.sh" ]]; then
	source /media/fat/Scripts/MiSTer_SAM_on.sh --source-only
	if [ "$(ps aux | grep -ice "[M]iSTer_SAM_on")" -ne 0 ]; then
		/media/fat/Scripts/MiSTer_SAM_on.sh stop
	fi
else
    echo "Error: MiSTer SAM not installed."
    exit 1
fi


# Prompt user for Plex URL
echo "Please paste the full Plex URL (from 'Get XML' option):"
read -r PLEX_URL

# Validate the URL
if [[ ! "$PLEX_URL" =~ ^https?:// ]]; then
    echo "Error: Invalid URL. Please provide a valid Plex URL."
    exit 1
fi



# Function to extract value from URL using `sed`
extract_value() {
    echo "$1" | sed -n "s/.*[?&]$2=\([^&]*\).*/\1/p"
}

# Extract metadata ID and token using `sed`
METADATA_ID=$(echo "$PLEX_URL" | sed -n 's#.*/metadata/\([0-9]\+\).*#\1#p')
URL_TOKEN=$(extract_value "$PLEX_URL" "X-Plex-Token")

# Verify metadata ID and token
if [[ -z "$METADATA_ID" ]]; then
    echo "Error: Unable to extract metadata ID from the URL."
    exit 1
fi

if [[ -z "$URL_TOKEN" ]]; then
    echo "Error: Unable to extract Plex token from the URL."
    exit 1
fi

# Generate MPlayer command
TRANSCODE_URL="http://$(echo "$PLEX_URL" | cut -d'/' -f3)/video/:/transcode/universal/start.m3u8?X-Plex-Platform=Chrome&copyts=1&mediaIndex=0&offset=0&path=%2Flibrary%2Fmetadata%2F$METADATA_ID&videoResolution=$VIDEO_RES&maxVideoBitrate=1000&X-Plex-Token=$URL_TOKEN&directStream=0&directPlay=0"

echo "Generated Transcode URL:"
echo "$TRANSCODE_URL"
# Hide login prompt
echo -e '\033[2J' > /dev/tty1
# Hide blinking cursor
echo 0 > /sys/class/graphics/fbcon/cursor_blink
echo -e '\033[?17;0;0c' > /dev/tty1 

groovy_cfg="/media/fat/config/Groovy.cfg"
echo "0000 0000 0000 0010 0000 0000 0000 0000" | xxd -r -p > "$groovy_cfg"



echo load_core /media/fat/mp4_play/mp4_player.rbf > /dev/MiSTer_cmd
sleep 5
/media/fat/mp4_play/mp4_play "$TRANSCODE_URL" -t 2
