library bishop;

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

pub fn bishop_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

pub fn bishop_validation(board: Board, move: Move) {}
