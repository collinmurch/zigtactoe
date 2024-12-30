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

    pub fn print_board(self: *const Game, writer: std.fs.File.Writer) !void {
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

    pub fn get_open_spots(self: *const Game) []const usize {
        var open_spots = std.ArrayList(usize).init(std.heap.page_allocator);
        defer open_spots.deinit();

        var count: usize = 0;
        for (self.board, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                if (cell == .Empty) {
                    open_spots.append(y * 3 + x) catch |err| {
                        std.debug.print("Unexpected error appending open spots: {}\n", .{err});
                        return &[_]usize{};
                    };
                    count += 1;
                }
            }
        }

        return open_spots.toOwnedSlice() catch |err| {
            std.debug.print("Unexpected error returning open spots: {}\n", .{err});
            return &[_]usize{};
        };
    }

    pub fn check_winner(self: *const Game) Player {
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

    pub fn is_draw(self: *const Game) bool {
        for (0..3) |y| {
            for (0..3) |x| {
                if (self.board[y][x] == .Empty) return false;
            }
        }

        return true;
    }

    pub fn place_move(self: *Game, index: usize) GameError!void {
        if (index >= 9) return GameError.InvalidMove;

        const y = index / 3;
        const x = index % 3;

        if (self.board[y][x] != .Empty) return GameError.CellOccupied;

        self.board[y][x] = self.current_player;
        self.current_player = switch (self.current_player) {
            .X => .O,
            .O => .X,
            else => .Empty,
        };
    }
};
