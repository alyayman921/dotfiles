#!/bin/bash

# Video Batch Converter - Bash wrapper
# Launches the PyQt6 GUI application

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/video_converter_qt.py"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed"
    echo "Install with: sudo apt install ffmpeg"
    exit 1
fi

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT"
    exit 1
fi

# Check if PyQt6 is installed
if ! python3 -c "import PyQt6" 2>/dev/null; then
    echo "Error: PyQt6 is not installed"
    echo "Install with: pip install PyQt6"
    exit 1
fi

# Run the Python application
python3 "$PYTHON_SCRIPT"
