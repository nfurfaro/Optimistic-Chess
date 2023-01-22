library bitmap;

// TODO: Add a BitMap struct (use a tuple struct when available)
pub struct BitMap {
    bits: u64
}

impl BitMap {
    pub fn from_u64(num: u64) -> BitMap {
        BitMap {
            bits: num
        }
    }

    // returns the number of set bits in a bitmap.
    pub fn enumerate_bits(self) -> Option<u64> {
        let mut n = 0;
        let mut b = self.bits;
        while b != 0 {
            n += 1;
            b = b & (b - 1);
        };
        match n {
            0 => Option::None,
            _ => Option::Some(n),
        }
    }
}

impl core::ops::Eq for BitMap {
    fn eq(self, other: Self) -> bool {
        __eq(self.bits, other.bits)
    }
}

impl core::ops::BitwiseAnd for BitMap {
    fn binary_and(self, other: Self) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                and r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::BitwiseOr for BitMap {
    fn binary_or(self, other: Self) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                or r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::BitwiseXor for BitMap {
    fn binary_xor(self, other: Self) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2: other.bits, r3) {
                xor r3 r1 r2;
                r3: u64
            }
        }
    }
}

impl core::ops::Not for BitMap {
    fn not(self) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2) {
                not r2 r1;
                r2: u64
            }
        }
    }
}


impl core::ops::Shiftable for BitMap {
    fn lsh(self, other: u64) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2: other, r3) {
                sll r3 r1 r2;
                r3: u64
            }
        }
    }

    fn rsh(self, other: u64) -> Self {
        BitMap {
            bits: asm(r1: self.bits, r2: other, r3) {
                srl r3 r1 r2;
                r3: u64
            }
        }
    }
}


// Primary bitmaps
pub const BLACK_PAWNS: BitMap = BitMap::from_u64(0x00FF000000000000);
pub const BLACK_ROOKS: BitMap = BitMap::from_u64(0x8100000000000000);
pub const BLACK_KNIGHTS: BitMap = BitMap::from_u64(0x4200000000000000);
pub const BLACK_BISHOPS: BitMap = BitMap::from_u64(0x2400000000000000);
pub const BLACK_QUEEN: BitMap = BitMap::from_u64(0x0800000000000000);
pub const BLACK_KING: BitMap = BitMap::from_u64(0x1000000000000000);
pub const WHITE_PAWNS: BitMap = BitMap::from_u64(0x000000000000FF00);
pub const WHITE_ROOKS: BitMap = BitMap::from_u64(0x0000000000000081);
pub const WHITE_KNIGHTS: BitMap = BitMap::from_u64(0x0000000000000042);
pub const WHITE_BISHOPS: BitMap = BitMap::from_u64(0x0000000000000024);
pub const WHITE_QUEEN: BitMap = BitMap::from_u64(0x0000000000000008);
pub const WHITE_KING: BitMap = BitMap::from_u64(0x0000000000000010);


// Utility bitmaps
pub const RANK_1: BitMap = BitMap::from_u64(0x00000000000000FF);
pub const RANK_2: BitMap = WHITE_PAWNS;
pub const RANK_3: BitMap = BitMap::from_u64(0x0000000000FF0000);
pub const RANK_4: BitMap = BitMap::from_u64(0x00000000FF000000);
pub const RANK_5: BitMap = BitMap::from_u64(0x000000FF00000000);
pub const RANK_6: BitMap = BitMap::from_u64(0x0000FF0000000000);
pub const RANK_7: BitMap = BLACK_PAWNS;
pub const RANK_8: BitMap = BitMap::from_u64(0xFF00000000000000);
pub const FILE_A: BitMap = BitMap::from_u64(0x0101010101010101);
pub const FILE_B: BitMap = BitMap::from_u64(0x0202020202020202);
pub const FILE_C: BitMap = BitMap::from_u64(0x0404040404040404);
pub const FILE_D: BitMap = BitMap::from_u64(0x0808080808080808);
pub const FILE_E: BitMap = BitMap::from_u64(0x1010101010101010);
pub const FILE_F: BitMap = BitMap::from_u64(0x2020202020202020);
pub const FILE_G: BitMap = BitMap::from_u64(0x4040404040404040);
pub const FILE_H: BitMap = BitMap::from_u64(0x8080808080808080);
pub const CASTLING_SQUARES_W_K: BitMap = BitMap::from_u64(0x0000000000000060);
pub const CASTLING_SQUARES_W_Q: BitMap = BitMap::from_u64(0x0000000000000006);
pub const CASTLING_SQUARES_B_K: BitMap = BitMap::from_u64(0x6000000000000000);
pub const CASTLING_SQUARES_B_Q: BitMap = BitMap::from_u64(0x0600000000000000);
pub const EDGES: BitMap = BitMap::from_u64(0xFF818181818181FF);
pub const CORNERS: BitMap = BitMap::from_u64(0x8100000000000081);
pub const LIGHT_SQUARES: BitMap = BitMap::from_u64(0x55AA55AA55AA55AA);
pub const DARK_SQUARES: BitMap = BitMap::from_u64(0xAA55AA55AA55AA55);
pub const A1_H8_DIAGONAL: BitMap = BitMap::from_u64(0x8040201008040201);
pub const H1_A8_ANTIDIAGONAL: BitMap = BitMap::from_u64(0x0102040810204080);

// Composite bitmaps
pub const WHITE_PIECES: BitMap = BitMap::from_u64(0x000000000000FFFF);
pub const BLACK_PIECES: BitMap = BitMap::from_u64(0xFFFF000000000000);
pub const ALL_PIECES: BitMap = BitMap::from_u64(0xFFFF00000000FFFF);
pub const BLANK: BitMap = BitMap::from_u64(0x0);

#[test()]
fn test_enumerate_bits() {
    let n1 = BitMap::from_u64(u64::max()).enumerate_bits();
    let n2 = BitMap::from_u64(u64::min()).enumerate_bits();
    let n3 = BitMap::from_u64(1).enumerate_bits();
    let n4 = BitMap::from_u64(0b011010011).enumerate_bits();
    let n5 = BitMap::from_u64(0b011010011011010011011011011011010011011011011).enumerate_bits();

    assert(n1.is_some());
    assert(n2.is_none());
    assert(n3.is_some());
    assert(n1.unwrap() == 64);
    assert(n3.unwrap() == 1);
    assert(n4.unwrap() == 5);
    assert(n5.unwrap() == 27);
}
