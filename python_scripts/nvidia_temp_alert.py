#!/usr/bin/python3

# This is the nvidia temp checker with prioity pop-up window that you have always been looking for.

import subprocess
import re
import tkinter as tk

def get_gpu_temperature():
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=temperature.gpu', '--format=csv,noheader,nounits'],
                                stdout=subprocess.PIPE, text=True)

        # Extract temperature from the output
        temperature = int(re.search(r'\d+', result.stdout).group())

        return temperature
    except Exception as e:
        print(f"Error: {e}")
        return None

def check_gpu_temperature():
    temperature = get_gpu_temperature()

    if temperature is not None and temperature >= 50:
        popup_alert("GPU Temperature Warning", f"GPU temperature is {temperature}°C. It's above 90°C.")

    root.after(5000, check_gpu_temperature)

def popup_alert(title, message):
    global popup_window

    if popup_window is not None and tk.Toplevel.winfo_exists(popup_window):
        # Update existing window if it exists
        popup_window.title(title)
        popup_window.label.config(text=message)
    else:
        # Create a new window if it doesn't exist
        popup_window = tk.Toplevel(root)
        popup_window.title(title)
        popup_window.geometry("300x100")
        popup_window.label = tk.Label(popup_window, text=message, padx=20, pady=20)
        popup_window.label.pack(side="top", fill="both", expand=True)
        popup_window.focus_set()
        popup_window.grab_set()
        popup_window.lift()

popup_window = None

root = tk.Tk()
root.withdraw()  # Hide the root window

check_gpu_temperature()

root.mainloop()
