#[cfg(test)]
mod tests {
    use core::option::OptionTrait;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::{ContractAddress, contract_address_try_from_felt252};
    use debug::PrintTrait;

    // import world dispatcher

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import model structs
    // the lowercase structs hashes generated by the compiler

    use rock_paper::models::{
        position, player_at_position, rps_type, energy, player_id, player_address, Position,
        PlayerAtPosition, RPSType, Energy, Direction, Vec2, PlayerID, PlayerAddress, GAME_DATA_KEY,
        GameData
    };

    use rock_paper::actions::actions;

    use rock_paper::interface::{IActions, IActionsDispatcher, IActionsDispatcherTrait};

    // import config
    use rock_paper::config::{INITIAL_ENERGY, RENEWED_ENERGY, MOVE_ENERGY_COST};


    // Note: Spawn world helper function
    // 1. deploys world contract
    // 2. deploys actions contract
    // 3. sets models within world
    // 4. Returns caller, world dispatcher and actions dispatcher for use in testing
    fn spawn_world() -> (ContractAddress, IWorldDispatcher, IActionsDispatcher) {
        let caller = starknet::contract_address_const::<'satyam'>();
        starknet::testing::set_caller_address(caller);
        starknet::testing::set_contract_address(caller);

        let mut models = array![
            player_at_position::TEST_CLASS_HASH,
            position::TEST_CLASS_HASH,
            energy::TEST_CLASS_HASH,
            rps_type::TEST_CLASS_HASH,
            player_id::TEST_CLASS_HASH,
            player_address::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('actions', actions::TEST_CLASS_HASH.try_into().unwrap());

        (caller, world, IActionsDispatcher { contract_address })
    }

    #[test]
    #[available_gas(20000000000)]
    fn spawn_test() {
        let (caller, world, actions_) = spawn_world();
        actions_.spawn('r');
        let player_id = get!(world, caller, (PlayerID)).player_id;
        assert(1 == player_id, 'incorrect id');

        // Get player from id
        let (position, rps_type, energy) = get!(world, player_id, (Position, RPSType, Energy));
        assert(position.x > 0, 'incorrect position.x');
        assert(position.y > 0, 'incorrect position.y');
        assert('r' == rps_type.rps, 'incorrect rps');
        assert(energy.amt == INITIAL_ENERGY, 'incorrect enegery');
    }

    #[test]
    #[available_gas(20000000000)]
    fn dead_test() {
        let (caller, world, actions_) = spawn_world();
        actions_.spawn('r');
        let player_id = get!(world, caller, (PlayerID)).player_id;

        let (position, rps_type, energy) = get!(world, player_id, (Position, RPSType, Energy));
        // kill player
        actions::player_dead(world, player_id);

        // player models should be 0
        let (position, rps_type, energy) = get!(world, player_id, (Position, RPSType, Energy));
        // 'energy'.print();
        // energy.amt.print();
        assert(position.x == 0, 'incorrect position.x');
        assert(position.y == 0, 'incorrect position.y');
        assert(energy.amt == 0, 'incorrect energy');
    }

    #[test]
    #[available_gas(2000000000)]
    fn random_spawn_test() {
        let (caller, world, actions_) = spawn_world();
        actions_.spawn('r');

        let pos_p1 = get!(world, get!(world, caller, (PlayerID)).player_id, (Position));
        let caller = starknet::contract_address_const::<'shivam'>();
        starknet::testing::set_contract_address(caller);
        actions_.spawn('r');

        let pos_p2 = get!(world, get!(world, caller, (PlayerID)).player_id, (Position));

        assert(pos_p1.x != pos_p2.x, 'spawn pos.x same');
        assert(pos_p1.y != pos_p2.y, 'spawn pos.y same');
    }

    #[test]
    #[available_gas(200000000)]
    fn moves_test() {
        let (caller, world, actions_) = spawn_world();
        actions_.spawn('r');

        let player_id = get!(world, caller, (PlayerID)).player_id;
        assert(player_id == 1, 'Incorrect id');

        let (spawn_pos, spawn_energy) = get!(world, player_id, (Position, Energy));

        'Spawn energy'.print();
        spawn_energy.amt.print();
        actions_.move(Direction::Up);

        let (pos, energy) = get!(world, player_id, (Position, Energy));
        'After move'.print();
        energy.amt.print();

        // assert player moved and energy was deducted
        assert(energy.amt == (spawn_energy.amt - MOVE_ENERGY_COST), 'incorrect energy');
        assert(spawn_pos.x == pos.x, 'incorrect position.x');
        assert(pos.y == spawn_pos.y - 1, 'incorrect position.y')
    }

    #[test]
    #[available_gas(2000000000)]
    fn player_at_position_test() {
        let (caller, world, actions_) = spawn_world();
        actions_.spawn('r');

        let player_id = get!(world, caller, (PlayerID)).player_id;

        // Get player position
        let Position{x, y, player_id } = get!(world, player_id, Position);

        assert(
            actions::player_at_position(world, x, y) == player_id, 'player should be at position'
        );

        actions_.move(Direction::Up);

        // Player shouldn't be at the old position
        assert(actions::player_at_position(world, x, y) == 0, 'player should not be at pos');

        // Get player's new position
        let Position{x, y, player_id } = get!(world, player_id, Position);

        // Player should be at new position
        assert(actions::player_at_position(world, x, y) == player_id, 'player should be at pos');
    }

    #[test]
    #[available_gas(2000000000)]
    fn encounter_test() {
        let (caller, world, actions_) = spawn_world();

        assert(actions::encounter_win('r', 'p') == false, 'R v P should lose');
        assert(actions::encounter_win('r', 's') == true, 'R v S should Win');
        assert(actions::encounter_win('p', 's') == false, 'P v S should lose');
        assert(actions::encounter_win('p', 'r') == true, 'P v R should win');
        assert(actions::encounter_win('s', 'r') == false, 'S v R should lose');
        assert(actions::encounter_win('s', 'p') == true, 'S v P should win');
    }

    #[test]
    #[available_gas(2000000000)]
    #[should_panic()]
    fn encounter_rock_tie_panic() {
        actions::encounter_win('r', 'r');
    }

    #[test]
    #[available_gas(200000000000)]
    fn test_cleanup() {
        let (caller, world, _action) = spawn_world();

        let num_players = 30;
        let mut i = 0;
            let caller1 = starknet::contract_address_const::<'test'>();
            starknet::testing::set_contract_address(caller1);
            _action.spawn('r');

            let caller1 = starknet::contract_address_const::<'test1'>();
            starknet::testing::set_contract_address(caller1);
            _action.spawn('p');

            let caller1 = starknet::contract_address_const::<'test2'>();
            starknet::testing::set_contract_address(caller1);
            _action.spawn('s');

            let caller1 = starknet::contract_address_const::<'test3'>();
            starknet::testing::set_contract_address(caller1);
            _action.spawn('r');

            // set caller back to original caller
            starknet::testing::set_contract_address(caller);
            _action.cleanup();

            let mut game_data = get!(world, GAME_DATA_KEY, (GameData));
            assert(game_data.number_of_players == 0, 'not cleaned up');
    }
}
