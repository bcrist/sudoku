//! For each value between the minimum and maximum values that appear in a region, requires that at least one cell in a region has that value.
//! a.k.a. White Kropki (without negative constraint), Renban lines
//! Note this doesn't enforce uniqueness of all cells in the region; use a separate Unique_Region constraint for that if necessary.

region: Region,
        
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
