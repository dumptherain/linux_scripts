#!/usr/bin/env python3
import tkinter as tk
from tkinter import filedialog, messagebox
import subprocess
import os

def add_folder():
    folder = filedialog.askdirectory(title="Select an input folder")
    if folder:
        if folder not in input_listbox.get(0, tk.END):
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

def run_processing():
    input_folders = list(input_listbox.get(0, tk.END))
    output_folder = output_entry.get()
    if not input_folders:
        messagebox.showerror("Error", "No input folders selected!")
        return
    if not output_folder:
        messagebox.showerror("Error", "No output folder selected!")
        return

    for folder in input_folders:
        # Run your globally available script 'exrtomp4.sh' in each folder
        cmd = "exrtomp4.sh"
        try:
            result = subprocess.run(cmd, shell=True, cwd=folder,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE,
                                    text=True)
            if result.returncode != 0:
                messagebox.showerror("Error", f"Processing failed in:\n{folder}\nError: {result.stderr}")
                continue

            # Look for the line indicating the output file name.
            output_file = None
            for line in result.stdout.splitlines():
                if "Output filename will be" in line:
                    parts = line.split("Output filename will be")
                    if len(parts) > 1:
                        output_file = parts[1].strip()
                        break

            # Fallback: look for any .mp4 file in the folder.
            if output_file is None:
                mp4_files = [f for f in os.listdir(folder) if f.endswith(".mp4")]
                if mp4_files:
                    mp4_files.sort(key=lambda x: os.path.getmtime(os.path.join(folder, x)), reverse=True)
                    output_file = mp4_files[0]

            if output_file:
                src = os.path.join(folder, output_file)
                dest = os.path.join(output_folder, output_file)
                os.rename(src, dest)
            else:
                messagebox.showerror("Error", f"Could not determine output file in:\n{folder}")
        except Exception as e:
            messagebox.showerror("Error", f"Error processing {folder}:\n{e}")

    messagebox.showinfo("Info", "Processing complete!")

# Build the GUI
root = tk.Tk()
root.title("Batch Sequence Processor")

# Frame for input folders list
frame_inputs = tk.Frame(root)
frame_inputs.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)

tk.Label(frame_inputs, text="Input Folders:").pack(anchor=tk.W)
input_listbox = tk.Listbox(frame_inputs, width=80, height=6)
input_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
scrollbar = tk.Scrollbar(frame_inputs, orient=tk.VERTICAL, command=input_listbox.yview)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
input_listbox.config(yscrollcommand=scrollbar.set)

# Buttons to add or remove folders via dialog
frame_input_buttons = tk.Frame(root)
frame_input_buttons.pack(padx=10, pady=5)
tk.Button(frame_input_buttons, text="Add Folder", command=add_folder).pack(side=tk.LEFT, padx=5)
tk.Button(frame_input_buttons, text="Remove Folder", command=remove_folder).pack(side=tk.LEFT, padx=5)

# Frame for pasted folder input
frame_paste = tk.Frame(root)
frame_paste.pack(padx=10, pady=5, fill=tk.BOTH)
tk.Label(frame_paste, text="Paste folder paths (one per line):").pack(anchor=tk.W)
paste_text = tk.Text(frame_paste, width=80, height=3)
paste_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
tk.Button(frame_paste, text="Add Pasted Folders", command=add_pasted_folders).pack(side=tk.LEFT, padx=5)

# Frame for output folder selection
frame_output = tk.Frame(root)
frame_output.pack(padx=10, pady=5, fill=tk.X)
tk.Label(frame_output, text="Output Folder:").pack(side=tk.LEFT)
output_entry = tk.Entry(frame_output, width=60)
output_entry.pack(side=tk.LEFT, padx=5)
tk.Button(frame_output, text="Browse", command=select_output_folder).pack(side=tk.LEFT)

# Run and Exit buttons
frame_run = tk.Frame(root)
frame_run.pack(padx=10, pady=10)
tk.Button(frame_run, text="Run", command=run_processing).pack(side=tk.LEFT, padx=5)
tk.Button(frame_run, text="Exit", command=root.quit).pack(side=tk.LEFT, padx=5)

root.mainloop()

