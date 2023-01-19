library validator;

dep board;
dep move;
dep game;
dep piece;
dep utils;

use board::Board;
use game::{Game, Status};
use move::Move;
use piece::Piece;
use utils::enumerate_bits;

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
            Piece::Rook => assert(enumerate_bits(game.board.bitboard.rooks & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
            Piece::Bishop => assert(enumerate_bits(game.board.bitboard.bishops & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
            Piece::Knight => assert(enumerate_bits(game.board.bitboard.knights & game.board.bitboard.colors[side_to_move]).unwrap() < 2),
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
    true
}
