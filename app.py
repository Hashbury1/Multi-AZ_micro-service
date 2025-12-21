import os
import requests
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

def get_aws_metadata():
    metadata_url = os.environ.get("ECS_CONTAINER_METADATA_URI_V4")
    if not metadata_url:
        return "Unknown-AZ", "Localhost"

    try:
        # Ask the ECS Agent for Task metadata
        response = requests.get(f"{metadata_url}/task", timeout=2)
        data = response.json()
        
        # Pull the AZ and the Task ARN (or ID)
        az = data.get("AvailabilityZone", "Unknown-AZ")
        # Task ARN looks like: arn:aws:ecs:us-east-1:123:task/cluster/ID
        task_id = data.get("TaskARN", "Localhost").split('/')[-1]
        
        return az, task_id
    except Exception:
        return "Error-Fetching-AZ", "Error-Instance"

@app.route('/')
def home():
    az, instance_id = get_aws_metadata()
    return jsonify({
        "service": "VoyageView-Event-Monitor",
        "message": f"Hello! I am serving requests from {az}",
        "availability_zone": az,
        "instance": instance_id,
        "timestamp": datetime.now().isoformat()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)