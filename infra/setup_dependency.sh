#!/bin/bash

set -x

# Define the virtual environment name
export VENV_NAME=".hireko_venv"

# Create the virtual environment using python3
python3 -m venv $VENV_NAME

# Activate the virtual environment
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
    source $VENV_NAME/bin/activate
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    source $VENV_NAME/Scripts/activate
else
    echo "Unsupported OS"
    exit 1
fi

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
else
    echo "No requirements.txt found. Skipping dependencies installation."
fi

# Generate a VS Code settings.json file to use the virtual environment
mkdir -p .vscode
cat > .vscode/settings.json <<EOL
{
    "python.defaultInterpreterPath": "\${workspaceFolder}/$VENV_NAME/bin/python3"
}
EOL

echo "Python virtual environment setup complete!"
echo "To activate, run: source $VENV_NAME/bin/activate"
