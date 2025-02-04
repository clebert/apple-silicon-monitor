const std = @import("std");

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

            const style_color = switch (sensor.getColor()) {
                .green => VT100.ControlSequence.style_green,
                .red => VT100.ControlSequence.style_red,
                .yellow => VT100.ControlSequence.style_yellow,
            };

            try stdout.print(
                "current: {s}{d:.2}°C{s} | max: {d:.2}°C | min: {d:.2}°C | {s}\n",
                .{
                    style_color,
                    sensor.current_temperature,
                    VT100.ControlSequence.style_default,
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
