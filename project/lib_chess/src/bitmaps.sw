library bitmaps;

// TODO: Add a Bitmap struct (use a tuple struct when available)
pub struct Bitmap {
    bits: u64
}

impl Bitmap {
    fn from_u64(num: u64) -> Bitmap {
        Bitmap {
            bits: num
        }
    }
}

impl core::ops::Eq for Bitmap {
    fn eq(self, other: Self) -> bool {
        self.bits == other.bits
    }
}

impl core::ops::BitwiseAnd for Bitmap {
    fn binary_and(self, other: Self) -> Self {
        Bitmap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                and r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::BitwiseOr for Bitmap {
    fn binary_or(self, other: Self) -> Self {
        Bitmap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                or r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::BitwiseXor for Bitmap {
    fn binary_xor(self, other: Self) -> Self {
        Bitmap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                xor r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::Not for Bitmap {
    fn not(self) -> Self {
        Bitmap {
            bits: asm(r1: self.bits, r2) {
                not r2 r1;
                r2: u64
            }
        }
    }
}


// Primary bitmaps
pub const BLACK_PAWNS: u64 = 0x00FF000000000000;
pub const BLACK_ROOKS: u64 = 0x8100000000000000;
pub const BLACK_KNIGHTS: u64 = 0x4200000000000000;
pub const BLACK_BISHOPS: u64 = 0x2400000000000000;
pub const BLACK_QUEEN: u64 = 0x0800000000000000;
pub const BLACK_KING: u64 = 0x1000000000000000;
pub const WHITE_PAWNS: u64 = 0x000000000000FF00;
pub const WHITE_ROOKS: u64 = 0x0000000000000081;
pub const WHITE_KNIGHTS: u64 = 0x0000000000000042;
pub const WHITE_BISHOPS: u64 = 0x0000000000000024;
pub const WHITE_QUEEN: u64 = 0x0000000000000008;
pub const WHITE_KING: u64 = 0x0000000000000010;


// Utility bitmaps
pub const RANK_1: u64 = 0x00000000000000FF;
pub const RANK_2: u64 = WHITE_PAWNS;
pub const RANK_3: u64 = 0x0000000000FF0000;
pub const RANK_4: u64 = 0x00000000FF000000;
pub const RANK_5: u64 = 0x000000FF00000000;
pub const RANK_6: u64 = 0x0000FF0000000000;
pub const RANK_7: u64 = BLACK_PAWNS;
pub const RANK_8: u64 = 0xFF00000000000000;
pub const FILE_A: u64 = 0x0101010101010101;
pub const FILE_B: u64 = 0x0202020202020202;
pub const FILE_C: u64 = 0x0404040404040404;
pub const FILE_D: u64 = 0x0808080808080808;
pub const FILE_E: u64 = 0x1010101010101010;
pub const FILE_F: u64 = 0x2020202020202020;
pub const FILE_G: u64 = 0x4040404040404040;
pub const FILE_H: u64 = 0x8080808080808080;
pub const CASTLING_SQUARES_W_K: u64 = 0x0000000000000060;
pub const CASTLING_SQUARES_W_Q: u64 = 0x0000000000000006;
pub const CASTLING_SQUARES_B_K: u64 = 0x6000000000000000;
pub const CASTLING_SQUARES_B_Q: u64 = 0x0600000000000000;
pub const EDGES: u64 = 0xFF818181818181FF;
pub const CORNERS: u64 = 0x8100000000000081;
pub const LIGHT_SQUARES: u64 = 0x55AA55AA55AA55AA;
pub const DARK_SQUARES: u64 = 0xAA55AA55AA55AA55;
pub const A1_H8_DIAGONAL: u64 = 0x8040201008040201;
pub const H1_A8_ANTIDIAGONAL: u64 = 0x0102040810204080;

// Composite bitmaps
pub const WHITE_PIECES: u64 = 0x000000000000FFFF;
pub const BLACK_PIECES: u64 = 0xFFFF000000000000;
pub const ALL_PIECES: u64 = 0xFFFF00000000FFFF;
pub const BLANK: u64 = 0x0;