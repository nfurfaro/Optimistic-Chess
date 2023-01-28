contract;

use chess_abi::Chess;
use lib_chess::{board::Board, errors::ChessError, game::{Game, Status}, move::Move};
use std::{
    call_frames::{
        contract_id,
        msg_asset_id,
    },
    constants::{ZERO_B256, BASE_ASSET_ID},
    context::msg_amount,
    hash::keccak256,
};

storage {
    // should bond be a config time const ?
    bond: u64 = 42,
    // mapping of game_id => Game. game_ids are globally unique
    games: StorageMap<b256, Game> = StorageMap {},
    // mapping of Player1 => Player2 => match_number
    salts: StorageMap<(Identity, Identity), u64> = StorageMap {},
}

impl Chess for Contract {
    #[storage(read, write)]
    #[payable]
    fn start_new_game(player1: Identity, player2: Identity, bond: Option<u64>) -> b256 {
        // increment the previous game salt
        let salt = storage.salts.get((player1, player2)).unwrap() + 1;
        storage.salts.insert((player1, player2), salt);

        let status = match bond {
            // free play, no bond required.
            Option::None => Status::Active,
            // bond required to activate gameplay.
            Option::Some(v) => Status::Standby,
        };

        let required_bond = storage.bond;
        let mut bond1 = false;
        let mut bond2 = false;
        let asset = msg_asset_id();
        let amount = msg_amount();

        require(asset == BASE_ASSET_ID, ChessError::Unimplemented);

        if bond.is_some() {
            let unwrapped = bond.unwrap();
            if amount == unwrapped {
                bond1 = true;
            };
            if amount == unwrapped * 2 {
                bond1 = true;
                bond2 = true;
            };
        }

        let mut game = Game::new(player1, player2, bond1, bond2, salt, status);
        game.statehash = game.hash_state();
        let game_id = game.id();
        storage.games.insert(game_id, game);

        game_id
    }

    // #[storage(write)]
    // fn post_bond(game_id: b256);
    // #[storage(read)]
    // fn move(move: Move);
    // #[storage(read, write)]
    // fn move_from_state(nonce: u64, sig: B512);
    // #[storage(read)]
    // fn game(game_id: b256) -> Game;
    // fn game_id(player1: Identity, player2: Identity, nonce: u64) -> b256;
    // #[storage(read, write)]
    // fn claim_winnings(game_id: b256);
}

// Private
// fn generate_game_id(player1: Identity, player2: Identity, game_number: u64) -> b256 {
//     keccak256((player1, player2, game_number, contract_id()))
// }
// // TODO: decide if this should include game.status by testing adversarially
// fn hash_state(piecemap: b256, metadata: u64,) -> b256 {
//     keccak256((piecemap, metadata))
// }


// should be implemented in the contract as a private function used by both move & move_from_state
fn commit_move() {
    // write to storage
    // emit event
}
