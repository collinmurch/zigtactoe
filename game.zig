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

    pub fn init() Game {
        return Game{
            .board = [3][3]Player{
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
            },
            .current_player = .Empty,
        };
    }

    pub fn move(self: *Game, x: usize, y: usize) GameError!void {
        if (x >= 3 or y >= 3) {
            return GameError.InvalidMove;
        }

        if (self.board[x][y] != .Empty) {
            return GameError.CellOccupied;
        }

        self.board[x][y] = self.current_player;
        self.current_player = switch (self.current_player) {
            .Empty => .X,
            .X => .O,
            .O => .Empty,
        };
    }

    pub fn isWinner(self: Game, player: Player) bool {
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
};
