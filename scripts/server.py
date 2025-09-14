from fastapi import FastAPI, Request
from typing import List, Dict
from fastapi.responses import JSONResponse
import json, base64, time

app = FastAPI()

# Global memory store
latest_players: List[Dict[str, str]] = []
last_request_time: float = time.time()  # Store the timestamp of the last valid call

@app.get("/server/info/{data}")
async def receive_player_list(data: str):
    global latest_players, last_request_time
    try:
        players_data = json.loads(base64.b64decode(data))
        latest_players = []
        for p in players_data:
            if isinstance(p, dict) and "PlayerName" in p and "PlayerId" in p:
                latest_players.append({
                    "PlayerName": str(p["PlayerName"]),
                    "PlayerId": str(p["PlayerId"])
                })
            else:
                return JSONResponse(content={"error": "Invalid player structure"}, status_code=400)
        last_request_time = time.time()  # Update timestamp
        return {"status": "Player list received", "playerCount": len(latest_players)}
    except Exception as e:
        return JSONResponse(content={"error": "Invalid data", "details": str(e)}, status_code=400)

@app.get("/info")
async def get_player_info():
    return {
        "playerCount": len(latest_players),
        "players": latest_players
    }

@app.get("/health")
async def health_check():
    if time.time() - last_request_time > 30:
        return JSONResponse(content={"status": "stale"}, status_code=500)
    return {"status": "ok"}