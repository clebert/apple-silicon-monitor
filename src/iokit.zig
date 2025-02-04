const corefoundation = @import("corefoundation.zig");

pub const IOHIDEventRef = *opaque {};

/// https://developer.apple.com/documentation/iokit/iohideventsystemclientref?language=objc
pub const IOHIDEventSystemClientRef = *opaque {};

/// https://developer.apple.com/documentation/iokit/iohidserviceclientref?language=objc
pub const IOHIDServiceClientRef = *opaque {};

pub extern "c" fn IOHIDEventGetFloatValue(event: IOHIDEventRef, field: i32) f64;

/// https://developer.apple.com/documentation/iokit/2269511-iohideventsystemclientcopyservic?language=objc
pub extern "c" fn IOHIDEventSystemClientCopyServices(
    client: IOHIDEventSystemClientRef,
) corefoundation.CFArrayRef;

pub extern "c" fn IOHIDEventSystemClientCreate(
    allocator: corefoundation.CFAllocatorRef,
) IOHIDEventSystemClientRef;

pub extern "c" fn IOHIDEventSystemClientSetMatching(
    client: IOHIDEventSystemClientRef,
    matching: corefoundation.CFDictionaryRef,
) i32;

pub extern "c" fn IOHIDServiceClientCopyEvent(
    service: IOHIDServiceClientRef,
    type: i64,
    options: i32,
    timestamp: i64,
) IOHIDEventRef;

/// https://developer.apple.com/documentation/iokit/2269430-iohidserviceclientcopyproperty?language=objc
pub extern "c" fn IOHIDServiceClientCopyProperty(
    service: IOHIDServiceClientRef,
    key: corefoundation.CFStringRef,
) corefoundation.CFTypeRef;

pub fn IOHIDEventFieldBase(@"type": i64) i32 {
    return @intCast(@"type" << 16);
}

const kIOHIDEventTypeTemperature = 15;

////////////////////////////////////////////////////////////////////////////////////////////////////

pub const HIDEvent = struct {
    ref: IOHIDEventRef,

    pub fn release(self: *@This()) void {
        corefoundation.CFRelease(self.ref);

        self.* = undefined;
    }

    pub fn getTemperatureValue(self: @This()) f64 {
        return IOHIDEventGetFloatValue(self.ref, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
    }
};

pub const HIDEventSystemClient = struct {
    ref: IOHIDEventSystemClientRef,

    pub fn create() ?@This() {
        const ref = IOHIDEventSystemClientCreate(corefoundation.kCFAllocatorDefault);

        return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
    }

    pub fn release(self: *@This()) void {
        corefoundation.CFRelease(self.ref);

        self.* = undefined;
    }

    pub fn copyServices(self: @This()) ?corefoundation.Array(HIDServiceClient) {
        const ref = IOHIDEventSystemClientCopyServices(self.ref);

        return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
    }

    pub fn setTemperatureSensorMatching(self: @This()) void {
        var primary_usage_page_key = corefoundation.String.createWithCString("PrimaryUsagePage").?;

        defer primary_usage_page_key.release();

        // https://github.com/acidanthera/MacKernelSDK/blob/a2ba595133100d5d3bba02c54819b46b792ed6aa/Headers/IOKit/hid/AppleHIDUsageTables.h#L35
        var primary_usage_page_value = corefoundation.Number(i32).create(0xFF00).?;

        defer primary_usage_page_value.release();

        var primary_usage_key = corefoundation.String.createWithCString("PrimaryUsage").?;

        defer primary_usage_key.release();

        // https://github.com/acidanthera/MacKernelSDK/blob/a2ba595133100d5d3bba02c54819b46b792ed6aa/Headers/IOKit/hid/AppleHIDUsageTables.h#L68
        var primary_usage_value = corefoundation.Number(i32).create(5).?;

        defer primary_usage_value.release();

        var temperature_sensor_matching = corefoundation.Dictionary(
            corefoundation.String,
            corefoundation.Number(i32),
        ).create(
            &.{ primary_usage_page_key.ref, primary_usage_key.ref },
            &.{ primary_usage_page_value.ref, primary_usage_value.ref },
        ).?;

        defer temperature_sensor_matching.release();

        _ = IOHIDEventSystemClientSetMatching(self.ref, temperature_sensor_matching.ref);
    }
};

pub const HIDServiceClient = struct {
    ref: IOHIDServiceClientRef,

    pub fn release(self: *@This()) void {
        corefoundation.CFRelease(self.ref);

        self.* = undefined;
    }

    pub fn copyTemperatureEvent(self: @This()) ?HIDEvent {
        const ref = IOHIDServiceClientCopyEvent(self.ref, kIOHIDEventTypeTemperature, 0, 0);

        return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
    }

    pub fn copyProperty(self: @This(), comptime T: type, key: corefoundation.String) ?T {
        const ref = IOHIDServiceClientCopyProperty(self.ref, key.ref);

        return if (@intFromPtr(ref) == 0) null else .{ .ref = @ptrCast(ref) };
    }
};
