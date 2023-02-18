library board;

dep bitboard;
dep bitmap;
dep color;
dep errors;
dep move;
dep piece;
dep special;
dep square;
dep utils;

use bitboard::BitBoard;
use bitmap::*;
use color::{BLACK, Color, WHITE};
use errors::*;
use move::Move;
use piece::{BISHOP, EMPTY, KING, KNIGHT, PAWN, Piece, QUEEN, ROOK};
use special::CastleRights;
use square::Square;
use utils::{b256_multimask, compose, decompose, multi_bit_mask, query_bit, toggle_bit, turn_on_bit};
/**

note: for more detail about how pieces are encoded, see ./piece.sw

Initial board state:

    0011 0100 0010 0101 0110 0010 0100 0011
    0001 0001 0001 0001 0001 0001 0001 0001
    0000 0000 0000 0000 0000 0000 0000 0000
    0000 0000 0000 0000 0000 0000 0000 0000
    0000 0000 0000 0000 0000 0000 0000 0000
    0000 0000 0000 0000 0000 0000 0000 0000
    1001 1001 1001 1001 1001 1001 1001 1001
    1011 1100 1010 1101 1110 1010 1100 1011

4 bits per piece * 64 squares = 256 bits to store all pieces.
*/
// HEX equivalent of the above starting board state
pub const INITIAL_PIECEMAP: b256 = 0x34256243111111110000000000000000000000000000000099999999BCADEACB;
pub const INITIAL_METADATA: u64 = 0b00000000_00000000_00000000_00000000_00001111_00000000_00000000_00000001;
pub const HALF_MOVE_MASK: u64 = 0x000000000000FF00;
pub const FULL_MOVE_MASK: u64 = 0x000000FF00000000;
pub const EN_PASSANT_MASK: u64 = 0x0000000000FF0000;
pub const CASTLING_MASK: u64 = 0x00000000FF000000;
pub const HALF_MOVE_CLEARING_MASK: u64 = 0xFFFFFFFFFFFF00FF;
pub const FULL_MOVE_CLEARING_MASK: u64 = 0xFFFFFF00FFFFFFFF;
pub const CASTLING_CLEARING_MASK: u64 = 0xFFFFFFFF00FFFFFF;
pub const EN_PASSANT_CLEARING_MASK: u64 = 0xFFFFFFFFFF00FFFF;

// struct for internal state representation.
// bitboards are calculated from the piecemap
pub struct Board {
    // complete location and type data for the board at a given point in time. Efficient transport, but not efficient to query, i.e: "give me all non-pinned white pawns", etc...
    piecemap: b256,
    // Great for answering queries, but less efficient for transport.
    // less efficient at answering the question: "what color/type is the piece on square f7?"
    bitboard: BitBoard,
    metadata: u64,
}

impl Board {
    pub fn new() -> Board {
        Board {
            piecemap: INITIAL_PIECEMAP,
            bitboard: BitBoard::new(),
            metadata: INITIAL_METADATA,
        }
    }
}

impl Board {
    pub fn build(pieces: b256, bits: BitBoard, data: u64) -> Board {
        Board {
            piecemap: pieces,
            bitboard: bits,
            metadata: data,
        }
    }
}

impl Board {
    pub fn king_in_check(self, color: Color) -> bool {
        true
    }

    pub fn clear_castling_rights(self) -> Board {
        Board::build(self.piecemap, self.bitboard, self.metadata & CASTLING_CLEARING_MASK)
    }

    pub fn clear_en_passant(self) -> Board {
        Board::build(self.piecemap, self.bitboard, self.metadata & EN_PASSANT_CLEARING_MASK)
    }

     // clear 1 nibble corresponding to a specific square's index from a piecemap
    pub fn clear_square(self, square: Square) -> Board {
        let mut index = square.to_index();
        // create a mask of all 1's except 4 0's on the target nibble.
        if index == 0 {
            let first_nibble_mask = b256_multimask(252);
            Board::build(self.piecemap & first_nibble_mask, self.bitboard, self.metadata)
        } else {
            // eg: index = 42, * 4 = 168th bit
            // part 1: need 256 - 168 - 4 `1`s, << 168 + 4 bits.
            // part 2: need 168 `1`s
            // mask = part 1 | part 2
            let nibble_index = index * 4;
            let mask_part_1 = b256_multimask((256 - (nibble_index) - 4) << nibble_index);
            let mask_part_2 = b256_multimask(nibble_index);
            Board::build(self.piecemap & (mask_part_1 | mask_part_2), self.bitboard, self.metadata)
        }
    }
}

impl Board {
    pub fn write_square_to_piecemap(self, color: Color, piece: Piece, dest: Square) -> Board {
        let cleared_piecemap = self.clear_square(dest).piecemap;
        let mut index = dest.to_index();
        // set the "color" bit in the piece code
        let colored_piece = piece.to_u64() | (color.to_u64() << 4);
        let mut piece_code = compose((0, 0, 0, (colored_piece)));
        let shifted = piece_code << index;
        Board::build(cleared_piecemap | shifted, self.bitboard, self.metadata)
    }

    pub fn half_move_counter(self) -> u64 {
        (self.metadata & HALF_MOVE_MASK) >> 8
    }

    pub fn full_move_counter(self) -> u64 {
        (self.metadata & FULL_MOVE_MASK) >> 32
    }

    // TODO: consider moving en_passant methods to Game? It must persist for 2 half moves
    pub fn en_passant_target(self) -> Square {
        Square::from_index((self.metadata & EN_PASSANT_MASK) >> 16).unwrap()
    }

    // TODO: consider partial reads, i.e: read only black castling rights if it's Blacks turn to move.
    pub fn castling_rights(self) -> Result<[CastleRights; 2], ChessError> {
        let value = (self.metadata & CASTLING_MASK) >> 24;
        match value {
            0x0 => Result::Ok([CastleRights::NoRights, CastleRights::NoRights]),
            0x1 => Result::Ok([CastleRights::NoRights, CastleRights::KingSide]),
            0x2 => Result::Ok([CastleRights::NoRights, CastleRights::QueenSide]),
            0x3 => Result::Ok([CastleRights::NoRights, CastleRights::Both]),
            0x4 => Result::Ok([CastleRights::KingSide, CastleRights::NoRights]),
            0x5 => Result::Ok([CastleRights::KingSide, CastleRights::KingSide]),
            0x6 => Result::Ok([CastleRights::KingSide, CastleRights::QueenSide]),
            0x7 => Result::Ok([CastleRights::KingSide, CastleRights::Both]),
            0x8 => Result::Ok([CastleRights::QueenSide, CastleRights::NoRights]),
            0x9 => Result::Ok([CastleRights::QueenSide, CastleRights::KingSide]),
            0xA => Result::Ok([CastleRights::QueenSide, CastleRights::QueenSide]),
            0xB => Result::Ok([CastleRights::QueenSide, CastleRights::Both]),
            0xC => Result::Ok([CastleRights::Both, CastleRights::NoRights]),
            0xD => Result::Ok([CastleRights::Both, CastleRights::KingSide]),
            0xE => Result::Ok([CastleRights::Both, CastleRights::QueenSide]),
            0xF => Result::Ok([CastleRights::Both, CastleRights::Both]),
            _ => Result::Err(ChessError::Unimplemented),
        }
    }

    pub fn set_castling_rights(self, rights: (CastleRights, CastleRights)) -> Board {
        let cleared_board = self.clear_castling_rights();
        let value = match rights {
            (CastleRights::NoRights, CastleRights::NoRights) => 0x0,
            (CastleRights::NoRights, CastleRights::KingSide) => 0x1,
            (CastleRights::NoRights, CastleRights::QueenSide) => 0x2,
            (CastleRights::NoRights, CastleRights::Both) => 0x3,
            (CastleRights::KingSide, CastleRights::NoRights) => 0x4,
            (CastleRights::KingSide, CastleRights::KingSide) => 0x5,
            (CastleRights::KingSide, CastleRights::QueenSide) => 0x6,
            (CastleRights::KingSide, CastleRights::Both) => 0x7,
            (CastleRights::QueenSide, CastleRights::NoRights) => 0x8,
            (CastleRights::QueenSide, CastleRights::KingSide) => 0x9,
            (CastleRights::QueenSide, CastleRights::QueenSide) => 0xA,
            (CastleRights::QueenSide, CastleRights::Both) => 0xB,
            (CastleRights::Both, CastleRights::NoRights) => 0xC,
            (CastleRights::Both, CastleRights::KingSide) => 0xD,
            (CastleRights::Both, CastleRights::QueenSide) => 0xE,
            (CastleRights::Both, CastleRights::Both) => 0xF,
        };

        Board::build(cleared_board.piecemap, cleared_board.bitboard, cleared_board.metadata | (value << 24))
    }

    pub fn reset_half_move_counter(self) -> Board {
        Board::build(self.piecemap, self.bitboard, self.metadata & HALF_MOVE_CLEARING_MASK)
    }

    pub fn clear_full_move(self) -> Board {
        Board::build(self.piecemap, self.bitboard, self.metadata & FULL_MOVE_CLEARING_MASK)
    }

    // TODO: decide on error handling strategy for this to replace the use of unwrap() everywhere.
    pub fn read_square(self, square_index: u64) -> Option<(Color, Piece)> {
        let mut index = square_index;
        let mut mask = compose((0, 0, 0, multi_bit_mask(4)));
        let piece_code = if index == 0 {
            decompose(self.piecemap & mask).3
        } else {
            index *= 4;
            let mask = compose((0, 0, 0, multi_bit_mask(index) << index));
            decompose((self.piecemap & mask) >> index).3
        };
        match piece_code {
            0 => Option::None,
            _ => {
                let color = Color::try_from_u64(piece_code >> 4).unwrap();
                let piece = Piece::try_from_u64(piece_code).unwrap();
                Option::Some((color, piece))
            },
        }
    }
}

impl Board {
    // convert bitboard to piecemap
    // TODO: do I ever need to perform all these steps, or can I always just use the latest Move to update 2 nibbles in the piecemap?
    pub fn generate_piecemap(self) -> Board {
        let mut new_board = Board::new();
        let mut i = 0;
        let mut mask = BLANK;
        let mut color = 0;
        let mut piece = EMPTY;
        // TODO: see if I can use match to clean this up. Add unit tests first so I know it actually works.
        while i < 64 {
            mask = BitMap::from_u64(1 << i);
            let occupied = mask & self.bitboard.all;
            if occupied == BLANK {
                i += 1;
            } else {
                let pawn_test = mask & self.bitboard.pawns;
                if pawn_test != BLANK {
                    piece = PAWN;
                } else {
                    let bishop_test = mask & self.bitboard.bishops;
                    if bishop_test != BLANK {
                        piece = BISHOP;
                    } else {
                        let rook_test = mask & self.bitboard.rooks;
                        if rook_test != BLANK {
                            piece = ROOK;
                        } else {
                            let knight_test = mask & self.bitboard.knights;
                            if knight_test != BLANK {
                                piece = KNIGHT;
                            } else {
                                let queen_test = mask & self.bitboard.queens;
                                if queen_test != BLANK {
                                    piece = QUEEN;
                                } else {
                                    piece = KING;
                                }
                            }
                        }
                    };
                }
            };

            let color = if mask & self.bitboard.black != BLANK {
                BLACK
            } else {
                WHITE
            };

            new_board = self.write_square_to_piecemap(color, Piece::try_from_u64(piece).unwrap(), Square::from_index(i).unwrap());
            i += 1;
        };

        new_board
    }

    // wraps Square::clear() & Square::set() ??                  REVIEW !
    pub fn move_piece(mut self, src: Square, dest: Square) -> Board {
        match self.read_square(src.to_index()) {
            Option::None => revert(0),
            Option::Some((color, piece)) => {
                // clear src
                self.clear_square(src);
                // TODO: clear dest if !color, and must be legal move
                self.clear_square(dest);
                // set src
                self.write_square_to_piecemap(color, piece, dest)
            },
        }
    }

    pub fn side_to_move(self) -> Color {
        Color::try_from_u64(query_bit(self.metadata, 0)).unwrap()
    }

    pub fn toggle_side_to_move(self) -> Board {
        Board::build(self.piecemap, self.bitboard, toggle_bit(self.metadata, 0))
    }

    pub fn increment_half_move_counter(self) -> Board {
        let mut new_board = self.reset_half_move_counter();
        new_board.metadata = self.metadata | ((self.half_move_counter() + 1) << 8);
        new_board
    }

    pub fn increment_full_move_counter(self) -> Board {
        let mut new_board = self.clear_full_move();
        new_board.metadata = self.metadata | ((self.full_move_counter() + 1) << 32);
        new_board
    }

    pub fn set_en_passant(self, target: Square) -> Board {
        let mut new_board = self.clear_en_passant();
        new_board.metadata = self.metadata | target.to_index() << 16;
        new_board
    }
}

impl Board {
    // TODO: review this, inputs/outputs & mutation of self?
    pub fn write_to_bitboard(mut self, board: Board) {
        let mut bitboard = BitBoard::new();

        let mut s = 0;
        let mut i = 0;
        while i < 64 {
            let (color, piece) = board.read_square(s).unwrap();
            if color == BLACK {
                match piece {
                    Piece::Pawn => self.bitboard.black_pawns = BitMap::from_u64(turn_on_bit(bitboard.black_pawns.bits, i)),
                    Piece::Bishop => self.bitboard.black_bishops = BitMap::from_u64(turn_on_bit(bitboard.black_bishops.bits, i)),
                    Piece::Rook => self.bitboard.black_rooks = BitMap::from_u64(turn_on_bit(bitboard.black_rooks.bits, i)),
                    Piece::Knight => self.bitboard.black_knights = BitMap::from_u64(turn_on_bit(bitboard.black_knights.bits, i)),
                    Piece::Queen => self.bitboard.black_queen = BitMap::from_u64(turn_on_bit(bitboard.black_queen.bits, i)),
                    Piece::King => self.bitboard.black_king = BitMap::from_u64(turn_on_bit(bitboard.black_king.bits, i)),
                }
            } else {
                match piece {
                    Piece::Pawn => self.bitboard.white_pawns = BitMap::from_u64(turn_on_bit(bitboard.white_pawns.bits, i)),
                    Piece::Bishop => self.bitboard.white_bishops = BitMap::from_u64(turn_on_bit(bitboard.white_bishops.bits, i)),
                    Piece::Rook => self.bitboard.white_rooks = BitMap::from_u64(turn_on_bit(bitboard.white_rooks.bits, i)),
                    Piece::Knight => self.bitboard.white_knights = BitMap::from_u64(turn_on_bit(bitboard.white_knights.bits, i)),
                    Piece::Queen => self.bitboard.white_queen = BitMap::from_u64(turn_on_bit(bitboard.white_queen.bits, i)),
                    Piece::King => self.bitboard.white_king = BitMap::from_u64(turn_on_bit(bitboard.white_king.bits, i)),
                }
            };
            s += 4;
            i += 1;
        }
    }

    // make updates to data structure, but stop before writing to storage or logging events.
    pub fn apply_move(mut self, move: Move) {
        // update metadata:
        self.toggle_side_to_move();
        let turn = self.increment_half_move_counter();
        let half_move = self.half_move_counter();
        if half_move > 0 && half_move % 2 == 0 {
            self.increment_full_move_counter();
        };

        if move.pawn_was_moved() || move.piece_was_captured() {
            self.reset_half_move_counter();
        };

        // update en_passant if needed
        if move.dest.to_index() == self.en_passant_target().to_index()
        {
            self.clear_en_passant();
        };

        /**
        let (allowed, maybe_square) = move.allows_en_passant();
        if allowed {
            self.set_en_passant(maybe_square.unwrap())
        }
        */

        // update castling_rights if needed
        if move.is_castling() {
            let mut rights = self.castling_rights();
            let turn_to_move = self.side_to_move();
            match turn_to_move {
                Color::Black => {
                    self.set_castling_rights((CastleRights::NoRights, rights.unwrap()[0]));
                },
                Color::White => {
                    self.set_castling_rights((rights.unwrap()[1], CastleRights::NoRights));
                },
            };
        }

        self.move_piece(move.source, move.dest  );
    }
}

//////////////////////////////////////////////////////////////////
/// TESTS
//////////////////////////////////////////////////////////////////
#[test()]
fn test_new_board() {
    let board = Board::new();
    assert(board.piecemap == INITIAL_PIECEMAP);
    assert(board.metadata == INITIAL_METADATA);
}

// #[test()]
// fn test_transition_side_to_move() {
//     let mut p1 = Board::build(INITIAL_PIECEMAP, BitBoard::new(), INITIAL_METADATA);
//     let m1 = Move::build(Square::a3, Square::a4, Option::None);
//     p1.transition(m1);
//     assert(p1.side_to_move() == BLACK);
//     let m2 = Move::build(Square::a2, Square::a3, Option::None);
//     p1.transition(m2);
//     assert(p1.side_to_move() == WHITE);
// }
// #[test()]
// fn test_transition_half_move_increment() {
//     let mut p1 = Board::build(INITIAL_PIECEMAP, BitBoard::new(),INITIAL_METADATA);
//     let m1 = Move::build(Square::a2, Square::a3, Option::None);
//     p1.transition(m1);
//     assert(p1.half_move_counter() == 1);
// }
#[test()]
fn test_increment_full_move_counter() {
    let metadata = 0b00000000_00000000_00000000_00000000_00001111_00000000_00000000_00000001;
    let mut b1 = Board::build(INITIAL_PIECEMAP, BitBoard::new(), metadata);
    assert(b1.full_move_counter() == 0);
    let b2 = b1.increment_full_move_counter();
    assert(b2.full_move_counter() == 1);
}

#[test()]
fn test_increment_half_move_counter() {
    let mut p1 = Board::new();
    assert(p1.half_move_counter() == 0);
    let p2 = p1.increment_half_move_counter();
    assert(p2.half_move_counter() == 1);
}
