#!/bin/env python3
import asyncio
import websockets
from hashlib import md5

# Dictionary to store connected clients with their respective WebSocket objects
connected_clients = {}

async def server(websocket, path):
    print(f"Client connected: {websocket.remote_address}")
    # Add the new client to the dictionary of connected clients
    connected_clients[websocket.remote_address] = websocket
    last_msg_hash = None
    try:
        async for message in websocket:
            print(f"Received message from {websocket.remote_address}: {message}")

            # Echo the message back to every other connected client
            for client_address, client in connected_clients.items():
                if (
                    client_address != websocket.remote_address
                    and md5(message) != last_msg_hash
                ):
                    await client.send(message)
            last_msg_hash = md5(message)

    except websockets.exceptions.ConnectionClosedError as e:
        print(f"Connection closed with error: {e}")

    finally:
        print(f"Client disconnected: {websocket.remote_address}")

        # Remove the disconnected client from the dictionary
        del connected_clients[websocket.remote_address]


# Start the WebSocket server
start_server = websockets.serve(server, "localhost", 8080)

# Run the server indefinitely
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
