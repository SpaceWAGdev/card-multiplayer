# Match Creation
Client requests new match with b64-encoded name -> Server creates new match
Server returns confirmation with a match ID -> Client stores b64-encoded match name

# Opponent connects to specific match
Client sends request for match with b64-encoded name -> Server checks if match exists
Server returns confirmation with a match ID -> Client stores match id

# Matchmaking
Client A sends matchmaking request -> Server places client's address in a queue
Client B sends matchmaking request -> Server checks the matchmaking queue, creates a match with Client A and Client B with a random match ID if both clients are still alive
Server sends confirmation with the match ID to both clients -> Client stores match ID