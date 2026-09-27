import psutil
import socket
import json
import subprocess
import re
import time

VM_HOST = "gamedata.home.arpa"
TCP_PORT = 5000
UDP_PORT = 5001
GAME_LIST = ["Dolphin.exe"]


def get_cpu_data():
    return {
        "usage_percent": psutil.cpu_percent(interval=1),
        "physical_cores": psutil.cpu_count(logical=False),
        "logical_cores": psutil.cpu_count(logical=True),
        "frequency_mhz": psutil.cpu_freq().current,
    }

def get_memory_data():
    memory = psutil.virtual_memory()

    return {
        "used_percent": memory.percent,
        "used_mb": memory.used / (1024 ** 2),
        "available_mb": memory.available / (1024 ** 2)
    }

def get_network_data():
    network = psutil.net_io_counters()

    return {
        "bytes_sent": network.bytes_sent,
        "bytes_received": network.bytes_recv,
        "packets_sent": network.packets_sent,
        "packets_received": network.packets_recv
    }

def find_process():

    processes = []

    for process in psutil.process_iter(["pid", "name"]):
        try:
            processes.append({
                "pid": process.info["pid"],
                "process_name": process.info["name"]
            })

        except (
            psutil.NoSuchProcess,
            psutil.AccessDenied
        ):
            pass

    for process in processes:
        for game in GAME_LIST:
            if (game == process["process_name"]):
                return {
                    "running": True,
                    "process_name": process["process_name"],
                    "pid": process["pid"]
                }

    return {
        "running": False,
        "process_name": None,
        "pid": None
    }

def get_gpu_data():

    result = subprocess.run(
        [
            "typeperf",
            r"\GPU Engine(*)\Utilization Percentage",
            "-sc",
            "1"
        ],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        return None

    pattern = r"[0-9][0-9]\.[0-9]{6}"

    match = re.search(pattern, result.stdout)

    if match:
        utilization = float(match.group())

    
    return {
        "usage_percent": None,
        "temperature_c": None,
        "memory_used_mb": None,
        "memory_total_mb": None
    }

def get_temperature_data():

    temperatures = psutil.sensors_temperatures()

    return temperatures



def collect_telemetry():

    return {
        "timestamp": time.time(),

        "cpu": get_cpu_data(),

        "temperature": None,

        "memory": get_memory_data(),

        "gpu": get_gpu_data(),

        "network": get_network_data(),

        "game": find_process(),

        "performance": {
            "fps": None,
            "frame_time_ms": None
        }
    }

# ====================================================================
# TCP
# ====================================================================
tcp_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

tcp_client.connect((VM_HOST,TCP_PORT))

print("Connected to C++ Server!")


# ======================================================================
# UDP
# ======================================================================
udp_client = socket.socket(
    socket.AF_INET,
    socket.SOCK_DGRAM
)

while True:
    
    telemetry = collect_telemetry()
    json_data = json.dumps(telemetry)

    udp_client.sendto(
        json_data.encode("utf-8"),
        (VM_HOST, UDP_PORT)
        )

    print("Data sent: ", json_data)
    time.sleep(1)
    


tcp_client.close()
udp_client.close()


