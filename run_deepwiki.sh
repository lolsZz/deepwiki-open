#!/bin/bash

# Run DeepWiki-Open script
# This script starts both the backend and frontend services for DeepWiki-Open

# Set the project directory
PROJECT_DIR="/home/osl/groundbreaking/deepwiki-open"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to display colored output
print_message() {
  local color=$1
  local message=$2
  case $color in
    "green") echo -e "\e[32m$message\e[0m" ;;
    "yellow") echo -e "\e[33m$message\e[0m" ;;
    "red") echo -e "\e[31m$message\e[0m" ;;
    *) echo "$message" ;;
  esac
}

# Check if .env file exists and has API keys
check_env_file() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    print_message "red" "Error: .env file not found!"
    print_message "yellow" "Creating a template .env file. Please edit it with your API keys."
    echo "GOOGLE_API_KEY=your_google_api_key" > "$PROJECT_DIR/.env"
    echo "OPENAI_API_KEY=your_openai_api_key" >> "$PROJECT_DIR/.env"
    echo "# OPENROUTER_API_KEY=your_openrouter_api_key" >> "$PROJECT_DIR/.env"
    return 1
  fi

  # Check if API keys are set
  if grep -q "your_google_api_key" "$PROJECT_DIR/.env" || grep -q "your_openai_api_key" "$PROJECT_DIR/.env"; then
    print_message "yellow" "Warning: It looks like you haven't set your API keys in the .env file."
    print_message "yellow" "Please edit $PROJECT_DIR/.env with your actual API keys."
    return 1
  fi

  return 0
}

# Start the backend server
start_backend() {
  print_message "green" "Starting DeepWiki backend server..."
  cd "$PROJECT_DIR" || exit 1
  source .venv/bin/activate
  python -m api.main &
  BACKEND_PID=$!
  print_message "green" "Backend server started with PID: $BACKEND_PID"
  sleep 3  # Give the backend time to start
}

# Start the frontend server
start_frontend() {
  print_message "green" "Starting DeepWiki frontend server..."
  cd "$PROJECT_DIR" || exit 1
  npm run dev &
  FRONTEND_PID=$!
  print_message "green" "Frontend server started with PID: $FRONTEND_PID"
}

# Main function
main() {
  print_message "green" "=== DeepWiki-Open Launcher ==="
  
  # Check if we're in the project directory
  if [ ! -d "$PROJECT_DIR" ]; then
    print_message "red" "Error: DeepWiki-Open directory not found at $PROJECT_DIR"
    exit 1
  fi

  # Check if virtual environment exists
  if [ ! -d "$PROJECT_DIR/.venv" ]; then
    print_message "yellow" "Virtual environment not found. Creating one..."
    cd "$PROJECT_DIR" || exit 1
    if command_exists uv; then
      uv venv
    else
      print_message "red" "Error: uv command not found. Please install uv first."
      exit 1
    fi
  fi

  # Check if dependencies are installed
  if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    print_message "yellow" "Node modules not found. Installing dependencies..."
    cd "$PROJECT_DIR" || exit 1
    npm install
  fi

  # Check if Python dependencies are installed
  if ! check_env_file; then
    print_message "yellow" "Please edit the .env file with your API keys and run this script again."
    exit 1
  fi

  # Start the servers
  start_backend
  start_frontend

  print_message "green" "DeepWiki-Open is now running!"
  print_message "green" "Access the web interface at: http://localhost:3000"
  print_message "yellow" "Press Ctrl+C to stop both servers"

  # Wait for user to press Ctrl+C
  trap 'print_message "yellow" "Stopping servers..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; print_message "green" "Servers stopped."; exit 0' INT
  wait
}

# Run the main function
main