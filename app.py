import os
import psutil
from datetime import datetime
from flask import Flask, jsonify, request

app = Flask(__name__)

# Simulated in-memory database for events
event_log = []

# Mock function for a database check
def check_db_connection():
    # In a real app, you'd try to ping RDS/PostgreSQL here
    return True

@app.route('/')
def dashboard():
    """Main landing page showing instance identity."""
    instance_id = os.environ.get('INSTANCE_ID', 'Localhost')
    az = os.environ.get('AZ_NAME', 'Unknown-AZ')
    return jsonify({
        "service": "VoyageView-Event-Monitor",
        "instance": instance_id,
        "availability_zone": az,
        "message": f"Hello! I am serving requests from {az}",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health_check():
    """L7 Health Check: Returns 200 if system is healthy, 503 if not."""
    health_status = {"status": "healthy", "checks": {}}
    
    # 1. Check System Vitals (Fails if CPU is pinned > 95%)
    cpu_usage = psutil.cpu_percent()
    health_status["checks"]["cpu"] = f"{cpu_usage}%"
    if cpu_usage > 95:
        health_status["status"] = "degraded"

    # 2. Check Database Connectivity
    if check_db_connection():
        health_status["checks"]["database"] = "up"
    else:
        health_status["status"] = "unhealthy"

    # 3. Memory Check
    mem_usage = psutil.virtual_memory().percent
    health_status["checks"]["memory"] = f"{mem_usage}%"

    # Set HTTP status code based on health
    code = 200 if health_status["status"] == "healthy" else 503
    return jsonify(health_status), code

@app.route('/events', methods=['GET', 'POST'])
def handle_events():
    """Monitor events: POST to log an event, GET to view them."""
    if request.method == 'POST':
        data = request.json
        event_log.append({
            "timestamp": datetime.now().isoformat(),
            "event": data.get("event", "generic_event"),
            "source_az": os.environ.get('AZ_NAME', 'unknown')
        })
        return jsonify({"msg": "Event recorded"}), 201
    
    return jsonify({"logged_events": event_log[-10:]}) # Return last 10 events

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)