const std = @import("std");

pub const Player = enum {
    Empty,
    X,
    O,
};

pub const GameError = error{
    InvalidMove,
    CellOccupied,
};

pub const Game = struct {
    board: [3][3]Player,
    current_player: Player,

    pub fn init(player: Player) Game {
        return Game{
            .board = [3][3]Player{
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
            },
            .current_player = player,
        };
    }

    pub fn playerMove(self: *Game, move: usize) !void {
        const x = move % 3;
        const y = move / 3;
        try self.placeMove(x, y);
    }

    pub fn printBoard(self: *const Game, writer: std.fs.File.Writer) !void {
        try writer.writeAll("-----\n");

        for (self.board) |row| {
            for (row) |cell| {
                try writer.print("{s} ", .{
                    switch (cell) {
                        .Empty => ".",
                        .X => "X",
                        .O => "O",
                    },
                });
            }
            try writer.print("\n", .{});
        }

        try writer.writeAll("-----\n");
    }

    pub fn isWinner(self: *const Game, player: Player) bool {
        for (self.board) |row| {
            if (row[0] == player and row[1] == player and row[2] == player) {
                return true;
            }
        }

        for (0..3) |i| {
            if (self.board[0][i] == player and self.board[1][i] == player and self.board[2][i] == player) {
                return true;
            }
        }

        if (self.board[0][0] == player and self.board[1][1] == player and self.board[2][2] == player) {
            return true;
        }

        if (self.board[0][2] == player and self.board[1][1] == player and self.board[2][0] == player) {
            return true;
        }

        return false;
    }

    pub fn isDraw(self: *const Game) bool {
        for (0..3) |y| {
            for (0..3) |x| {
                if (self.board[y][x] == .Empty) {
                    return false;
                }
            }
        }

        return true;
    }

    fn placeMove(self: *Game, x: usize, y: usize) GameError!void {
        if (x >= 3 or y >= 3) {
            return GameError.InvalidMove;
        }

        if (self.board[y][x] != .Empty) {
            return GameError.CellOccupied;
        }

        self.board[y][x] = self.current_player;
        self.current_player = switch (self.current_player) {
            .Empty => .X,
            .X => .O,
            .O => .X,
        };
    }
};
