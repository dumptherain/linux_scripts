#!/bin/bash

# Define the directory where your scripts are located
SCRIPTS_DIR="./scripts"

# Parse command-line options
if [[ "$1" == "--monitor" ]]; then
    flag_script="monitor"
fi

# If the monitor flag is set, execute monitor.sh
if [ -n "$flag_script" ]; then
    if [ -x "$SCRIPTS_DIR/$flag_script.sh" ]; then
        echo "Running $flag_script.sh..."
        bash "$SCRIPTS_DIR/$flag_script.sh"
    else
        echo "Script $flag_script not found or not executable. Exiting..."
        exit 1
    fi
    exit 0
fi

# List all the available scripts
echo "Available scripts:"
echo "------------------"
scripts=($(ls "$SCRIPTS_DIR"))

# Display the list of scripts with numbers for selection
for ((i=0; i<${#scripts[@]}; i++)); do
    echo "$((i+1)). ${scripts[i]}"
done

# Prompt the user to select a script
echo -n "Enter the number of the script you want to run or the name of the script (without extension): "
read choice

# Check if user input is a number
if [[ $choice =~ ^[0-9]+$ ]]; then
    # Validate the numerical input
    if ((choice >= 1 && choice <= ${#scripts[@]})); then
        selected_script="${scripts[choice-1]}"
        echo "Running $selected_script..."
        # Execute the selected script
        bash "$SCRIPTS_DIR/$selected_script"
    else
        echo "Invalid selection. Exiting..."
        exit 1
    fi
else
    # Check if user input matches a script name (without extension)
    selected_script="$choice.sh"
    if [[ -x "$SCRIPTS_DIR/$selected_script" ]]; then
        echo "Running $selected_script..."
        # Execute the selected script
        bash "$SCRIPTS_DIR/$selected_script"
    else
        echo "Script $choice not found or not executable. Exiting..."
        exit 1
    fi
fi
