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

pub fn options(debug: []const u8) Value_Options {
    var o: Value_Options = .initEmpty();
    for (debug) |ch| switch (ch) {
        '0'...'9' => o.set(ch - '0'),
        'a'...'z' => o.set(ch - 'a' + 10),
        'A'...'Z' => o.set(ch - 'A' + 36),
        '@' => o.set(62),
        '#' => o.set(63),
        else => o = .initFull(),
    };
    return o;
}

pub fn debug_options(o: Value_Options) u8 {
    return switch (o.count()) {
        0 => ' ',
        1 => ch: {
            const value = o.findFirstSet().?;
            break :ch switch (value) {
                0...9 => @intCast('0' + value),
                10...35 => @intCast('a' + value - 10),
                36...61 => @intCast('A' + value - 36),
                62 => '@',
                63 => '#',
                else => unreachable,
            };
        },
        64 => '*',
        else => '?',
    };
}

pub const origin: Cell = .init(0, 0);

pub const Value_Options = std.bit_set.IntegerBitSet(64);

pub const Iteration_Direction = enum {
    forward, // left-to-right, top-to-bottom
    reverse, // right-to-left, bottom-to-top
};

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
