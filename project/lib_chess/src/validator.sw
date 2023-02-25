library validator;

// dep bitboard;
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
dep pawn;
dep king;
dep queen;
dep rook;
dep bishop;
dep knight;

// use bitboard::BitBoard;
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
use piece_types::pawn::*;
use pawn::*;
use king::*;
use queen::*;
use rook::*;
use bishop::*;
use knight::*;

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

fn threat_map(bits: BitMap, color: Color) -> BitMap {
    pawn_attacks(bits, color) | bishop_attacks(bits, color) | rook_attacks(bits, color) | knight_attacks(bits, color) | queen_attacks(bits, color) | king_attacks(bits, color)
}

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

// validation
    // check metadata
    // src & dest must be valid squares
    // if source and dest are of type Square, they can only be valid squares!
    // assert(move.source.is_in_bounds() && move.dest.is_in_bounds());
    // is move a castle? check rights & legality

    //   - is piece pinned? (May still be able to move (sliding pice on pinning ray, pawn en passant if diagonal pinner))
    //   - blocking pieces on squares between?

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

pub fn validate_move() {
    // check game.statehash to know if we need to generate bitboards or not
}
