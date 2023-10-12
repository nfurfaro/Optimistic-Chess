library;

// mod board;
// mod color;
// mod piece;

use ::board::Board;
use ::color::{BLACK, Color, WHITE};
use std::{call_frames::contract_id, hash::keccak256};

// TODO: add methods to convert to & from a status code, i.e:
// 0, 1, 2, 3
pub enum Status {
    Standby: (),   // at least 1 player has not deposited bond
    Active: (),    // game on
    Stalemate: (), // stalemate, game is a draw
    Checkmate: (), // game has a winner
}

pub struct Game {
    player_black: Identity,
    player_white: Identity,
    bonds_payed: [bool; 2],
    salt: u64, // allows multiple games between P1 & P2 to have unique IDs.
    board: Board,
    status: Status,
    winner: Option<Identity>,
    statehash: b256,
}

impl Game {
    pub fn new(
        p1: Identity,
        p2: Identity,
        p1_bond_payed: bool,
        p2_bond_payed: bool,
        salt: u64,
        status: Status,
    ) -> Game {
        let board = Board::new();
        let hash = keccak256((board.piecemap, board.metadata));
        Game {
            player_black: p2,
            player_white: p1,
            bonds_payed: [p2_bond_payed, p1_bond_payed],
            salt: salt,
            board: Board::new(),
            status: status,
            winner: Option::None,
            statehash: hash,
        }
    }

    pub fn id(self) -> b256 {
        keccak256((
            self.player_white,
            self.player_black,
            self.salt,
            contract_id(),
        ))
    }

    pub fn hash_state(self) -> b256 {
        keccak256((self.board.piecemap, self.board.metadata))
    }
}

// #[test()]
// fn test_new_game() {
//     let game = game::new();
//     assert(game.player_1 == );
//     assert(game.player_2 == );
//     assert(game.game_id.unwrap().is_none());
//     assert(game.board.position == Position::new());
//     assert(game.board.bitboard == BitStack::new());
//     if let Status::Ready = game.status {
//         assert(true);
//     } else {
//         assert(false)
//     };
// }
