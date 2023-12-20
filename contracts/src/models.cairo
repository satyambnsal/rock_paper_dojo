use starknet::ContractAddress;
use debug::PrintTrait;

#[derive(Copy, Drop, Serde, Introspect)]
enum Direction {
    None,
    Left,
    Right,
    Up,
    Down,
}

impl DirectionIntoFelt252 of Into<Direction, felt252> {
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::None(()) => 0,
            Direction::Left(()) => 1,
            Direction::Right(()) => 2,
            Direction::Up(()) => 3,
            Direction::Down(()) => 4
        }
    }
}

const GAME_DATA_KEY: felt252 = 'game';

#[derive(Copy, Drop, Serde, Introspect)]
struct Vec2 {
    x: u32,
    y: u32
}

#[derive(Model, Copy, Drop, Serde)]
struct PlayerAtPosition {
    #[key]
    x: u8,
    #[key]
    y: u8,
    player_id: u8
}

#[derive(Model, Copy, Drop, Serde)]
struct Position {
    #[key]
    player_id: u8,
    x: u8,
    y: u8
}

#[derive(Model, Copy, Drop, Serde)]
struct RPSType {
    #[key]
    player_id: u8,
    rps: u8
}

#[generate_trait]
impl RPSTypeImpl of RPSTypeTrait {
    fn get_type(self: RPSType) -> u8 {
        self.rps
    }
}

#[derive(Model, Copy, Drop, Serde)]
struct Energy {
    #[key]
    player_id: u8,
    amt: u8
}

#[derive(Model, Copy, Drop, Serde)]
struct PlayerID {
    #[key]
    player: ContractAddress,
    player_id: u8
}


#[derive(Model, Copy, Drop, Serde)]
struct PlayerAddress {
    #[key]
    player_id: u8,
    player: ContractAddress
}

#[derive(Model, Copy, Drop, Serde)]
struct GameData {
    #[key]
    game: felt252,
    number_of_players: u8,
    available_ids: u256
}
