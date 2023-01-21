library validator;

dep bitboard;
dep bitmaps;
dep board;
dep errors;
dep game;
dep move;
dep piece;
dep square;
dep utils;

use bitboard::BitBoard;
use bitmaps::*;
use board::Board;
use errors::ChessError;
use game::{Game, Status};
use move::Move;
use piece::Piece;
use square::Square;
// use utils::enumerate_bits;

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

noWe         nort         noEa
          +7    +8    +9
              \  |  /
  west    -1 <-  0 -> +1    east
              /  |  \
          -9    -8    -7
  soWe         sout         soEa

*/

// fn square_mask() -> u64 {}
fn file_delta() {}
fn rank_delta() {}

fn is_legal_move(board: Board, move: Move) -> bool {
    let (color, piece) = board.read_square(move.source.to_index());
    match piece {
        Piece::Pawn => pawn_validation(move),
        Piece::Bishop => bishop_validation(move),
        Piece::Rook => rook_validation(move),
        Piece::Knight => knight_validation(move),
        Piece::Queen => queen_validation(move),
        Piece::King => king_validation(move),
    };
    true
}

fn pawn_attacks(bits: BitBoard, color: u64) -> u64 {
    match color {
        BLACK => ((board.bitboard.black_pawns >> 7) & !FILE_H) | ((board.bitboard.black_pawns >> 9) & !FILE_A),
        WHITE => ((board.bitboard.white_pawns << 7) & !FILE_H) | ((board.bitboard.white_pawns << 9) & !FILE_A),
        _ => revert(0),
    }
}

fn is_on_edge(bitmap: u64) -> bool {
    (bitmap & EDGES) != 0
}

fn is_on_corner(bitmap: u64) -> bool {
    (bitmap & CORNERS) != 0
}

fn is_on_rank_1(bitmap: u64) -> bool {
    (bitmap & RANK_1) != 0
}

fn is_on_rank_8(bitmap: u64) -> bool {
    (bitmap & RANK_8) != 0
}

fn is_on_file_a(bitmap: u64) -> bool {
    (bitmap & FILE_A) != 0
}

fn is_on_file_h(bitmap: u64) -> bool {
    (bitmap & FILE_H) != 0
}

// this will determine valid king moves from the bitboard alone.
// if I use the Move here, this can be vastly simplified because it tells us exactly where the king starts from. Howeve, we may need this to tell us the opponents king attacks to generate a threat map, so it needs to be general purpose.
// fn king_attacks(bits: BitBoard, color: u64) -> u64 {
//     let king = bits.kings & bits.colors[color];
//     // TODO: filter out duplicates somehow
//     // ise match if possible
//     if is_on_edge(king) {
//         // king is on an edge and can attack at most 5 squares
//         // determine which edge
//         if is_on_rank_1(king) {
//             // king is on Rank 1
//             if is_on_file_a(king) {
//                 // king is on corner a1
//                 (king << 8) | (king << 9) | (king << 1)
//             } else if is_on_file_h(king) {
//                 // king is on corner h1
//                 (king >> 1) (king << 7) | (king << 8)
//             } else {
//                 // king is not on a corner
//                 (king >> 1) (king << 7) | (king << 8) | (king << 9) | (king << 1)
//             }
//         } else if is_on_file_a(king) {
//             // king is on File A
//             if is_on_rank_1(king) {
//                 // king is on corner a1
//                 (king << 8) | (king << 9) | (king << 1)

//             } else if is_on_rank_8(king) {
//                 // king is on corner a8
//                 (king >> 8) |(king << 1) | (king >> 7)
//             } else {
//                 // king is not on a corner
//                 (king >> 8) | (king << 8) | (king << 9) | (king << 1) | (king >> 7)
//             }
//         } else if is_on_rank_8(king) {
//             // king is on Rank 8
//             if is_on_file_a(king) {
//                 // king is on corner a8
//                 (king >> 8) |(king << 1) | (king >> 7)
//             } else if is_on_file_h(king) {
//                 // king is on corner h8
//                 (king >> 8) | (king >> 9) | (king >> 1)
//             } else {
//                 // king is not on a corner
//                 (king >> 8) | (king >> 9) | (king >> 1) | (king << 1) | (king >> 7)
//             }
//         } else  {
//             // king is on File H
//             if is_on_rank_1(king) {
//                 // king is on corner h1
//                 (king >> 1) (king << 7) | (king << 8)
//             } else if is_on_rank_8(king) {
//                 // king is on corner h8
//                 (king >> 8) | (king >> 9) | (king >> 1)
//             } else {
//                 // king is not on a corner
//                 (king >> 8) | (king >> 9) | (king >> 1) (king << 7) | (king << 8)
//             }
//         }
//     } else {
//         // king is on a non-edge square and can attack 8 squares
//         (king >> 8) | (king >> 9) | (king >> 1) (king << 7) | (king << 8) | (king << 9) | (king << 1) | (king >> 7)
//     }
// }

fn king_attacks(bits: BitBoard, color: u64) -> u64 {
    let king = bits.kings & bits.colors[color];
    let rank_1 = is_on_rank_1(king);
    let file_a = is_on_file_a(king);
    let rank_8 = is_on_rank_8(king);
    let file_h = is_on_file_h(king);

    match (rank_1, file_a, rank_8, file_h) {
        // a1 corner: can attack 3 squares
        (true, true, false, false) => (king << 8) | (king << 9) | (king << 1),
        // a8 corner: can attack 3 squares
        (false, true, true, false) => (king >> 8) |(king << 1) | (king >> 7),
        // h8 corner: can attack 3 squares
        (false, false, true, true) => (king >> 8) | (king >> 9) | (king >> 1),
        // h1 corner: can attack 3 squares
        (true, false, false, true) => (king >> 1) (king << 7) | (king << 8),
        // rank 1: can attack 5 squares
        (true, false, false, false) => (king >> 1) (king << 7) | (king << 8) | (king << 9) | (king << 1),
        // file a: can attack 5 squares
        (false, true, false, false) => (king >> 8) | (king << 8) | (king << 9) | (king << 1) | (king >> 7),
        // rank 8: can attack 5 squares
        (false, false, true, false) => (king >> 8) | (king >> 9) | (king >> 1) | (king << 1) | (king >> 7),
        // file h: can attack 5 squares
        (false, false, false, true) => (king >> 8) | (king >> 9) | (king >> 1) (king << 7) | (king << 8),
        // king is not on an edge square: can attack 8 squares
        (false, false, false, false) => (king >> 8) | (king >> 9) | (king >> 1) (king << 7) | (king << 8) | (king << 9) | (king << 1) | (king >> 7),
    }
}

/** Shared legality checks:
    - a player can only move their own piece
    assert(own_color_moved());
    - a player can only capture a piece of the opposite color
    assert(opposite_color_captured();

*/

fn pawn_validation(move: Move, board: Board) {
    // get pawn possible attacks
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

}

fn bishop_validation(move: Move) {}
fn rook_validation(move: Move) {}
fn knight_validation(move: Move) {}
fn queen_validation(move: Move) {}
fn king_validation(move: Move) {}

pub fn validate(game: Game, move: Move) -> bool {
    let side_to_move = game.board.side_to_move();
    let (color_moved, piece) = game.board.read_square(move.source.to_index());
    assert(color_moved == side_to_move);

    // generally, check metadata before checking move legality based on movement patterns, i.e: perform the cheapet checks first!
    // check game status ! don't bother validating moves if game is over
    match game.status {
        Status::Active => (),
        _ => return false,
    };

    // src & dest must be valid squares
    // if source and dest are of type Square, they can only be valid squares!
    // assert(move.source.is_in_bounds() && move.dest.is_in_bounds());
    // if move is a pawn promotion:
    //   - check that pawn can legally move to the 8th rank.
    //   - check that selected replacement piece has been captured already.
    if let Option::Some(p) = move.promotion {
            // check that selected replacement piece has been captured already.
        match p {
            Piece::Queen => assert(game.board.bitboard.queens & game.board.bitboard.colors[side_to_move] == 0),
            Piece::Rook => assert(u64::enumerate_bits(game.board.bitboard.rooks & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
            Piece::Bishop => assert(u64::enumerate_bits(game.board.bitboard.bishops & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
            Piece::Knight => assert(u64::enumerate_bits(game.board.bitboard.knights & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
            _ => (),
        }
    };

    // is move a castle? check rights & legality
    // is there a piece on src?
    // does it belong to current side to move?
    // if piece on dest, is it opposite colour?
    // check en_passant target
    // can piece legally move to dest?
    //   - allowed movements for piece-type
    //   - is piece pinned? (May still be able to move (sliding pice on pinning ray, pawn en passant if diagonal pinner))
    //   - blocking pieces on squares between?
    // check that piece_map is not empty
    // check that metadata is not empty
    // check game.statehash to know if we need to generate bitboards or not
    // check full-move counter. At 50, the game automatically ends in a draw, unless the 50th move is a checkmate
    // if castling, check castling rights
    // if castling, check legality

    // if move.is_castling() {
        // check legality
        // check metadata for castling rights
    // };

    // if move.is_en_passant() {
        // check legality
        // check metadata for en_passant target, ensure match with move.dest
    // };

    true
}
