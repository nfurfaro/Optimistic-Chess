library knight;

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

pub fn knight_attacks(bits: BitBoard, color: Color) -> BitMap {
    let mut attacks = BitMap::from_u64(EMPTY);
    let knights = match color {
        Color::Black => bits.knights & bits.black,
        Color::White => bits.knights & bits.white,
    };
    let mut num = 0;
    match knights.enumerate_bits().unwrap() {
        0 => return BLANK,
        1 => num = 1,
        2 => num = 2,
        _ => revert(0),
    };
    if num == 1 {
        let rank_1 = knights.is_on_rank_1();
        let file_a = knights.is_on_file_a();
        let rank_8 = knights.is_on_rank_8();
        let file_h = knights.is_on_file_h();

        // convert a bitmap of n knights into n bitmaps with 1 knight each
        let knight_maps = knights.scatter();
        if knight_maps.is_none() {
            return BitMap::from_u64(EMPTY);
        };
        let unwrapped = knight_maps.unwrap();
        let mut i = 0;
        while i < unwrapped.len() {
            let bits = unwrapped.get(i).unwrap();
            attacks = match (rank_1, file_a, rank_8, file_h) {
                // a1 corner: can attack 2 squares
                (true, true, false, false) => attacks | (bits << 17) | (bits << 10),
                // a8 corner: can attack 2 squares
                (false, true, true, false) => attacks | (bits >> 6) | (bits >> 15),
                // h8 corner: can attack 2 squares
                (false, false, true, true) => attacks | (bits >> 10) | (bits >> 17),
                // h1 corner: can attack 2 squares
                (true, false, false, true) => attacks | (bits << 6) | (bits << 15),
                // rank 1: can attack 4 squares
                (true, false, false, false) => attacks | (bits << 17) | (bits << 10) | (bits << 6) | (bits << 15),
                // file a: can attack 4 squares
                (false, true, false, false) => attacks | (bits << 17) | (bits << 10) | (bits >> 6) | (bits >> 15),
                // rank 8: can attack 4 squares
                (false, false, true, false) => attacks | (bits >> 6) | (bits >> 15) | (bits >> 10) | (bits >> 17),
                // file h: can attack 4 squares
                (false, false, false, true) => attacks | (bits >> 10) | (bits >> 17) | (bits << 6) | (bits << 15),
                // knight is not on an edge square: can attack 8 squares
                (false, false, false, false) => attacks | (bits << 17) | (bits << 10) | (bits >> 6) | (bits >> 10) | (bits >> 15) | (bits >> 17) | (bits << 6) | (bits << 15),
                _ => revert(0),
            };
        }
    }

    attacks
}

    // TODO: Implement me !
pub fn knight_validation(board: Board, move: Move) {}
