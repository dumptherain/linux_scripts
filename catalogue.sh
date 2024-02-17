#!/bin/bash

# Prompt the user to enter the directory path
read -p "Enter the directory path to scan: " directoryPath

# Prompt the user to enter the name of the CSV file
read -p "Enter the name of the resulting CSV file (e.g., catalogue.csv): " csvFileName

# Set the CSV file path to be the same as the input directory
csvFilePath="${directoryPath}/${csvFileName}"

# Check if the directory exists
if [ ! -d "$directoryPath" ]; then
    echo "Directory does not exist: $directoryPath"
    exit 1
fi

# Create the CSV file and add the header row
echo '"Catalogue","Tags","Description"' > "$csvFilePath"

# Get all the subdirectories in the specified directory, add them to the CSV file
find "$directoryPath" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | \
while read folderName; do
    echo "\"$folderName\",," >> "$csvFilePath"
done

echo "Folder names have been exported to '$csvFilePath'"

