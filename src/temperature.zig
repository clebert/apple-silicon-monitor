const std = @import("std");

const corefoundation = @import("corefoundation.zig");
const iokit = @import("iokit.zig");

const Sensor = struct { current_temperature: f64, max_temperature: f64, min_temperature: f64 };

sensor_by_name: *std.StringArrayHashMap(Sensor),

pub fn init(allocator: std.mem.Allocator) !@This() {
    const sensor_by_name = try allocator.create(std.StringArrayHashMap(Sensor));

    sensor_by_name.* = std.StringArrayHashMap(Sensor).init(allocator);

    return .{ .sensor_by_name = sensor_by_name };
}

pub fn deinit(self: *@This()) void {
    const allocator = self.sensor_by_name.allocator;

    for (self.sensor_by_name.keys()) |key| {
        allocator.free(key);
    }

    self.sensor_by_name.deinit();
    allocator.destroy(self.sensor_by_name);

    self.* = undefined;
}

pub fn readAllSensors(self: @This()) !void {
    var event_system = iokit.HIDEventSystemClient.create().?;

    defer event_system.release();

    event_system.setTemperatureSensorMatching();

    var services = event_system.copyServices().?;

    defer services.release();

    var product_key = corefoundation.String.createWithCString("Product").?;

    defer product_key.release();

    for (0..services.getCount()) |index| {
        const service = services.getValueAtIndex(index);

        var temperature_event = service.copyTemperatureEvent() orelse continue;

        defer temperature_event.release();

        const temperature_value = temperature_event.getTemperatureValue();

        var product = service.copyProperty(corefoundation.String, product_key) orelse continue;

        defer product.release();

        try self.updateSensor(product.getSlice(), temperature_value);
    }

    self.sensor_by_name.sort(SortContext{ .sensor_by_name = self.sensor_by_name });
}

const SortContext = struct {
    sensor_by_name: *const std.StringArrayHashMap(Sensor),

    pub fn lessThan(self: @This(), a_index: usize, b_index: usize) bool {
        const names = self.sensor_by_name.keys();

        return std.mem.lessThan(u8, names[a_index], names[b_index]);
    }
};

fn updateSensor(self: @This(), name: []const u8, temperature_value: f64) !void {
    if (self.sensor_by_name.getEntry(name)) |entry| {
        const sensor = entry.value_ptr;

        try self.sensor_by_name.put(entry.key_ptr.*, .{
            .current_temperature = temperature_value,
            .max_temperature = @max(temperature_value, sensor.max_temperature),
            .min_temperature = @min(temperature_value, sensor.min_temperature),
        });
    } else {
        try self.sensor_by_name.put(try self.sensor_by_name.allocator.dupe(u8, name), .{
            .current_temperature = temperature_value,
            .max_temperature = temperature_value,
            .min_temperature = temperature_value,
        });
    }
}
