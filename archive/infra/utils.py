import subprocess
import os
import time

def print_green(message):
    print(f"\033[92m{message}\033[0m")

def print_red(message):
    print(f"\033[91m{message}\033[0m")

def check_docker_daemon():
    try:
        subprocess.check_call(['docker', 'info'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        print_red("❌ Docker daemon is not running!")
        if "linux" in os.uname().sysname.lower():
            print_green("🔄 Attempting to start Docker...")
            subprocess.run(['sudo', 'systemctl', 'start', 'docker'])
            time.sleep(5)
            try:
                subprocess.check_call(['docker', 'info'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except subprocess.CalledProcessError:
                print_red("❌ Failed to start Docker. Please start Docker manually and re-run the script.")
                exit(1)
        else:
            print_red("⚠️ Please start Docker Desktop and re-run the script.")
            exit(1) 