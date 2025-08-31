x: u16,
y: u16,

pub fn init(x: usize, y: usize) Cell {
    return .{
        .x = @intCast(x),
        .y = @intCast(y),
    };
}

pub fn expand_bounds(self: Cell, bounds: *Rect) void {
    if (bounds.width() == 0 or bounds.height() == 0) {
        bounds.min = self;
        bounds.max = self;
    } else {
        bounds.min.x = @min(self.x, bounds.min.x);
        bounds.min.y = @min(self.y, bounds.min.y);
        bounds.max.x = @max(self.x, bounds.max.x);
        bounds.max.y = @max(self.y, bounds.max.y);
    }
}

pub const origin: Cell = .init(0, 0);

pub const Value_Options = std.bit_set.IntegerBitSet(64);

pub const Index = enum (u32) {
    invalid = 0xFFFF_FFFF,
    _,

    pub fn init(i: usize) Index {
        return @enumFromInt(i);
    }

    pub fn maybe_raw(self: Index) ?u32 {
        if (self == .invalid) return null;
        return @intFromEnum(self);
    }

    pub fn raw(self: Index) u32 {
        std.debug.assert(self != .invalid);
        return @intFromEnum(self);
    }
};

const Cell = @This();

const Rect = @import("Rect.zig");
const std = @import("std");
