#!/bin/bash

# Define the directory where your scripts are located
SCRIPTS_DIR="./"

# List all the available scripts
echo "Available scripts:"
echo "------------------"
scripts=($(ls "$SCRIPTS_DIR"))

# Display the list of scripts with numbers for selection
for ((i=0; i<${#scripts[@]}; i++)); do
    echo "$((i+1)). ${scripts[i]}"
done

# Prompt the user to select a script
echo -n "Enter the number of the script you want to run: "
read choice

# Validate user input
if [[ $choice =~ ^[0-9]+$ && $choice -ge 1 && $choice -le ${#scripts[@]} ]]; then
    selected_script="${scripts[choice-1]}"
    echo "Running $selected_script..."
    # Execute the selected script
    bash "$SCRIPTS_DIR/$selected_script"
else
    echo "Invalid selection. Exiting..."
    exit 1
fi
