# ttcd

A cross platform Pomodoro timer written in Python. The application provides configurable focus and break timers and records completed sessions to a JSON file. A history chart can be displayed showing the number of focus sessions per day.

## Requirements

- Python 3.10+
- `matplotlib` (for history chart)

Install dependencies with:

```bash
pip install matplotlib
```

## Running

Execute the application using Python:

```bash
python3 main.py
```

The GUI allows you to configure focus, short break and long break durations. After each timer completes a record is appended to `pomodoro_log.json`. Use the **Show History** button to display a chart of focus sessions per day.
