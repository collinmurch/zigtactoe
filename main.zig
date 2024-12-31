const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var g = game.Game.init(.X);
    try stdout.writeAll("You play as X.\n");

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
                while (true) {
                    const input = request_move(stdin, stdout) catch |err| {
                        std.debug.print("Bad move type: {}\n", .{err});
                        continue;
                    };

                    g.place_move(input) catch |err| {
                        std.debug.print("Invalid move: {}\n", .{err});
                        continue;
                    };

                    break;
                }
            },
            .O => {
                const result = alphabeta(&g, -1_000_000, 1_000_000);
                g.place_move(result[0]) catch |err| {
                    std.debug.print("AI requested invalid move! Err: {}\n", .{err});
                    return;
                };
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
            std.debug.print("Unexpected error placing open AI move: {}\n", .{err});
            return .{ 0, 0 };
        };

        _, const score = alphabeta(g, alpha, beta);

        g.undo_move(choice) catch |err| {
            std.debug.print("Unexpected error undoing open AI move: {}\n", .{err});
            return .{ 0, 0 };
        };

        if (g.current_player == .X) {
            if (score > bestScore) {
                bestScore = score;
                bestMove = choice;
            }

            if (bestScore > beta) {
                break; // Prune
            }

            if (bestScore > alpha) {
                alpha = bestScore;
            }
        } else if (g.current_player == .O) {
            if (score < bestScore) {
                bestScore = score;
                bestMove = choice;
            }

            if (bestScore < alpha) {
                break; // Prune
            }

            if (bestScore < beta) {
                beta = bestScore;
            }
        }
    }

    return .{ bestMove, bestScore };
}
