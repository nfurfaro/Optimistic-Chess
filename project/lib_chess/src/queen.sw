library queen;

dep bitboard;
dep bitmap;
dep color;
dep board;
dep move;

use bitboard::BitBoard;
use bitmap::{BitMap, BLANK};
use board::Board;
use color::*;
use move::Move;

pub fn queen_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

    // TODO: Implement me !
pub fn queen_validation(board: Board, move: Move) {}
