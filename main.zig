const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var g = game.Game.init(.X);
    try stdout.writeAll("You play as X.\n");

    var input: usize = undefined;
    while (true) {
        try g.print_board(stdout);
        switch (g.check_winner()) {
            .X => {
                try stdout.writeAll("X wins!\n");
                return;
            },
            .O => {
                try stdout.writeAll("O wins!\n");
                return;
            },
            .Empty => {
                if (g.is_draw()) {
                    try stdout.writeAll("It's a draw!\n");
                    return;
                }
            },
        }

        switch (g.current_player) {
            .X => {
                input = try request_move(stdin, stdout);
                try g.place_move(input);
            },
            .O => {
                const result = minimax(&g);
                try g.place_move(result[0]);
            },
            else => {},
        }
    }
}

fn request_move(reader: std.fs.File.Reader, writer: std.fs.File.Writer) !usize {
    var buf: [10]u8 = undefined;

    try writer.writeAll("Enter a move [1-9]: ");
    if (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        const move = try std.fmt.parseInt(usize, user_input, 10);
        return move - 1;
    }

    return 0;
}

fn minimax(g: *const game.Game) struct { usize, i32 } {
    switch (g.check_winner()) {
        .X => return .{ 0, 10 },
        .O => return .{ 0, -10 },
        .Empty => if (g.is_draw()) return .{ 0, 0 },
    }

    const choices = g.get_open_spots();
    defer std.heap.page_allocator.free(choices);

    var scores: [9]i32 = undefined;
    for (choices, 0..) |move, i| {
        var gameCopy = g.*;
        gameCopy.place_move(move) catch |err| {
            std.debug.print("Unexpected error placing open AI move: {}\n", .{err});
            return .{ 0, 0 };
        };

        const result = minimax(&gameCopy);
        scores[i] = result[1];
    }

    var bestScore: i32 = if (g.current_player == .X) -10000 else 10000;
    var bestMove: usize = 0;
    for (scores[0..choices.len], 0..) |score, i| {
        if (g.current_player == .X) {
            if (score > bestScore) {
                bestScore = score;
                bestMove = choices[i];
            }
        } else {
            if (score < bestScore) {
                bestScore = score;
                bestMove = choices[i];
            }
        }
    }

    return .{ bestMove, bestScore };
}
