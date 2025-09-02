//! Requires that the value of two specific cells differs by a constant amount (usually 1)
//! a.k.a. White Kropki (without negative constraint)

a: Cell,
b: Cell,
difference: u6,

pub const Init_Options = struct {
    difference: u6 = 1,
};

pub fn init(cell: Cell, direction: Cell.Direction, options: Init_Options) Consecutive_Cells {
    return .{
        .a = cell,
        .b = cell.neighbor(direction).?,
        .difference = options.difference,
    };
}

pub fn num_regions(_: Consecutive_Cells) usize {
    return 2;
}

pub fn get_region(self: Consecutive_Cells, region: usize) Region {
    return .single(.{ .offset = switch (region) {
        0 => self.a,
        1 => self.b,
        else => unreachable,
    }});
}

pub fn evaluate(self: Consecutive_Cells, config: *const Config, state: *State) error{NotSolvable}!void {
    const a_options = state.get(config, self.a);
    const b_options = state.get(config, self.b);
    state.intersect(config, self.a, self.get_new_options(b_options));
    state.intersect(config, self.b, self.get_new_options(a_options));
}

fn get_new_options(self: Consecutive_Cells, other: Cell.Value_Options) Cell.Value_Options {
    return .{
        .mask = (other.mask << self.difference) | (other.mask >> self.difference),
    };
}

const Consecutive_Cells = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
