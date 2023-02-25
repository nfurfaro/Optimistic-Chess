library rook;

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

pub fn rook_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

    // TODO: Implement me !
pub fn rook_validation(board: Board, move: Move) {}
