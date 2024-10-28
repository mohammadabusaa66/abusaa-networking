#!/bin/bash
# ===================================================================================================================================
# abusaa-networking.sh
#
# Copyright (c) 2024 Eng. Mohammad Motasem Abusaa
#
# This script is a tool for paginated display, selection, and installation of QEMU images based on .yml templates.
# It features automated installation with CPU monitoring, dependency checks, and a retry mechanism for failed installations.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ===================================================================================================================================

# Define color codes
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

# Display logo with color
echo -e "${CYAN}====================================================================================================================================="
echo -e "=                                                                                                                                   ="
echo -e "=                                                                                                                                   ="
echo -e "=                                                                                                                                   ="
echo -e "=                                                          ${WHITE}ABUSAA-NETWORKING${CYAN}                                                        ="
echo -e "=                                                                                                                                   ="
echo -e "=                                                                                                                                   ="
echo -e "=                                                                                                                                   ="
echo -e "=====================================================================================================================================${RESET}"

# Directory containing .yml files
TEMPLATE_DIR="/opt/unetlab/html/templates/intel/"
LOG_FILE="qemu_installation_log_$(date +'%Y%m%d_%H%M%S').log"
CPU_THRESHOLD=70               # Maximum CPU usage threshold to avoid overload
COOLDOWN_INTERVAL=5            # Interval (in seconds) to wait if CPU is too high
PAUSE_BETWEEN_INSTALLS=10       # Pause between installations to reduce CPU strain
MAX_RETRIES=3                   # Maximum retry attempts for failed installations

# Function to check and install ishare2 if not present
check_and_install_ishare2() {
    if ! command -v ishare2 >/dev/null 2>&1; then
        echo -e "${YELLOW}ishare2 is not installed. Installing now...${RESET}"
        wget -O /usr/sbin/ishare2 https://raw.githubusercontent.com/ishare2-org/ishare2-cli/main/ishare2 && chmod +x /usr/sbin/ishare2
        
        # Run ishare2 once to complete setup, simulating user pressing "Enter" for prompts
        yes '' | ishare2
        if command -v ishare2 >/dev/null 2>&1; then
            echo -e "${GREEN}ishare2 installed successfully.${RESET}"
        else
            echo -e "${RED}Failed to install ishare2. Aborting.${RESET}"
            exit 1
        fi
    fi
}

# Check dependencies and install ishare2 if missing
check_and_install_ishare2
command -v top >/dev/null 2>&1 || { echo -e "${RED}top command is required but it's not installed. Aborting.${RESET}"; exit 1; }

# Function to monitor CPU usage
check_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
    echo "$cpu_usage"
}

# Log messages with timestamp and color
log_message() {
    local message="$1"
    echo -e "${CYAN}$(date): ${RESET}${WHITE}$message${RESET}" | tee -a "$LOG_FILE"
}

# Function to display a menu of available .yml files with descriptions
show_menu() {
    echo -e "${BLUE}Enter a keyword to filter descriptions (or press Enter to show all): ${RESET}"
    read -p "> " keyword
    keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')

    while true; do
        echo -e "${GREEN}Available Options:${RESET}"
        echo "---------------------------------------"

        # Check if there are any .yml files in the directory
        yml_files=($(ls "$TEMPLATE_DIR"*.yml 2>/dev/null))
        if [ ${#yml_files[@]} -eq 0 ]; then
            log_message "${RED}No .yml files found in $TEMPLATE_DIR.${RESET}"
            exit 1
        fi

        # Arrays for descriptions and corresponding filenames
        descriptions=()
        valid_files=()
        declare -A unique_descriptions

        # Extract descriptions and apply the keyword filter
        for file in "${yml_files[@]}"; do
            description=$(grep -m 1 "^description:" "$file" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            description_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')

            # Skip files without a description or those that don’t match the keyword
            if [ -n "$description" ] && [[ "$description_lower" == *"$keyword"* ]] && [ -z "${unique_descriptions[$description_lower]}" ]; then
                descriptions+=("$description")
                valid_files+=("$file")
                unique_descriptions[$description_lower]=1
            fi
        done
        unset unique_descriptions

        if [ ${#descriptions[@]} -eq 0 ]; then
            log_message "${RED}No .yml files with descriptions matching '$keyword' found in $TEMPLATE_DIR.${RESET}"
            exit 1
        fi

        # Display the descriptions in a list format
        for i in "${!descriptions[@]}"; do
            printf "${YELLOW}%2d. %s${RESET}\n" "$((i+1))" "${descriptions[$i]}"
        done
        echo -e "${YELLOW} 0. Exit${RESET}"
        echo

        # Prompt user to select a file
        echo -e "${BLUE}Enter the number of the description you want to select (all to install all or 0 to exit):${RESET}"
        read -p "> " choice

        if [[ "$choice" == "all" ]]; then
            log_message "${GREEN}You selected to install all images matching the descriptions.${RESET}"
            read -p "Are you sure you want to proceed? (y/n): " confirm
            if [[ "$confirm" != "y" ]]; then
                log_message "${YELLOW}Installation aborted by user.${RESET}"
                exit 0
            fi
            for i in "${!valid_files[@]}"; do
                filename=$(basename "${valid_files[$i]}" .yml)
                log_message "${CYAN}Installing images for: ${descriptions[$i]}${RESET}"
                search_and_install_images "$filename" "${descriptions[$i]}"
            done
            log_message "${GREEN}All images installed.${RESET}"
            break
        fi

        # Validate input
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt ${#descriptions[@]} ]; then
            log_message "${RED}Invalid choice. Please enter a number between 0 and ${#descriptions[@]}, or type 'all'.${RESET}"
            continue
        fi

        # Exit if the user chooses 0
        if [ "$choice" -eq 0 ]; then
            log_message "${CYAN}Exiting.${RESET}"
            break
        fi

        selected_file="${valid_files[$((choice-1))]}"
        filename=$(basename "$selected_file" .yml)
        log_message "${CYAN}You selected: $filename - ${descriptions[$((choice-1))]}${RESET}"

        # Confirm installation
        read -p "Do you want to install images for $filename? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            log_message "${YELLOW}Installation aborted for $filename by user.${RESET}"
            continue
        fi

        search_and_install_images "$filename" "${descriptions[$((choice-1))]}"
        echo -e "${CYAN}Returning to menu...${RESET}"
        echo
    done
}

# Function to search for QEMU images and install them
search_and_install_images() {
    local prefix="$1"
    local description="$2"

    log_message "${CYAN}Searching for QEMU images for: $description${RESET}"
    
    search_output=$(ishare2 search qemu "$prefix-")
    echo "$search_output" | tee -a "$LOG_FILE"
    image_count=$(echo "$search_output" | grep -c "^[0-9]")

    log_message "${GREEN}$image_count QEMU images found for: $description${RESET}"
    ids=$(echo "$search_output" | awk '/^[0-9]+/ {print $1}')
    
    if [ -z "$ids" ]; then
        log_message "${RED}No QEMU images found for prefix: $prefix-${RESET}"
        return
    fi

    for id in $ids; do
        attempt=1
        while [ "$attempt" -le "$MAX_RETRIES" ]; do
            cpu_usage=$(check_cpu_usage)
            log_message "${YELLOW}Current CPU usage: ${cpu_usage}%${RESET}"
            while [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; do
                log_message "${RED}High CPU usage detected (${cpu_usage}%). Waiting for CPU usage to decrease...${RESET}"
                sleep "$COOLDOWN_INTERVAL"
                cpu_usage=$(check_cpu_usage)
                log_message "${YELLOW}Rechecking CPU usage: ${cpu_usage}%${RESET}"
            done

            log_message "${CYAN}Installing QEMU image with ID: $id (Attempt $attempt)${RESET}"
            if ishare2 pull qemu "$id"; then
                log_message "${GREEN}Successfully installed QEMU image with ID $id.${RESET}"
                break
            else
                log_message "${RED}Failed to install QEMU image with ID $id. Attempt $attempt of $MAX_RETRIES.${RESET}"
                ((attempt++))
                sleep "$COOLDOWN_INTERVAL"
            fi
        done

        if [ "$attempt" -gt "$MAX_RETRIES" ]; then
            log_message "${RED}Max retries reached. Skipping QEMU image with ID $id.${RESET}"
        fi

        log_message "${YELLOW}Pausing for $PAUSE_BETWEEN_INSTALLS seconds before the next installation...${RESET}"
        sleep "$PAUSE_BETWEEN_INSTALLS"
    done
}

# Run the menu function
show_menu
