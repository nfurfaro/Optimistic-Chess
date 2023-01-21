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
use piece::{BLACK, Piece, WHITE};
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
        << 7   << 8   << 9
              \  |  /
  west  >> 1 <-  0 -> << 1  east
              /  |  \
        >> 9  >> 8    >> 7
  soWe         sout         soEa

*/

// fn square_mask() -> u64 {}
fn file_delta() {}
fn rank_delta() {}

fn is_legal_move(board: Board, move: Move) -> bool {
    let (color, piece) = board.read_square(move.source.to_index());
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

fn threat_map(bits: BitBoard, color: u64) -> u64 {
     pawn_attacks(bits, color) | bishop_attacks(bits, color) | rook_attacks(bits, color) | knight_attacks(bits, color) | queen_attacks(bits, color) | king_attacks(bits, color)
}

fn pawn_attacks(bits: BitBoard, color: u64) -> u64 {
    match color {
        BLACK => ((bits.black_pawns >> 7) & !FILE_H) | ((bits.black_pawns >> 9) & !FILE_A),
        WHITE => ((bits.white_pawns << 7) & !FILE_H) | ((bits.white_pawns << 9) & !FILE_A),
        _ => revert(0),
    }
}

fn bishop_attacks(bits: BitBoard, color: u64) -> u64 {
    // TODO: Implement me !
    0
}

fn rook_attacks(bits: BitBoard, color: u64) -> u64 {
    // TODO: Implement me !
    0
}

fn knight_attacks(bits: BitBoard, color: u64) -> u64 {
    // TODO: Implement me !
    0
}

fn queen_attacks(bits: BitBoard, color: u64) -> u64 {
    // TODO: Implement me !
    0
}

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
        (false, true, true, false) => (king >> 8) | (king << 1) | (king >> 7),
        // h8 corner: can attack 3 squares
        (false, false, true, true) => (king >> 8) | (king >> 9) | (king >> 1),
        // h1 corner: can attack 3 squares
        (true, false, false, true) => (king >> 1) | (king << 7) | (king << 8),
        // rank 1: can attack 5 squares
        (true, false, false, false) => (king >> 1) | (king << 7) | (king << 8) | (king << 9) | (king << 1),
        // file a: can attack 5 squares
        (false, true, false, false) => (king >> 8) | (king << 8) | (king << 9) | (king << 1) | (king >> 7),
        // rank 8: can attack 5 squares
        (false, false, true, false) => (king >> 8) | (king >> 9) | (king >> 1) | (king << 1) | (king >> 7),
        // file h: can attack 5 squares
        (false, false, false, true) => (king >> 8) | (king >> 9) | (king >> 1) | (king << 7) | (king << 8),
        // king is not on an edge square: can attack 8 squares
        (false, false, false, false) => (king >> 8) | (king >> 9) | (king >> 1) | (king << 7) | (king << 8) | (king << 9) | (king << 1) | (king >> 7),
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
        match p {
            Piece::Queen => assert(board.bitboard.queens & board.bitboard.colors[board.side_to_move()] == 0),
            Piece::Rook => assert(u64::enumerate_bits(board.bitboard.rooks & board.bitboard.colors[board.side_to_move()]).unwrap() < 2),
            Piece::Bishop => assert(u64::enumerate_bits(board.bitboard.bishops & board.bitboard.colors[board.side_to_move()]).unwrap() < 2),
            Piece::Knight => assert(u64::enumerate_bits(board.bitboard.knights & board.bitboard.colors[board.side_to_move()]).unwrap() < 2),
            _ => (),
        }
    };
    // check en_passant target:
    // if move.is_en_passant() {
        // check legality
        // check metadata for en_passant target, ensure match with move.dest
    // };

}

fn bishop_validation(board: Board, move: Move) {
    // TODO: Implement me !
}

fn rook_validation(board: Board, move: Move) {
    // TODO: Implement me !
}

fn knight_validation(board: Board, move: Move) {
    // TODO: Implement me !
}

fn queen_validation(board: Board, move: Move) {
    // TODO: Implement me !
}

fn king_validation(board: Board, move: Move) {
    // TODO: Implement me !
    // if move.is_castling() {
        // check legality
        // check metadata for castling rights
    // };
}

// validation checks common to all pieces and colors
fn universal_validation_checks() {
    // TODO: Implement me !

    // perform the cheapest checks first!
    // check game.statehash to know if we need to generate bitboards or not
    // check game status ! don't bother validating moves if game is over
    // check metadata
    // src & dest must be valid squares
    // if source and dest are of type Square, they can only be valid squares!
    // assert(move.source.is_in_bounds() && move.dest.is_in_bounds());
    // is move a castle? check rights & legality
    // is there a piece on src?
    // does it belong to current side to move?
    // if piece on dest, is it opposite colour?
    //   - is piece pinned? (May still be able to move (sliding pice on pinning ray, pawn en passant if diagonal pinner))
    //   - blocking pieces on squares between?
    // check full-move counter. At 50, the game automatically ends in a draw, unless the 50th move is a checkmate
}

pub fn validate(game: Game, move: Move) -> bool {
    let side_to_move = game.board.side_to_move();
    let (color_moved, piece) = game.board.read_square(move.source.to_index());
    assert(color_moved == side_to_move);

    match game.status {
        Status::Active => (),
        _ => return false,
    };

    true
}
