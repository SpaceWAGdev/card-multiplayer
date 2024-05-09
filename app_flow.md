# Message Format:

JSON
{
    "type": "Control" / "Sync" / "Message"
    "match": 4 Chars
    "user": UUID
    "control-operation" : "JOIN_MATCH" / "CREATE_MATCH" / "LEAVE_MATCH" / "CONFIRM_MATCH"
    "control-arguments": JSON
    "sync-data": Godot Bytes
    "message": String
}