const std = @import("std");
const game = @import("game.zig");

pub fn requestMove(reader: std.fs.File.Reader, writer: std.fs.File.Writer) !usize {
    var buf: [10]u8 = undefined;

    try writer.writeAll("Enter a move [1-9]: ");
    if (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        const move = try std.fmt.parseInt(usize, user_input, 10);
        return move - 1;
    }

    return 0;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var g = game.Game.init(.X);
    try stdout.writeAll("You play as X.\n");

    var input: usize = undefined;
    while (true) {
        try g.printBoard(stdout);
        if (g.isWinner(.X)) {
            try stdout.writeAll("X wins!\n");
            break;
        } else if (g.isWinner(.O)) {
            try stdout.writeAll("O wins!\n");
            break;
        } else if (g.isDraw()) {
            try stdout.writeAll("It's a draw!\n");
            break;
        }

        input = try requestMove(stdin, stdout);
        try g.playerMove(input);
    }
}
