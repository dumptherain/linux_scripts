#!/usr/bin/env python3
import tkinter as tk
from tkinter import filedialog, messagebox
import tkinter.ttk as ttk
import subprocess
import os
import configparser

# --- Configuration handling ---
CONFIG_FILE = os.path.expanduser("~/.batch_tk_config.ini")
DEFAULT_SCRIPT_LOCATION = "/home/mini2/linux_scripts"

config = configparser.ConfigParser()
if os.path.exists(CONFIG_FILE):
    config.read(CONFIG_FILE)
    script_location = config.get("Settings", "script_location", fallback=DEFAULT_SCRIPT_LOCATION)
else:
    script_location = DEFAULT_SCRIPT_LOCATION

def save_config():
    config['Settings'] = {'script_location': script_entry.get()}
    with open(CONFIG_FILE, 'w') as configfile:
        config.write(configfile)

# --- Functions ---
def add_folder():
    folder = filedialog.askdirectory(title="Select an input folder")
    if folder and folder not in input_listbox.get(0, tk.END):
        input_listbox.insert(tk.END, folder)

def remove_folder():
    selected = input_listbox.curselection()
    if selected:
        input_listbox.delete(selected[0])

def add_pasted_folders():
    text = paste_text.get("1.0", tk.END)
    lines = text.splitlines()
    added = False
    for line in lines:
        folder = line.strip()
        if folder:
            if os.path.isdir(folder):
                if folder not in input_listbox.get(0, tk.END):
                    input_listbox.insert(tk.END, folder)
                    added = True
            else:
                messagebox.showwarning("Warning", f"Not a valid directory: {folder}")
    if added:
        paste_text.delete("1.0", tk.END)

def select_output_folder():
    folder = filedialog.askdirectory(title="Select an output folder")
    if folder:
        output_entry.delete(0, tk.END)
        output_entry.insert(0, folder)

def select_script_location():
    folder = filedialog.askdirectory(title="Select Script Location", initialdir=script_entry.get())
    if folder:
        script_entry.delete(0, tk.END)
        script_entry.insert(0, folder)
        save_config()

def run_processing():
    input_folders = list(input_listbox.get(0, tk.END))
    output_folder = output_entry.get()
    script_loc = script_entry.get()
    
    if not input_folders:
        messagebox.showerror("Error", "No input folders selected!")
        return
    if not output_folder:
        messagebox.showerror("Error", "No output folder selected!")
        return
    if not os.path.isdir(script_loc):
        messagebox.showerror("Error", "Script location is not a valid directory!")
        return

    # Build a list of commands based on selected checkboxes.
    commands = []
    if mp4_var.get():
        commands.append("exrtomp4.sh")
    if prores444_var.get():
        commands.append("exrtoprores444.sh")
    if prores422_var.get():
        commands.append("exrtoprores422.sh")
    
    if not commands:
        messagebox.showerror("Error", "No command selected! Please select at least one format.")
        return

    total_tasks = len(input_folders) * len(commands)
    progress_bar["maximum"] = total_tasks
    progress_bar["value"] = 0
    status_label.config(text="In Progress", fg="red")
    root.update_idletasks()

    task_count = 0
    for folder in input_folders:
        for cmd in commands:
            full_cmd = os.path.join(script_loc, cmd)
            try:
                result = subprocess.run(full_cmd, shell=True, cwd=folder,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE,
                                        text=True)
                if result.returncode != 0:
                    messagebox.showerror("Error", f"Processing failed in:\n{folder}\nCommand: {full_cmd}\nError: {result.stderr}")
                    # Continue to update progress even if a command fails.
                else:
                    # Look for the output filename as provided by the script.
                    output_file = None
                    for line in result.stdout.splitlines():
                        if "Output filename will be" in line:
                            parts = line.split("Output filename will be")
                            if len(parts) > 1:
                                output_file = parts[1].strip()
                                break

                    # Fallback: check for any .mp4 file.
                    if output_file is None:
                        mp4_files = [f for f in os.listdir(folder) if f.endswith(".mp4")]
                        if mp4_files:
                            mp4_files.sort(key=lambda x: os.path.getmtime(os.path.join(folder, x)), reverse=True)
                            output_file = mp4_files[0]

                    if output_file:
                        # Use the filename as returned by the script.
                        src = os.path.join(folder, output_file)
                        dest = os.path.join(output_folder, output_file)
                        os.rename(src, dest)
                    else:
                        messagebox.showerror("Error", f"Could not determine output file in:\n{folder}\nCommand: {full_cmd}")
            except Exception as e:
                messagebox.showerror("Error", f"Error processing {folder} with {full_cmd}:\n{e}")

            task_count += 1
            progress_bar["value"] = task_count
            root.update_idletasks()  # Ensure the progress bar updates

    status_label.config(text="Conversion Done", fg="green")
    progress_bar["value"] = 0  # Optionally reset the progress bar

# --- Build the GUI ---
root = tk.Tk()
root.title("Batch Sequence Processor")

# Input Folders List
frame_inputs = tk.Frame(root)
frame_inputs.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)
tk.Label(frame_inputs, text="Input Folders:").pack(anchor=tk.W)
input_listbox = tk.Listbox(frame_inputs, width=80, height=6)
input_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
scrollbar = tk.Scrollbar(frame_inputs, orient=tk.VERTICAL, command=input_listbox.yview)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
input_listbox.config(yscrollcommand=scrollbar.set)

# Buttons to Add/Remove Folders
frame_input_buttons = tk.Frame(root)
frame_input_buttons.pack(padx=10, pady=5)
tk.Button(frame_input_buttons, text="Add Folder", command=add_folder).pack(side=tk.LEFT, padx=5)
tk.Button(frame_input_buttons, text="Remove Folder", command=remove_folder).pack(side=tk.LEFT, padx=5)

# Pasted Folder Input
frame_paste = tk.Frame(root)
frame_paste.pack(padx=10, pady=5, fill=tk.BOTH)
tk.Label(frame_paste, text="Paste folder paths (one per line):").pack(anchor=tk.W)
paste_text = tk.Text(frame_paste, width=80, height=3)
paste_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
tk.Button(frame_paste, text="Add Pasted Folders", command=add_pasted_folders).pack(side=tk.LEFT, padx=5)

# Script Location Selection
frame_script = tk.Frame(root)
frame_script.pack(padx=10, pady=5, fill=tk.X)
tk.Label(frame_script, text="Script Location:").pack(side=tk.LEFT)
script_entry = tk.Entry(frame_script, width=60)
script_entry.pack(side=tk.LEFT, padx=5)
script_entry.insert(0, script_location)
tk.Button(frame_script, text="Browse", command=select_script_location).pack(side=tk.LEFT)

# Command Checkboxes
frame_command = tk.Frame(root)
frame_command.pack(padx=10, pady=5, fill=tk.X)
tk.Label(frame_command, text="Select Formats:").pack(anchor=tk.W)
mp4_var = tk.BooleanVar(value=True)
prores444_var = tk.BooleanVar(value=False)
prores422_var = tk.BooleanVar(value=False)
tk.Checkbutton(frame_command, text="exrtomp4.sh", variable=mp4_var).pack(anchor=tk.W)
tk.Checkbutton(frame_command, text="exrtoprores444.sh", variable=prores444_var).pack(anchor=tk.W)
tk.Checkbutton(frame_command, text="exrtoprores422.sh", variable=prores422_var).pack(anchor=tk.W)

# Output Folder Selection
frame_output = tk.Frame(root)
frame_output.pack(padx=10, pady=5, fill=tk.X)
tk.Label(frame_output, text="Output Folder:").pack(side=tk.LEFT)
output_entry = tk.Entry(frame_output, width=60)
output_entry.pack(side=tk.LEFT, padx=5)
tk.Button(frame_output, text="Browse", command=select_output_folder).pack(side=tk.LEFT)

# Run, Exit, and Status
frame_run = tk.Frame(root)
frame_run.pack(padx=10, pady=10)
tk.Button(frame_run, text="Run", command=run_processing).pack(side=tk.LEFT, padx=5)
tk.Button(frame_run, text="Exit", command=root.quit).pack(side=tk.LEFT, padx=5)
status_label = tk.Label(frame_run, text="", width=20)
status_label.pack(side=tk.LEFT, padx=10)

# Progress Bar
frame_progress = tk.Frame(root)
frame_progress.pack(padx=10, pady=5, fill=tk.X)
progress_bar = ttk.Progressbar(frame_progress, orient="horizontal", mode="determinate")
progress_bar.pack(fill=tk.X, expand=True)

root.mainloop()
