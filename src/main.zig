const std = @import("std");

const corefoundation = @import("corefoundation.zig");
const iokit = @import("iokit.zig");

pub fn main() !void {
    var event_system = iokit.HIDEventSystemClient.create().?;

    defer event_system.release();

    event_system.setTemperatureSensorMatching();

    var services = event_system.copyServices().?;

    defer services.release();

    std.debug.print("Found {d} temperature sensors:\n\n", .{services.getCount()});

    var product_key = corefoundation.String.createWithCString("Product").?;

    defer product_key.release();

    for (0..services.getCount()) |index| {
        const service = services.getValueAtIndex(index);

        var temperature_event = service.copyTemperatureEvent() orelse continue;

        defer temperature_event.release();

        const temperature_value = temperature_event.getTemperatureValue();

        var product = service.copyProperty(corefoundation.String, product_key) orelse
            corefoundation.String.createWithCString("unknown").?;

        defer product.release();

        std.debug.print("{d:.2}°C ({s})\n", .{ temperature_value, product.getSlice() });
    }
}
