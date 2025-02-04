const std = @import("std");

const buffer_size = 44;
const esc = "\x1b";

const ControlCommand = enum { cursorPosition, eraseInLine };

pub const ControlSequence = union(ControlCommand) {
    pub const style_default = esc ++ "[0m";
    pub const style_green = esc ++ "[32m";
    pub const style_red = esc ++ "[31m";
    pub const style_yellow = esc ++ "[33m";

    /// https://vt100.net/docs/vt100-ug/chapter3.html#CUP
    cursorPosition: struct { line: u64 = 1, column: u64 = 1 },

    /// https://vt100.net/docs/vt100-ug/chapter3.html#EL
    eraseInLine: enum(u8) { end, start, all },

    pub fn write(self: @This(), writer: anytype) !void {
        var buffer: [buffer_size]u8 = undefined;

        try writer.writeAll(try self.stringify(&buffer));
    }

    fn stringify(self: @This(), buffer: []u8) ![]u8 {
        return switch (self) {
            .cursorPosition => |params| try std.fmt.bufPrint(
                buffer,
                esc ++ "[{d};{d}H",
                .{ params.line, params.column },
            ),

            .eraseInLine => |params| try std.fmt.bufPrint(
                buffer,
                esc ++ "[{d}K",
                .{@intFromEnum(params)},
            ),
        };
    }
};

test "stringify cursorPosition" {
    var buffer: [buffer_size]u8 = undefined;

    try std.testing.expectEqualStrings(
        esc ++ "[1;1H",
        try ControlSequence.stringify(.{ .cursorPosition = .{} }, &buffer),
    );

    try std.testing.expectEqualStrings(
        esc ++ "[10;5H",
        try ControlSequence.stringify(.{ .cursorPosition = .{ .line = 10, .column = 5 } }, &buffer),
    );

    const max_int = std.math.maxInt(u64);

    try std.testing.expectEqualStrings(
        esc ++ "[18446744073709551615;18446744073709551615H",
        try ControlSequence.stringify(
            .{ .cursorPosition = .{ .line = max_int, .column = max_int } },
            &buffer,
        ),
    );
}

test "stringify eraseInLine" {
    var buffer: [buffer_size]u8 = undefined;

    try std.testing.expectEqualStrings(
        esc ++ "[0K",
        try ControlSequence.stringify(.{ .eraseInLine = .end }, &buffer),
    );

    try std.testing.expectEqualStrings(
        esc ++ "[1K",
        try ControlSequence.stringify(.{ .eraseInLine = .start }, &buffer),
    );

    try std.testing.expectEqualStrings(
        esc ++ "[2K",
        try ControlSequence.stringify(.{ .eraseInLine = .all }, &buffer),
    );
}
