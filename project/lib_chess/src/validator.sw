library validator;

dep board;
dep move;

use board::Board;
use move::Move;

pub fn validate(board: Board, move: Move) -> bool {
    let side_to_move = board.side_to_move();
    let (color_moved, piece) = board.read_square(move.source.to_index());
    assert(color_moved == side_to_move);

    true
}