//! Requires that for two cells A and B, the ratio of @max(A, B) to @min(A, B) is an exact integer value.
//! a.k.a. Black Kropki (without negative constraint)

a: Cell,
b: Cell,
ratio: u8,

pub fn init(ratio: u8, a: Cell, b: Cell) Ratio_Cells {
    return .{
        .a = a,
        .b = b,
        .ratio = ratio,
    };
}

pub fn init_kropki(a: Cell, b: Cell) Ratio_Cells {
    return .init(2, a, b);
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

pub fn evaluate(self: Ratio_Cells, config: *const Config, state: *State) State.Solve_Status {
    _ = self;
    _ = config;
    _ = state;
    // TODO
    return .not_solvable;
}

const Ratio_Cells = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
