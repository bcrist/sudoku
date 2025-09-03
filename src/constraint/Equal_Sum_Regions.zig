//! For at least two regions, the sum of the values in all cells in each region must be the same.
//! a.k.a. "?" Killer Cages, Arrows with single cell sum
//! Note this doesn't enforce uniqueness of cells in the regions; use Unique_Region constraint(s) for that if necessary.

regions: []const Region,
        
pub fn evaluate(self: @This(), config: *const Config, state: *State) error{NotSolvable}!void {
    var min_sum: usize = 0;
    var max_sum: usize = std.math.maxInt(usize);

    for (self.regions) |region| {
        var min: u64 = 0;
        var max: u64 = 0;

        var iter = region.iterator(.forward);
        while (iter.next()) |cell| {
            const options = state.get(config, cell);
            min += options.findFirstSet() orelse 0;
            max += options.findLastSet() orelse 0;
        }

        min_sum = @max(min_sum, min);
        max_sum = @min(max_sum, max);
    }

    for (self.regions) |region| {
        try base.evaluate_sum_cells(config, state, region.iterator(.forward), min_sum, max_sum);
    }
}

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");
const std = @import("std");
