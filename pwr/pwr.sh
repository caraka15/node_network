#!/bin/bash

SCRIPT_URL="https://raw.githubusercontent.com/caraka15/node_network/main/pwr/pwr-tools.sh"
TEMP_SCRIPT="/tmp/pwr_tools_temp.sh"

wget -q "$SCRIPT_URL" -O "$TEMP_SCRIPT" && chmod +x "$TEMP_SCRIPT" && "$TEMP_SCRIPT"

rm -f "$TEMP_SCRIPT"