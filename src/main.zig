const std = @import("std");

const corefoundation = @import("corefoundation.zig");
const iokit = @import("iokit.zig");

pub fn main() !void {
    var event_system = iokit.HIDEventSystemClient.create().?;

    defer event_system.release();

    var key1 = corefoundation.String.createWithCString("PrimaryUsagePage").?;

    defer key1.release();

    var value1 = corefoundation.Number(i32).create(iokit.kHIDPage_AppleVendor).?;

    defer value1.release();

    var key2 = corefoundation.String.createWithCString("PrimaryUsage").?;

    defer key2.release();

    var value2 = corefoundation.Number(i32).create(iokit.kHIDUsage_AppleVendor_TemperatureSensor).?;

    defer value2.release();

    var matching = corefoundation.Dictionary(
        corefoundation.String,
        corefoundation.Number(i32),
    ).create(&.{ key1.ref, key2.ref }, &.{ value1.ref, value2.ref }).?;

    defer matching.release();

    event_system.setMatching(matching);

    var services = event_system.copyServices().?;

    defer services.release();

    var product_key = corefoundation.String.createWithCString("Product").?;

    defer product_key.release();

    for (0..services.getCount()) |index| {
        const service = services.getValueAtIndex(index);

        var product = service.copyProperty(corefoundation.String, product_key) orelse continue;

        defer product.release();

        var temperature_event = service.copyTemperatureEvent() orelse continue;

        defer temperature_event.release();

        const temperature_value = temperature_event.getTemperatureValue();

        std.debug.print("{d:.2}°C ({s})\n", .{ temperature_value, product.getSlice() });
    }
}
