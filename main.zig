const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var g = game.Game.init(stdin, stdout, .X);
    try stdout.writeAll("You play as X.\n");

    while (true) {
        g.print_board();
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

        if (g.current_player == .X) {
            while (true) {
                g.player_move() catch |err| {
                    std.debug.print("Invalid move: {}\n", .{err});
                    continue;
                };
                break;
            }
        } else if (g.current_player == .O) {
            const choice, _ = alphabeta(&g, -1_000_000, 1_000_000);
            g.place_move(choice) catch |err| {
                std.debug.print("AI requested invalid move: {}\n", .{err});
                return;
            };
        }
    }
}

fn alphabeta(g: *game.Game, alpha_in: i32, beta_in: i32) struct { usize, i32 } {
    switch (g.check_winner()) {
        .X => return .{ 0, 10 },
        .O => return .{ 0, -10 },
        .Empty => if (g.is_draw()) return .{ 0, 0 },
    }

    var alpha = alpha_in;
    var beta = beta_in;

    const choices = g.get_open_spots();
    defer std.heap.page_allocator.free(choices);

    var bestMove: usize = 0;
    var bestScore: i32 = if (g.current_player == .X) -1_000_000 else 1_000_000;
    for (choices) |choice| {
        g.place_move(choice) catch |err| {
            std.debug.print("Unexpected error placing AI move: {}\n", .{err});
            return .{ 0, 0 };
        };

        _, const score = alphabeta(g, alpha, beta);

        g.undo_move(choice) catch |err| {
            std.debug.print("Unexpected error undoing AI move: {}\n", .{err});
            return .{ 0, 0 };
        };

        if (g.current_player == .X) {
            if (score > bestScore) {
                bestScore = score;
                bestMove = choice;
            }

            if (bestScore > beta) break; // Prune
            if (bestScore > alpha) alpha = bestScore;
        } else if (g.current_player == .O) {
            if (score < bestScore) {
                bestScore = score;
                bestMove = choice;
            }

            if (bestScore < alpha) break; // Prune
            if (bestScore < beta) beta = bestScore;
        }
    }

    return .{ bestMove, bestScore };
}
