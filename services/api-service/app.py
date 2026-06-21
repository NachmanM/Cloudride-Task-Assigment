from flask import Flask, jsonify
import time
import datetime

app = Flask(__name__)

START_TIME = time.time()


@app.route("/")
@app.route("/api/health")
def health():
    return jsonify({"status": "healthy"})


@app.route("/api/hello")
def hello():
    return jsonify({
        "message": "Hello from the API service!",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "service": "api-service",
    })


@app.route("/api/status")
def status():
    uptime = round(time.time() - START_TIME, 2)
    return jsonify({
        "status": "ok",
        "uptime_seconds": uptime,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
