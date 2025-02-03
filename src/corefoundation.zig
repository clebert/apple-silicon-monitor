const std = @import("std");

/// https://developer.apple.com/documentation/corefoundation/cfallocatorref?language=objc
pub const CFAllocatorRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfarrayref?language=objc
pub const CFArrayRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfdictionarykeycallbacks?language=objc
pub const CFDictionaryKeyCallBacks = anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfdictionaryref?language=objc
pub const CFDictionaryRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfdictionaryvaluecallbacks?language=objc
pub const CFDictionaryValueCallBacks = anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfindex?language=objc
pub const CFIndex = i64;

/// https://developer.apple.com/documentation/corefoundation/cfnumberref?language=objc
pub const CFNumberRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cfnumbertype?language=objc
pub const CFNumberType = enum(CFIndex) {
    kCFNumberSInt8Type = 1,
    kCFNumberSInt16Type = 2,
    kCFNumberSInt32Type = 3,
    kCFNumberSInt64Type = 4,
    kCFNumberFloat32Type = 5,
    kCFNumberFloat64Type = 6,
};

/// https://developer.apple.com/documentation/corefoundation/cfstringencoding?language=objc
pub const CFStringEncoding = u32;

/// https://developer.apple.com/documentation/corefoundation/cfstringbuiltinencodings?language=objc
pub const CFStringBuiltInEncodings = enum(CFStringEncoding) { kCFStringEncodingUTF8 = 0x08000100 };

/// https://developer.apple.com/documentation/corefoundation/cfstringref?language=objc
pub const CFStringRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/cftyperef?language=objc
pub const CFTypeRef = *anyopaque;

/// https://developer.apple.com/documentation/corefoundation/1388772-cfarraygetcount?language=objc
pub extern "c" fn CFArrayGetCount(theArray: CFArrayRef) CFIndex;

/// https://developer.apple.com/documentation/corefoundation/1388767-cfarraygetvalueatindex?language=objc
pub extern "c" fn CFArrayGetValueAtIndex(theArray: CFArrayRef, index: CFIndex) CFTypeRef;

/// https://developer.apple.com/documentation/corefoundation/1516782-cfdictionarycreate?language=objc
pub extern "c" fn CFDictionaryCreate(
    allocator: CFAllocatorRef,
    keys: [*]const CFTypeRef,
    values: [*]const CFTypeRef,
    numValues: CFIndex,
    keyCallBacks: *const CFDictionaryKeyCallBacks,
    valueCallBacks: *const CFDictionaryValueCallBacks,
) CFDictionaryRef;

/// https://developer.apple.com/documentation/corefoundation/1542182-cfnumbercreate?language=objc
pub extern "c" fn CFNumberCreate(
    allocator: CFAllocatorRef,
    theType: CFNumberType,
    valuePtr: *const anyopaque,
) CFNumberRef;

/// https://developer.apple.com/documentation/corefoundation/1543114-cfnumbergetvalue?language=objc
pub extern "c" fn CFNumberGetValue(
    number: CFNumberRef,
    theType: CFNumberType,
    valuePtr: *anyopaque,
) bool;

/// https://developer.apple.com/documentation/corefoundation/1542942-cfstringcreatewithcstring?language=objc
pub extern "c" fn CFStringCreateWithCString(
    allocator: CFAllocatorRef,
    cStr: [*:0]const u8,
    encoding: CFStringEncoding,
) CFStringRef;

/// https://developer.apple.com/documentation/corefoundation/1542133-cfstringgetcstringptr?language=objc
pub extern "c" fn CFStringGetCStringPtr(
    theString: CFStringRef,
    encoding: CFStringEncoding,
) [*:0]const u8;

/// https://developer.apple.com/documentation/corefoundation/1521153-cfrelease?language=objc
pub extern "c" fn CFRelease(cf: CFTypeRef) void;

/// https://developer.apple.com/documentation/corefoundation/kcfallocatordefault?language=objc
pub extern "c" const kCFAllocatorDefault: CFAllocatorRef;

/// https://developer.apple.com/documentation/corefoundation/kcftypedictionarykeycallbacks?language=objc
pub extern "c" const kCFTypeDictionaryKeyCallBacks: CFDictionaryKeyCallBacks;

/// https://developer.apple.com/documentation/corefoundation/kcftypedictionaryvaluecallbacks?language=objc
pub extern "c" const kCFTypeDictionaryValueCallBacks: CFDictionaryValueCallBacks;

////////////////////////////////////////////////////////////////////////////////////////////////////

pub fn Array(comptime T: type) type {
    return struct {
        ref: CFArrayRef,

        pub fn release(self: *@This()) void {
            CFRelease(self.ref);

            self.* = undefined;
        }

        pub fn getCount(self: @This()) usize {
            return @intCast(CFArrayGetCount(self.ref));
        }

        pub fn getValueAtIndex(self: @This(), index: usize) T {
            return .{ .ref = CFArrayGetValueAtIndex(self.ref, @intCast(index)) };
        }
    };
}

pub fn Dictionary(comptime K: type, comptime V: type) type {
    return struct {
        ref: CFDictionaryRef,

        pub fn create(
            key_refs: []const @FieldType(K, "ref"),
            value_refs: []const @FieldType(V, "ref"),
        ) ?@This() {
            std.debug.assert(key_refs.len == value_refs.len);

            const ref = CFDictionaryCreate(
                kCFAllocatorDefault,
                key_refs.ptr,
                value_refs.ptr,
                @intCast(key_refs.len),
                &kCFTypeDictionaryKeyCallBacks,
                &kCFTypeDictionaryValueCallBacks,
            );

            return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
        }

        pub fn release(self: *@This()) void {
            CFRelease(self.ref);

            self.* = undefined;
        }
    };
}

pub fn Number(comptime T: type) type {
    const number_type = switch (T) {
        i8 => |_| CFNumberType.kCFNumberSInt8Type,
        i16 => |_| CFNumberType.kCFNumberSInt16Type,
        i32 => |_| CFNumberType.kCFNumberSInt32Type,
        i64 => |_| CFNumberType.kCFNumberSInt64Type,
        f32 => |_| CFNumberType.kCFNumberFloat32Type,
        f64 => |_| CFNumberType.kCFNumberFloat64Type,
        else => @compileError("Unsupported number type."),
    };

    return struct {
        ref: CFNumberRef,

        pub fn create(value: T) ?@This() {
            const ref = CFNumberCreate(kCFAllocatorDefault, number_type, &value);

            return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
        }

        pub fn release(self: *@This()) void {
            CFRelease(self.ref);

            self.* = undefined;
        }

        pub fn getValue(self: @This()) T {
            var value: T = undefined;

            _ = CFNumberGetValue(self.ref, number_type, &value);

            return value;
        }
    };
}

pub const String = struct {
    ref: CFStringRef,

    pub fn createWithCString(c_string: [*:0]const u8) ?@This() {
        const ref = CFStringCreateWithCString(
            kCFAllocatorDefault,
            c_string,
            @intFromEnum(CFStringBuiltInEncodings.kCFStringEncodingUTF8),
        );

        return if (@intFromPtr(ref) == 0) null else .{ .ref = ref };
    }

    pub fn release(self: *@This()) void {
        CFRelease(self.ref);

        self.* = undefined;
    }

    pub fn getCString(self: @This()) [*:0]const u8 {
        return CFStringGetCStringPtr(
            self.ref,
            @intFromEnum(CFStringBuiltInEncodings.kCFStringEncodingUTF8),
        );
    }

    pub fn getSlice(self: @This()) []const u8 {
        return std.mem.span(self.getCString());
    }
};
