//! For at least two regions, the sum of the values in all cells in each region must be the same.
//! a.k.a. "?" Killer Cages, Arrows with single cell sum
//! Note this doesn't enforce uniqueness of cells in the regions; use Unique_Region constraint(s) for that if necessary.

regions: []const Region,
        
pub fn evaluate(self: @This(), config: *const Config, state: *State) State.Solve_Status {
    _ = self;
    _ = config;
    _ = state;
    // TODO
    return .not_solvable;
}

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
