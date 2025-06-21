import tkinter as tk
from tkinter import messagebox
import json
from datetime import datetime
import os
from collections import defaultdict
import matplotlib.pyplot as plt

LOG_FILE = "pomodoro_log.json"


def log_session(session_type, start_time, end_time):
    data = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                data = []
    data.append({
        "type": session_type,
        "start_time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
    })
    with open(LOG_FILE, "w") as f:
        json.dump(data, f, indent=2)


class PomodoroApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Pomodoro")

        self.focus_minutes = tk.IntVar(value=25)
        self.short_minutes = tk.IntVar(value=5)
        self.long_minutes = tk.IntVar(value=15)

        self.time_left = 0
        self.timer_id = None
        self.session_type = None
        self.start_time = None

        self.create_widgets()

    def create_widgets(self):
        tk.Label(self.root, text="Focus (min)").grid(row=0, column=0)
        tk.Entry(self.root, textvariable=self.focus_minutes, width=5).grid(row=0, column=1)
        tk.Label(self.root, text="Short Break (min)").grid(row=1, column=0)
        tk.Entry(self.root, textvariable=self.short_minutes, width=5).grid(row=1, column=1)
        tk.Label(self.root, text="Long Break (min)").grid(row=2, column=0)
        tk.Entry(self.root, textvariable=self.long_minutes, width=5).grid(row=2, column=1)

        self.timer_label = tk.Label(self.root, text="00:00", font=("Helvetica", 24))
        self.timer_label.grid(row=3, column=0, columnspan=2, pady=10)

        tk.Button(self.root, text="Start Focus", command=lambda: self.start_timer("focus")).grid(row=4, column=0, sticky="ew")
        tk.Button(self.root, text="Start Short Break", command=lambda: self.start_timer("short_break")).grid(row=4, column=1, sticky="ew")
        tk.Button(self.root, text="Start Long Break", command=lambda: self.start_timer("long_break")).grid(row=5, column=0, sticky="ew")
        tk.Button(self.root, text="Stop", command=self.stop_timer).grid(row=5, column=1, sticky="ew")

        tk.Button(self.root, text="Show History", command=self.show_history).grid(row=6, column=0, columnspan=2, sticky="ew", pady=(10, 0))

    def start_timer(self, session_type):
        if self.timer_id is not None:
            return
        self.session_type = session_type
        minutes = {
            "focus": self.focus_minutes.get(),
            "short_break": self.short_minutes.get(),
            "long_break": self.long_minutes.get(),
        }[session_type]
        self.time_left = minutes * 60
        self.start_time = datetime.now()
        self.update_timer()

    def update_timer(self):
        minutes = self.time_left // 60
        seconds = self.time_left % 60
        self.timer_label.config(text=f"{minutes:02d}:{seconds:02d}")
        if self.time_left > 0:
            self.time_left -= 1
            self.timer_id = self.root.after(1000, self.update_timer)
        else:
            self.root.after_cancel(self.timer_id)
            self.timer_id = None
            end_time = datetime.now()
            log_session(self.session_type, self.start_time, end_time)
            messagebox.showinfo("Timer", f"{self.session_type.replace('_', ' ').title()} completed!")

    def stop_timer(self):
        if self.timer_id is not None:
            self.root.after_cancel(self.timer_id)
            self.timer_id = None
        self.timer_label.config(text="00:00")

    def show_history(self):
        if not os.path.exists(LOG_FILE):
            messagebox.showinfo("History", "No sessions recorded yet.")
            return
        with open(LOG_FILE, "r") as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                messagebox.showerror("Error", "Log file corrupted.")
                return
        counts = defaultdict(int)
        for entry in data:
            if entry["type"] == "focus":
                day = entry["start_time"][:10]
                counts[day] += 1
        if not counts:
            messagebox.showinfo("History", "No focus sessions recorded yet.")
            return
        days = sorted(counts.keys())
        values = [counts[d] for d in days]
        plt.figure(figsize=(8, 4))
        plt.bar(days, values)
        plt.xlabel("Date")
        plt.ylabel("Focus Sessions")
        plt.title("Focus Sessions per Day")
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()


if __name__ == "__main__":
    root = tk.Tk()
    app = PomodoroApp(root)
    root.mainloop()
