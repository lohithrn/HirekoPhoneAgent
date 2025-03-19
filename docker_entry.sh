#!/bin/bash
set -e
set -x

#python3 test/app.py &

# Start SSH service
service ssh start

# Activate virtual environment
source .${venv_name}/bin/activate

nohup bash -c "python3 test/app.py" &
ps aux | grep 'app.py' &
ps aux | grep '[m]ain.py' &

python3 /app/src/main.py start &

tail -f /dev/null

