const std = @import("std");
const Game = @import("game.zig").Game;

fn requestMove(reader: std.fs.File.Reader, writer: std.fs.File.Writer) !usize {
    var buf: [10]u8 = undefined;

    try writer.writeAll("Enter a move [1-9]: ");
    if (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        return std.fmt.parseInt(usize, user_input, 10);
    }

    return 0;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var game = Game.init();
    try game.printBoard(stdout);
    const input = try requestMove(stdin, stdout);
    try stdout.print("Entered: {d}\n", .{input});
}
