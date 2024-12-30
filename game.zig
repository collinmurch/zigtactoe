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
    currentPlayer: Player,

    pub fn init(player: Player) Game {
        return Game{
            .board = [3][3]Player{
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
                [_]Player{.Empty} ** 3,
            },
            .currentPlayer = player,
        };
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

    pub fn getOpenSpots(self: *const Game) ![]const usize {
        var open_spots = std.ArrayList(usize).init(std.heap.page_allocator);
        defer open_spots.deinit();

        var count: usize = 0;
        for (self.board, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                if (cell == .Empty) {
                    open_spots.append(y * 3 + x) catch unreachable;
                    count += 1;
                }
            }
        }

        return open_spots.toOwnedSlice();
    }

    pub fn checkWinner(self: *const Game) Player {
        for ([_]Player{ .X, .O }) |player| {
            for (self.board) |row| {
                if (row[0] == player and row[1] == player and row[2] == player) {
                    return player;
                }
            }

            for (0..3) |i| {
                if (self.board[0][i] == player and self.board[1][i] == player and self.board[2][i] == player) {
                    return player;
                }
            }

            if (self.board[0][0] == player and self.board[1][1] == player and self.board[2][2] == player) {
                return player;
            }
            if (self.board[0][2] == player and self.board[1][1] == player and self.board[2][0] == player) {
                return player;
            }
        }

        return .Empty;
    }

    pub fn isDraw(self: *const Game) bool {
        for (0..3) |y| {
            for (0..3) |x| {
                if (self.board[y][x] == .Empty) return false;
            }
        }

        return true;
    }

    pub fn placeMove(self: *Game, index: usize) GameError!void {
        if (index >= 9) return GameError.InvalidMove;

        const y = index / 3;
        const x = index % 3;

        if (self.board[y][x] != .Empty) return GameError.CellOccupied;

        self.board[y][x] = self.currentPlayer;
        self.currentPlayer = switch (self.currentPlayer) {
            .Empty => .X,
            .X => .O,
            .O => .X,
        };
    }
};
