library bitboard;

dep bitmap;
use bitmap::*;

/// The BitBoard type can be thought of as a stack of layers
/// which can be selectively combined to query the location of pieces.
pub struct BitBoard {
    black_pawns: BitMap,
    black_bishops: BitMap,
    black_rooks: BitMap,
    black_knights: BitMap,
    black_queen: BitMap,
    black_king: BitMap,
    white_pawns: BitMap,
    white_bishops: BitMap,
    white_rooks: BitMap,
    white_knights: BitMap,
    white_queen: BitMap,
    white_king: BitMap,
    pawns: BitMap,
    knights: BitMap,
    bishops: BitMap,
    rooks: BitMap,
    queens: BitMap,
    kings: BitMap,
    black: BitMap,
    white: BitMap,
    all: BitMap,
}

impl BitBoard {
    pub fn new() -> BitBoard {
        BitBoard {
            black_pawns: BLACK_PAWNS,
            black_bishops: BLACK_BISHOPS,
            black_rooks: BLACK_ROOKS,
            black_knights: BLACK_KNIGHTS,
            black_queen: BLACK_QUEEN,
            black_king: BLACK_KING,
            white_pawns: WHITE_PAWNS,
            white_bishops: WHITE_BISHOPS,
            white_rooks: WHITE_ROOKS,
            white_knights: WHITE_KNIGHTS,
            white_queen: WHITE_QUEEN,
            white_king: WHITE_KING,
            pawns: BLACK_PAWNS
            | WHITE_PAWNS,
            knights: BLACK_KNIGHTS
            | WHITE_KNIGHTS,
            bishops: BLACK_BISHOPS
            | WHITE_BISHOPS,
            rooks: BLACK_ROOKS
            | WHITE_ROOKS,
            queens: BLACK_QUEEN
            | WHITE_QUEEN,
            kings: BLACK_KING
            | WHITE_KING,
            black: BLACK_PIECES,
            white: WHITE_PIECES,
            all: ALL_PIECES,
        }
    }
}

//////////////////////////////////////////////////////////////////
/// TESTS
//////////////////////////////////////////////////////////////////
#[test()]
fn test_new_bitboard() {
    let board = BitBoard::new();
    assert(board.all == ALL_PIECES);
    assert(board.pawns == BLACK_PAWNS | WHITE_PAWNS);
    assert(board.knights == BLACK_KNIGHTS | WHITE_KNIGHTS);
    assert(board.bishops == BLACK_BISHOPS | WHITE_BISHOPS);
    assert(board.rooks == BLACK_ROOKS | WHITE_ROOKS);
    assert(board.queens == BLACK_QUEEN | WHITE_QUEEN);
    assert(board.kings == BLACK_KING | WHITE_KING);
    assert(board.black == BLACK_PIECES);
    assert(board.white == WHITE_PIECES);
}
