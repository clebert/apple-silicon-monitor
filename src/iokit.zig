const corefoundation = @import("corefoundation.zig");

/// https://github.com/acidanthera/MacKernelSDK/blob/a2ba595133100d5d3bba02c54819b46b792ed6aa/Headers/IOKit/hid/AppleHIDUsageTables.h
pub const kHIDPage_AppleVendor = 0xFF00;
pub const kHIDUsage_AppleVendor_TemperatureSensor = 0x0005;
pub const kIOHIDEventTypeTemperature = 15;

pub const IOHIDEventRef = *anyopaque;

/// https://developer.apple.com/documentation/iokit/iohideventsystemclientref?language=objc
pub const IOHIDEventSystemClientRef = *anyopaque;

/// https://developer.apple.com/documentation/iokit/iohidserviceclientref?language=objc
pub const IOHIDServiceClientRef = *anyopaque;

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

    pub fn setMatching(self: @This(), matching: corefoundation.Dictionary(
        corefoundation.String,
        corefoundation.Number(i32),
    )) void {
        _ = IOHIDEventSystemClientSetMatching(self.ref, matching.ref);
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

        return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
    }
};
