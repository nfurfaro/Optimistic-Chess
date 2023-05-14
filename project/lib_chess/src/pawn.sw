library;

use ::bitboard::BitBoard;
use ::bitmap::{BitMap, BLANK, FILE_A, FILE_H};
use ::board::Board;
use ::color::*;
use ::move::Move;
use ::piece::*;

pub fn pawn_attacks(bits: BitBoard, color: Color) -> BitMap {
    match color {
        Color::Black => ((bits.black_pawns >> 7) & !FILE_H) | ((bits.black_pawns >> 9) & !FILE_A),
        Color::White => ((bits.white_pawns << 7) & !FILE_H) | ((bits.white_pawns << 9) & !FILE_A),
        _ => revert(0),
    }
}

pub fn pawn_validation(board: Board, move: Move) {
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
