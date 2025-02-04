const std = @import("std");

const corefoundation = @import("corefoundation.zig");
const iokit = @import("iokit.zig");
const Temperature = @import("temperature.zig");
const VT100 = @import("vt100.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    defer if (gpa.deinit() == .leak) unreachable;

    const allocator = gpa.allocator();

    var temperature = try Temperature.init(allocator);

    defer temperature.deinit();

    const stdout = std.io.getStdOut().writer();

    while (true) {
        try temperature.readAllSensors();

        try VT100.ControlSequence.write(.{ .cursorPosition = .{} }, stdout);

        var iterator = temperature.sensor_by_name.iterator();

        while (iterator.next()) |entry| {
            const sensor_name = entry.key_ptr.*;
            const sensor = entry.value_ptr.*;

            try VT100.ControlSequence.write(.{ .eraseInLine = .end }, stdout);

            try stdout.print(
                "current: {d:.2}°C | max: {d:.2}°C | min: {d:.2}°C | {s}\n",
                .{
                    sensor.current_temperature,
                    sensor.max_temperature,
                    sensor.min_temperature,
                    sensor_name,
                },
            );
        }

        std.Thread.sleep(500_000_000); // 500 ms
    }
}

test {
    std.testing.refAllDecls(@This());
}
