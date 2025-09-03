//! Requires that for two cells A and B, the ratio of @max(A, B) to @min(A, B) is an exact integer value.
//! a.k.a. Black Kropki (without negative constraint)

a: Cell,
b: Cell,
ratio: u8,

pub fn init(ratio: u8, cell: Cell, direction: Cell.Direction) Ratio_Cells {
    return .{
        .a = cell,
        .b = cell.neighbor(direction).?,
        .ratio = ratio,
    };
}

pub fn num_regions(_: Ratio_Cells) usize {
    return 2;
}

pub fn get_region(self: Ratio_Cells, region: usize) Region {
    return .single(.{ .offset = switch (region) {
        0 => self.a,
        1 => self.b,
        else => unreachable,
    }});
}

pub fn evaluate(self: Ratio_Cells, config: *const Config, state: *State) error{NotSolvable}!void {
    const a_options = state.get(config, self.a);
    const b_options = state.get(config, self.b);
    _ = state.intersect(config, self.a, self.get_new_options(b_options));
    _ = state.intersect(config, self.b, self.get_new_options(a_options));
}

fn get_new_options(self: Ratio_Cells, other: Cell.Value_Options) Cell.Value_Options {
    var result: Cell.Value_Options = .initEmpty();
    var iter = other.iterator(.{});
    while (iter.next()) |value| {
        const higher = value * self.ratio;
        if (higher < 64) result.set(higher);

        const lower = value / self.ratio;
        if (lower * self.ratio == value) result.set(lower);
    }
    return result;
}

const Ratio_Cells = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
