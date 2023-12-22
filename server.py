import asyncio
import websockets

async def server(websocket, path):
    print(f"Client connected: {websocket.remote_address}")

    try:
        async for message in websocket:
            print(f"Received message from {websocket.remote_address}: {message}")

            # Echo the message back to the client
            await websocket.send(message)

    except websockets.exceptions.ConnectionClosedError as e:
        print(f"Connection closed with error: {e}")

    finally:
        print(f"Client disconnected: {websocket.remote_address}")

# Start the WebSocket server
start_server = websockets.serve(server, "localhost", 8765)

# Run the server indefinitely
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
