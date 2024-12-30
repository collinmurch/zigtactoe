const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var g = game.Game.init(.X);
    try stdout.writeAll("You play as X.\n");

    var input: usize = undefined;
    while (true) {
        try g.printBoard(stdout);
        if (check_end(&g, stdout)) return;

        // Player
        input = try requestMove(stdin, stdout);
        try g.placeMove(input);

        if (check_end(&g, stdout)) return;

        // AI
        const result = minimax(&g, 0);
        try stdout.print("Move: {d}, Score: {d}\n", .{ result[0] + 1, result[1] });
        try g.placeMove(result[0]);
    }
}

fn check_end(g: *const game.Game, writer: std.fs.File.Writer) bool {
    switch (g.checkWinner()) {
        .X => {
            writer.writeAll("X wins!\n") catch unreachable;
            return true;
        },
        .O => {
            writer.writeAll("O wins!\n") catch unreachable;
            return true;
        },
        .Empty => {
            if (g.isDraw()) {
                writer.writeAll("It's a draw!\n") catch unreachable;
                return true;
            }
        },
    }

    return false;
}

fn requestMove(reader: std.fs.File.Reader, writer: std.fs.File.Writer) !usize {
    var buf: [10]u8 = undefined;

    try writer.writeAll("Enter a move [1-9]: ");
    if (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        const move = try std.fmt.parseInt(usize, user_input, 10);
        return move - 1;
    }

    return 0;
}

fn minimax(g: *const game.Game, depth: usize) struct { usize, i32 } {
    switch (g.checkWinner()) {
        .X => return .{ 0, 10 },
        .O => return .{ 0, -10 },
        .Empty => if (g.isDraw()) return .{ 0, 0 },
    }

    const choices = g.getOpenSpots() catch unreachable;
    defer std.heap.page_allocator.free(choices);

    var scores: [9]i32 = undefined;
    for (choices, 0..) |move, i| {
        if (depth == 0) std.debug.print("Choice: {}\n", .{move});
        var gameCopy = g.*;
        gameCopy.placeMove(move) catch unreachable;
        const result = minimax(&gameCopy, depth + 1);
        scores[i] = result[1];
    }

    var bestScore: i32 = if (g.currentPlayer == .X) -10000 else 10000;
    var bestMove: usize = 0;
    for (scores[0..choices.len], 0..) |score, i| {
        if (g.currentPlayer == .X) {
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
