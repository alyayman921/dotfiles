#!/bin/bash

# Simple ffmpeg test script
# Edit INPUT_FILE to test different files

INPUT_FILE="/home/aly/Storage/Records/League of Legends/1.mp4"
OUTPUT_FILE="/home/aly/Storage/Records/League of Legends/1.mkv"

echo "Input file: $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"
echo ""

# Check if input exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Input file not found!"
    exit 1
fi

echo "Input file size: $(ls -lh "$INPUT_FILE" | awk '{print $5}')"
echo ""

# Remove existing output file
if [ -f "$OUTPUT_FILE" ]; then
    echo "Removing existing output file..."
    rm "$OUTPUT_FILE"
fi

echo "Running ffmpeg (this will take a while)..."
echo ""

# Run ffmpeg with AV1
ffmpeg -i "$INPUT_FILE" \
    -c:v libsvtav1 \
    -crf 30 \
    -r 30 \
    -c:a libmp3lame \
    "$OUTPUT_FILE" \
    -y

echo ""
echo "================================"

if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "✓ SUCCESS!"
    echo "Output file size: $SIZE"
else
    echo "❌ FAILED - No output file created"
    exit 1
fi
