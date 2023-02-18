library validator;

dep bitboard;
dep color;
dep bitmap;
dep board;
dep errors;
dep game;
dep move;
dep piece;
dep special;
dep square;
dep utils;

use bitboard::BitBoard;
use color::{BLACK, Color, WHITE};
use bitmap::*;
use board::Board;
use errors::ChessError;
use game::{Game, Status};
use move::Move;
use piece::{EMPTY, Piece};
use special::CastleRights;
use square::Square;
use utils::turn_on_bit;

/**

Square Numbering

56 57 58 59 60 61 62 63
48 49 50 51 52 53 54 55
40 41 42 43 44 45 46 47
32 33 34 35 36 37 38 39
24 25 26 27 28 29 30 31
16 17 18 19 20 21 22 23
08 09 10 11 12 13 14 15
00 01 02 03 04 05 06 07

0  0  0  1  0  0  0  0     3 and 59
0  0  0  0  0  0  0  0     3 % 8 =  3
0  0  0  0  0  0  0  0     59 % 8 = 3
0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0
0  0  0  1  0  0  0  0

0  0  0  0  0  0  0  0     24 and 31
0  0  0  0  0  0  0  0     24 / 8 = 4
0  0  0  0  0  0  0  0     31 / 8 = 4
0  0  0  0  0  0  0  0
1  0  0  0  0  0  0  1
0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0

0  0  0  0  0  0  0  0  << 17, << 10, >> 6, >> 10, >> 15, >> 17, << 6,  << 15,
0  0  0  0  0  0  0  0
0  0  0  x  0  x  0  0
0  0  x  0  0  0  x  0
0  0  0  0  K  0  0  0
0  0  x  0  0  0  x  0
0  0  0  x  0  x  0  0
K  0  0  0  0  0  0  0


  noWe         nort         noEa
        << 7   << 8   << 9
              \  |  /
  west  >> 1 <-  0 -> << 1  east
              /  |  \
        >> 9  >> 8    >> 7
  soWe         sout         soEa

*/
// fn squares_between(src: Square, dest: Square) -> Vec<Square> {
// find all the bit indexes between src and dest as a bitmap.
fn squares_between(src: Square, dest: Square) -> Option<u64> {
    let src_idx = src.to_index();
    let dest_idx = dest.to_index();

    // check that src & dest are points on a line
    if (src_idx % 8) == (dest_idx % 8) {
        let mut bitmap = 0;
        let mut i = src_idx + 8;
        while i < dest_idx {
            turn_on_bit(bitmap, i);
            i += 8;
        };
        Option::Some(bitmap)
    } else if (src_idx / 8) == (dest_idx / 8) {
        // squares are in the same rank
        let mut bitmap = 0;
        let mut i = src_idx + 1;
        while i < dest_idx {
            turn_on_bit(bitmap, i);
            i += 1;
        };
        Option::Some(bitmap)
    } else if file_delta(src, dest) == rank_delta(src, dest) {
        // squares are in the same diagonal or antidiagonal
        if src.rank() > dest.rank() {
            // northerly direction
            if src.file() > dest.file() {
                // NW dir, << 7
                let mut bitmap = 0;
                let mut i = src_idx + 7;
                while i < dest_idx {
                    turn_on_bit(bitmap, i);
                    i += 7;
                };
                Option::Some(bitmap)
            } else {
                // NE dir, << 9
                let mut bitmap = 0;
                let mut i = src_idx + 9;
                while i < dest_idx {
                    turn_on_bit(bitmap, i);
                    i += 9;
                };
                Option::Some(bitmap)
            }
        } else {
            // southerly direction
            if src.file() > dest.file() {
                // SW dir, >> 9
                let mut bitmap = 0;
                let mut i = src_idx - 7;
                while i > dest_idx {
                    turn_on_bit(bitmap, i);
                    i -= 7;
                };
                Option::Some(bitmap)
            } else {
                // NE dir, >> 7
                let mut bitmap = 0;
                let mut i = src_idx - 9;
                while i > dest_idx {
                    turn_on_bit(bitmap, i);
                    i -= 9;
                };
                Option::Some(bitmap)
            }
        }
    } else {
        // squares are not points on a line
        Option::None
    }
}

fn max(a: u64, b: u64) -> u64 {
    if a < b { a } else if b > a { b } else { a }
}

fn min(a: u64, b: u64) -> u64 {
    if b < a { b } else if a < b { a } else { a }
}

fn file_delta(src: Square, dest: Square) -> u64 {
    max(src.file(), dest.file()) - min(src.file(), dest.file())
}

fn rank_delta(src: Square, dest: Square) -> u64 {
    max(src.rank(), dest.rank()) - min(src.rank(), dest.rank())
}

fn is_legal_move(board: Board, move: Move) -> bool {
    let (color, piece) = board.read_square(move.source.to_index()).unwrap();
    match piece {
        Piece::Pawn => pawn_validation(board, move),
        Piece::Bishop => bishop_validation(board, move),
        Piece::Rook => rook_validation(board, move),
        Piece::Knight => knight_validation(board, move),
        Piece::Queen => queen_validation(board, move),
        Piece::King => king_validation(board, move),
    };
    true
}

// fn is_on_edge(bitmap: BitMap) -> bool {
//     (bitmap & EDGES) != BLANK
// }
// fn is_on_corner(bitmap: BitMap) -> bool {
//     (bitmap & CORNERS) != BLANK
// }
fn is_on_rank_1(bitmap: BitMap) -> bool {
    (bitmap & RANK_1) != BLANK
}

fn is_on_rank_8(bitmap: BitMap) -> bool {
    (bitmap & RANK_8) != BLANK
}

fn is_on_file_a(bitmap: BitMap) -> bool {
    (bitmap & FILE_A) != BLANK
}

fn is_on_file_h(bitmap: BitMap) -> bool {
    (bitmap & FILE_H) != BLANK
}

fn threat_map(bits: BitBoard, color: Color) -> BitMap {
    pawn_attacks(bits, color) | bishop_attacks(bits, color) | rook_attacks(bits, color) | knight_attacks(bits, color) | queen_attacks(bits, color) | king_attacks(bits, color)
}

fn pawn_attacks(bits: BitBoard, color: Color) -> BitMap {
    match color {
        Color::Black => ((bits.black_pawns >> 7) & !FILE_H) | ((bits.black_pawns >> 9) & !FILE_A),
        Color::White => ((bits.white_pawns << 7) & !FILE_H) | ((bits.white_pawns << 9) & !FILE_A),
        _ => revert(0),
    }
}

fn bishop_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

fn rook_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

fn knight_attacks(bits: BitBoard, color: Color) -> BitMap {
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
        let rank_1 = is_on_rank_1(knights);
        let file_a = is_on_file_a(knights);
        let rank_8 = is_on_rank_8(knights);
        let file_h = is_on_file_h(knights);

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

fn queen_attacks(bits: BitBoard, color: Color) -> BitMap {
    // TODO: Implement me !
    BLANK
}

fn king_attacks(bits: BitBoard, color: Color) -> BitMap {
    let king_bit = match color {
        Color::Black => bits.kings & bits.black,
        Color::White => bits.kings & bits.white,
    };

    let rank_1 = is_on_rank_1(king_bit);
    let file_a = is_on_file_a(king_bit);
    let rank_8 = is_on_rank_8(king_bit);
    let file_h = is_on_file_h(king_bit);

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


/** Shared legality checks:
    - a player can only move their own piece
    assert(own_color_moved());
    - a player can only capture a piece of the opposite color
    assert(opposite_color_captured();

*/
fn pawn_validation(board: Board, move: Move) {
    // get pawn possible moves
    // add en_passant
    let white_pawn_attacks = pawn_attacks(board.bitboard, WHITE);
    let black_pawn_attacks = pawn_attacks(board.bitboard, BLACK);

    // if File == File::A  {
                // there can be no captures to the west
            // }
            // if File == File::H {
                // there can be no captures to the east
            // }
            // if (Rank == Rank::2 && color == WHITE) ||  (Rank == Rank::7 && color == BLACK){
                // pawn can move 1 or 2 spaces FORWARD (forward is relative !)
            // }
            // if (Rank == Rank::2 && color == BLACK) ||  (Rank == Rank::7 && color == WHITE){
                // promotion is possible
            // }
    assert(move.dest.to_index() == move.source.to_index() + 7 || move.dest.to_index() == move.source.to_index() + 8 || move.dest.to_index() == move.source.to_index() + 9 || move.dest.to_index() == move.source.to_index() + 15 || move.dest.to_index() == move.source.to_index() + 16 || move.dest.to_index() == move.source.to_index() + 17);

    // if move is a pawn promotion:
    //   - check that pawn can legally move to the 8th rank.
    //   - check that selected replacement piece has been captured already.
    if let Option::Some(p) = move.promotion {
        // check that selected replacement piece has been captured already.
        let color = board.side_to_move();
        if let Color::Black = color {
            match p {
                Piece::Queen => assert(board.bitboard.queens & board.bitboard.black == BLANK),
                Piece::Rook => assert((board.bitboard.rooks & board.bitboard.black).enumerate_bits().unwrap() < 2),
                Piece::Bishop => assert((board.bitboard.bishops & board.bitboard.black).enumerate_bits().unwrap() < 2),
                Piece::Knight => assert((board.bitboard.knights & board.bitboard.black).enumerate_bits().unwrap() < 2),
                _ => (),
            }
        } else {
            // color is white
            match p {
                Piece::Queen => assert(board.bitboard.queens & board.bitboard.white == BLANK),
                Piece::Rook => assert((board.bitboard.rooks & board.bitboard.white).enumerate_bits().unwrap() < 2),
                Piece::Bishop => assert((board.bitboard.bishops & board.bitboard.white).enumerate_bits().unwrap() < 2),
                Piece::Knight => assert((board.bitboard.knights & board.bitboard.white).enumerate_bits().unwrap() < 2),
                _ => (),
            }
        }
    };
    // check en_passant target:
    // if move.is_en_passant() {
        // check legality
        // check metadata for en_passant target, ensure match with move.dest
    // };
}

fn bishop_validation(board: Board, move: Move) {}

    // TODO: Implement me !
fn rook_validation(board: Board, move: Move) {}

    // TODO: Implement me !
fn knight_validation(board: Board, move: Move) {}

    // TODO: Implement me !
fn queen_validation(board: Board, move: Move) {}

    // TODO: Implement me !
fn king_validation(board: Board, move: Move) {}

pub fn validate(game: Game, move: Move) -> bool {
    let side_to_move = game.board.side_to_move();
    let (color_moved, piece) = game.board.read_square(move.source.to_index()).unwrap();
    assert(color_moved == side_to_move);

    match game.status {
        Status::Active => (),
        _ => return false,
    };

    true
}

// validation
    // check metadata
    // src & dest must be valid squares
    // if source and dest are of type Square, they can only be valid squares!
    // assert(move.source.is_in_bounds() && move.dest.is_in_bounds());
    // is move a castle? check rights & legality

    //   - is piece pinned? (May still be able to move (sliding pice on pinning ray, pawn en passant if diagonal pinner))
    //   - blocking pieces on squares between?

// here we do the easy checks common to all pieces and colors
pub fn verify_move(game: Game, move: Move) {
    // TODO: Implement me !
    // perform the cheapest checks first!
    // perform minimal verification that a move is at least well formed.
    // this can be done incrementally while building a Move struct from the abi method params.

    // don't bother validating moves if game is over
    match game.status {
        Status::Active => (),
        _ => (),// TODO
    };

    // check full-move counter.
    // At 50, the game automatically ends in a draw, unless the 50th move is a checkmate
    match game.board.full_move_counter() {
        49 => (), // this is the last move !
        _ => (),
    };

    let turn_to_move = game.board.side_to_move();

    // check if king is in check early as possible, and reset as needed each move.
    assert(!game.board.king_in_check(turn_to_move));

    // is there a piece on src?
    match game.board.read_square(move.source.to_index()) {
        Option::None => revert(0),
        Option::Some((color, piece)) => {
            // does it belong to current side to move?
            if color != turn_to_move {
               revert(0);
            };
        },
    }

    // if piece on dest, is it the opposite color?
    match game.board.read_square(move.source.to_index()) {
        Option::None => (),
        Option::Some((color, piece)) => {
              assert(color != turn_to_move);
        },
    }

    // check metadata for castling rights
    if move.is_castling() {
        // check legality
        let result = game.board.castling_rights();
        if result.is_ok() {
            match result.unwrap()[turn_to_move.to_u64()] {
                CastleRights::NoRights => revert(0),
                _ => (), // TODO: decide how to check move aligns with rights
            };
        };
    };
}

pub fn validate_move() {
    // check game.statehash to know if we need to generate bitboards or not
}

// write to storage