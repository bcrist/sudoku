//! Restricts the set of "digits" to be used.
//! All puzzles should have at least one constraint like this, which covers all cells in the puzzle.
//! In rare cases, you might have multiple, non-overlapping Values constraints; e.g. if part of the puzzle uses 1-9 and a different part uses 1-6
//! Values constraints can also be used for rules like odd/even regions

region: Region,
values: Cell.Value_Options,

pub const _4x4: Values = .init_square(4);
pub const _6x6: Values = .init_square(6);
pub const _9x9: Values = .init_square(9);
pub const _12x12: Values = .init_square(12);
pub const _16x16: Values = .init_square(16);

pub fn init_square(dim: usize) Values {
    return .init_range(1, dim, .single(.{ .dim = dim }));
}

pub fn init_range(min: usize, max: usize, region: Region) Values {
    var v: Cell.Value_Options = .initEmpty();
    v.setRangeValue(.{
        .start = min,
        .end = max + 1,
    }, true);
    return .{
        .region = region,
        .values = v,
    };
}

pub fn init_odd(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = 0b1010101010101010101010101010101010101010101010101010101010101010 },
    };
}

pub fn init_even(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = 0b0101010101010101010101010101010101010101010101010101010101010101 },
    };
}

pub fn init_prime(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = 0b0010100000100000100010100010000010100000100010100010100010101100 },
    };
}

pub fn init_composite(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = ~@as(u64, 0b0010100000100000100010100010000010100000100010100010100010101100) },
    };
}

pub fn init_fib(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = 0b0000000010000000000000000000010000000000001000000010000100101110 },
    };
}

pub fn init_non_fib(region: Region) Values {
    return .{
        .region = region,
        .values = .{ .mask = ~@as(u64, 0b0000000010000000000000000000010000000000001000000010000100101110) },
    };
}

pub fn evaluate(self: Values, config: *const Config, state: *State) error{NotSolvable}!void {
    const values = self.values;
    var iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        _ = state.intersect(config, cell, values);
    }
}

const Values = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
