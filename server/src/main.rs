use ws::listen;

struct Matchup {
    players: Vec<String>,
    round: i32
}

fn main() {
    if let Err(error) = listen("127.0.0.1:8080", |out| {
        // The handler needs to take ownership of out, so we use move
        move |msg| {
            // Handle messages received on this connection
            println!("Server got message '{}'. ", msg);
            
            // Use the out channel to send messages back
            out.send(msg)
        }
    }) {
        // Inform the user of failure
        println!("Failed to create WebSocket due to {:?}", error);
    }
}