//----------------------
// Contract interfaces
//----------------------

use rock_paper::models::{Direction};

#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(self: @TContractState, rps: u8);
    fn move(self: @TContractState, dir: Direction);
    fn cleanup(self: @TContractState);
}
