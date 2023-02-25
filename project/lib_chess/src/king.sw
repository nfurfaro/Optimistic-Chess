library king;

dep bitboard;
dep bitmap;
dep board;
dep color;
dep move;

use bitboard::BitBoard;
use bitmap::{BitMap, BLANK};
use board::Board;
use color::*;
use move::Move;

pub fn king_attacks(bits: BitBoard, color: Color) -> BitMap {
    let king_bit = match color {
        Color::Black => bits.kings & bits.black,
        Color::White => bits.kings & bits.white,
    };

    let rank_1 = king_bit.is_on_rank_1();
    let file_a = king_bit.is_on_file_a();
    let rank_8 = king_bit.is_on_rank_8();
    let file_h = king_bit.is_on_file_h();

    match (rank_1, file_a, rank_8, file_h) {
        // a1 corner: can attack 3 squares
        (true, true, false, false) => (king_bit << 8) | (king_bit << 9) | (king_bit << 1),
        // a8 corner: can attack 3 squares
        (false, true, true, false) => (king_bit >> 8) | (king_bit << 1) | (king_bit >> 7),
        // h8 corner: can attack 3 squares
        (false, false, true, true) => (king_bit >> 8) | (king_bit >> 9) | (king_bit >> 1),
        // h1 corner: can attack 3 squares
        (true, false, false, true) => (king_bit >> 1) | (king_bit << 7) | (king_bit << 8),
        // rank 1: can attack 5 squares
        (true, false, false, false) => (king_bit >> 1) | (king_bit << 7) | (king_bit << 8) | (king_bit << 9) | (king_bit << 1),
        // file a: can attack 5 squares
        (false, true, false, false) => (king_bit >> 8) | (king_bit << 8) | (king_bit << 9) | (king_bit << 1) | (king_bit >> 7),
        // rank 8: can attack 5 squares
        (false, false, true, false) => (king_bit >> 8) | (king_bit >> 9) | (king_bit >> 1) | (king_bit << 1) | (king_bit >> 7),
        // file h: can attack 5 squares
        (false, false, false, true) => (king_bit >> 8) | (king_bit >> 9) | (king_bit >> 1) | (king_bit << 7) | (king_bit << 8),
        // king is not on an edge square: can attack 8 squares
        (false, false, false, false) => (king_bit >> 8) | (king_bit >> 9) | (king_bit >> 1) | (king_bit << 7) | (king_bit << 8) | (king_bit << 9) | (king_bit << 1) | (king_bit >> 7),
        _ => revert(0),
    }
}

    // TODO: Implement me !
pub fn king_validation(board: Board, move: Move) {}
