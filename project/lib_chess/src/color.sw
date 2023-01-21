library color;

dep errors;
use errors::ChessError;

pub const BLACK: Color = Color::Black; // 0
pub const WHITE: Color = Color::White; // 1

pub enum Color {
    Black: (),
    White: (),
}

impl Color {
    pub fn to_u64(self) -> u64 {
        match self {
            Color::Black => 0,
            Color::White => 1,
        }
    }

    pub fn try_from_u64(num: u64) -> Result<Color, ChessError> {
        match num {
            0 => Result::Ok(Color::Black),
            1 => Result::Ok(Color::White),
            _ => Result::Err(ChessError::Unimplemented),
        }
    }
}

impl core::ops::Eq for Color {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (Color::Black, Color::Black) => true,
            (Color::White, Color::White) => true,
            _ => false,
        }
    }
}
