//! Requires that the sum of the values in all cells of a region equals a fixed, known value.
//! a.k.a. Killer Cages, Diagonal Sums, X-V (without negative constraint)
//! Note this doesn't enforce uniqueness of all cells in the region; use a separate Unique_Region constraint for that if necessary.
    
region: Region,
sum: u64,

pub fn init(sum: u64, region: Region) Sum_Region {
    return .{
        .region = region,
        .sum = sum,
    };
}

pub fn evaluate(self: Sum_Region, config: *const Config, state: *State) error{NotSolvable}!void {
    try base.evaluate_sum_cells(config, state, self.region.iterator(.forward), self.sum);
}

const Sum_Region = @This();

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");