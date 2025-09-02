//! Requires that the sum of values in each region is larger than the sum from the previous region.
//! Note this doesn't enforce uniqueness of cells in the regions; use Unique_Region constraint(s) for that if necessary.

regions: []const Region,
        
pub fn evaluate(self: @This(), config: *const Config, state: *State) error{NotSolvable}!void {
    _ = self;
    _ = config;
    _ = state;
    // TODO
    return .not_solvable;
}

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
