#[dojo::contract]
mod actions {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use debug::PrintTrait;
    use cubit::f128::procgen::simplex3;
    use cubit::f128::types::FixedTrait;
    use cubit::f128::types::vec3::Vec3Trait;


    use rock_paper::interface::IActions;

    use rock_paper::models::{
        GAME_DATA_KEY, GameData, Direction, Vec2, Position, PlayerAtPosition, RPSType, Energy,
        PlayerID, PlayerAddress
    };

    use rock_paper::utils::next_position;
    use rock_paper::config;
    use integer::{u128s_from_felt252, U128sFromFelt252Result, u128_safe_divmod};

    const DOJO_WORLD_RESOURCE: felt252 = 0;

    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(self: @ContractState, rps: u8) {
            let world = self.world_dispatcher.read();
            let player = get_caller_address();
            let mut game_data = get!(world, GAME_DATA_KEY, (GameData));

            game_data.number_of_players += 1;

            set!(world, (game_data));

            assert(rps == 'r' || rps == 'p' || rps == 's', 'Only r,p, or s type allowed');

            let mut player_id = get!(world, player, (PlayerID)).player_id;

            if player_id == 0 {
                player_id = assign_player_id(world, game_data.number_of_players, player);
            } else {
                let pos = get!(world, player_id, (Position));
                clear_player_at_position(world, pos.x, pos.y);
            }

            set!(world, (RPSType { player_id, rps }));
            // assert(
            //     game_data.number_of_players < config::X_RANGE * config::Y_RANGE,
            //     'maximum players reached'
            // );

            let (x, y) = spawn_coords(world, player.into(), player_id.into());
            player_position_and_energy(world, player_id, x, y, config::INITIAL_ENERGY);
        }

        fn move(self: @ContractState, dir: Direction) {
            let world = self.world_dispatcher.read();
            let player = get_caller_address();

            let player_id = get!(world, player, (PlayerID)).player_id;
            let (pos, energy) = get!(world, player_id, (Position, Energy));

            clear_player_at_position(world, pos.x, pos.y);

            let Position{player_id, x, y } = next_position(pos, dir);

            let max_x: felt252 = config::ORIGIN_OFFSET.into() + config::X_RANGE.into();
            let max_y: felt252 = config::ORIGIN_OFFSET.into() + config::Y_RANGE.into();

            assert(
                x <= max_x.try_into().unwrap() && y < max_y.try_into().unwrap(), 'Out of bounds'
            );

            let adversary = player_at_position(world, x, y);

            let tile = tile_at_position(
                x - config::ORIGIN_OFFSET.into(), y - config::ORIGIN_OFFSET.into()
            );
            'tile'.print();
            tile.print();
            let mut move_energy_cost = config::MOVE_ENERGY_COST;
            if tile == 3 {
                move_energy_cost = move_energy_cost * 3;
            }

            assert(energy.amt >= move_energy_cost, 'Not enough energy');

            if adversary == 0 {
                player_position_and_energy(world, player_id, x, y, energy.amt - move_energy_cost);
            } else if encounter(world, player_id, adversary) {
                player_position_and_energy(
                    world, player_id, x, y, energy.amt + config::RENEWED_ENERGY
                );
            }
        }

        fn cleanup(self: @ContractState) {
            let world = self.world_dispatcher.read();
            let player = get_caller_address();

            assert(
                world.is_owner(get_caller_address(), DOJO_WORLD_RESOURCE), 'only owner can call'
            );

            let mut game_data = get!(world, GAME_DATA_KEY, (GameData));
            let mut i = game_data.number_of_players;
            game_data.number_of_players = 0;

            set!(world, (game_data));
            loop {
                if i > 20 {
                    break;
                }
                player_dead(world, i);
                i += 1;
            }
        }
    }

    // -----------------------------------
    // INTERNAL FUNCTIONS
    // -----------------------------------

    fn assign_player_id(world: IWorldDispatcher, num_players: u8, player: ContractAddress) -> u8 {
        let player_id = num_players;
        set!(world, (PlayerID { player, player_id }, PlayerAddress { player, player_id }));
        player_id
    }

    fn clear_player_at_position(world: IWorldDispatcher, x: u8, y: u8) {
        set!(world, (PlayerAtPosition { x, y, player_id: 0 }));
    }

    fn player_at_position(world: IWorldDispatcher, x: u8, y: u8) -> u8 {
        get!(world, (x, y), (PlayerAtPosition)).player_id
    }

    fn player_position_and_energy(world: IWorldDispatcher, player_id: u8, x: u8, y: u8, amt: u8) {
        set!(
            world,
            (
                PlayerAtPosition { x, y, player_id },
                Position { x, y, player_id },
                Energy { player_id, amt }
            )
        );
    }

    fn tile_at_position(x: u8, y: u8) -> u8 {
        let vec = Vec3Trait::new(
            FixedTrait::from_felt(x.into()) / FixedTrait::from_felt(config::MAP_AMPLITUDE.into()),
            FixedTrait::from_felt(0),
            FixedTrait::from_felt(y.into()) / FixedTrait::from_felt(config::MAP_AMPLITUDE.into())
        );

        let simplex_value = simplex3::noise(vec);

        let fixed_value = (simplex_value + FixedTrait::from_unscaled_felt(1))
            / FixedTrait::from_unscaled_felt(2);

        let value: u8 = FixedTrait::floor(fixed_value * FixedTrait::from_unscaled_felt(100))
            .try_into()
            .unwrap();

        if (value > 70) {
            return 3;
        } else if (value > 60) {
            return 2;
        } else if (value > 53) {
            return 1;
        } else {
            return 0;
        }
    }


    fn spawn_coords(world: IWorldDispatcher, player: felt252, mut salt: felt252) -> (u8, u8) {
        let mut x = 10;
        let mut y = 10;

        loop {
            let hash = pedersen::pedersen(player, salt);
            let rnd_seed = match u128s_from_felt252(hash) {
                U128sFromFelt252Result::Narrow(low) => low,
                U128sFromFelt252Result::Wide((high, low)) => low
            };

            let (rnd_seed, x_) = u128_safe_divmod(rnd_seed, config::X_RANGE.try_into().unwrap());
            let (rnd_seed, y_) = u128_safe_divmod(rnd_seed, config::Y_RANGE.try_into().unwrap());

            let x_: felt252 = x_.into();
            let y_: felt252 = y_.into();

            x = config::ORIGIN_OFFSET + x_.try_into().unwrap();
            y = config::ORIGIN_OFFSET + y_.try_into().unwrap();
            let occupied = player_at_position(world, x, y);
            if occupied == 0 {
                break;
            } else {
                salt += 1;
            }
        };
        (x, y)
    }

    fn encounter_win(player_type: u8, adversary_type: u8) -> bool {
        assert(adversary_type != player_type, 'Occupied by same type');
        if (player_type == 'r' && adversary_type == 's')
            || (player_type == 'p' && adversary_type == 'r')
            || (player_type == 's' && adversary_type == 'p') {
            return true;
        }
        false
    }

    // Handle player encounters
    // if the player dies return false
    // if the player kills the other player returns true
    fn encounter(world: IWorldDispatcher, player_id: u8, adversary_id: u8) -> bool {
        let player_type = get!(world, player_id, (RPSType)).rps;
        let adversary_type = get!(world, adversary_id, (RPSType)).rps;
        if encounter_win(player_type, adversary_type) {
            player_dead(world, adversary_id);
            true
        } else {
            player_dead(world, player_id);
            false
        }
    }

    fn player_dead(world: IWorldDispatcher, player_id: u8) {
        let pos = get!(world, player_id, (Position));
        let empty_player = contract_address_const::<0>();

        let player_id_felt: felt252 = player_id.into();

        let entity_keys = array![player_id_felt].span();
        let player = get!(world, player_id, (PlayerAddress)).player;
        let player_felt: felt252 = player.into();

        let mut layout = array![];
        world.delete_entity('PlayerID', array![player_felt].span(), layout.span());
        world.delete_entity('PlayerAddress', entity_keys, layout.span());

        set!(world, (PlayerID { player, player_id: 0 }));
        set!(world, (Position { player_id, x: 0, y: 0 }, RPSType { player_id, rps: 0 }));

        // Remove player components
        world.delete_entity('RPSType', entity_keys, layout.span());
        world.delete_entity('Position', entity_keys, layout.span());
        world.delete_entity('Energy', entity_keys, layout.span());
    }
}

