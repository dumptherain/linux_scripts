#!/bin/bash

# Prompt the user for the directory path
read -p "Enter the path of the directory to organize: " directoryPath

# Check if the provided directory path is valid
if [[ ! -d "$directoryPath" ]]; then
    echo "The directory does not exist. Try again!"
    exit 1
fi

# Ask the user for their sorting preferences
echo "Enter your sorting preferences:"
echo "Y - Year"
echo "M - Month"
echo "D - Day"
echo "You can combine them (e.g., YMD, YM, YD)."
read -p "Your choice: " sortingPreference

# Validate sorting preference
if ! [[ "$sortingPreference" =~ ^[YMD]+$ ]]; then
    echo "Invalid choice. Please enter a combination of Y, M, and D."
    exit 1
fi

# Get all files and folders in the specified directory, safely handling names with spaces
find "$directoryPath" -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d $'\0' item; do
    # Determine the LastWriteTime
    lastWriteTime=$(stat -c %y "$item" | cut -d' ' -f1)
    
    # Extract the year, month, and day from the LastWriteTime
    year=$(date -d "$lastWriteTime" +%Y)
    month=$(date -d "$lastWriteTime" +%m)
    day=$(date -d "$lastWriteTime" +%d)
    
    # Initialize the base path as the directory path
    basePath="$directoryPath"
    
    # Append year, month, day to the path based on user preference
    [[ "$sortingPreference" == *Y* ]] && basePath="$basePath/$year"
    [[ "$sortingPreference" == *M* ]] && basePath="$basePath/$year-$month"
    [[ "$sortingPreference" == *D* ]] && basePath="$basePath/$year-$month-$day"
    
    # Create the target directory if it doesn't exist
    if [[ ! -d "$basePath" ]]; then
        mkdir -p "$basePath"
    fi
    
    # Define the destination path
    destination="$basePath/$(basename "$item")"
    
    # Move the item to the target directory if it's not already there
    if [[ "$item" != "$destination" ]] && [[ ! -e "$destination" ]]; then
        mv "$item" "$destination"
    else
        echo "Warning: An item with the name '$(basename "$item")' already exists in '$basePath' or is being processed. Skipping..."
    fi
done

echo "Files and folders have been organized according to your preference."

