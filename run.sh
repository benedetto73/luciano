#!/bin/bash
set -e

echo "Building..."
swift build --configuration debug

echo "Launching app..."
# Run in background and bring to foreground
./.build/debug/PresentationGenerator &
APP_PID=$!

# Give it a moment to start
sleep 0.5

# Try to activate the app window
osascript -e 'tell application "System Events" to set frontmost of first process whose unix id is '$APP_PID' to true' 2>/dev/null || true

echo "App running with PID: $APP_PID"
echo "Press Ctrl+C to stop"

# Wait for the app
wait $APP_PID
