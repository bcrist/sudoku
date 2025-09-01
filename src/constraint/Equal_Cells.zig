//! Requires that all cells in the region contain the same value
//! Note all Equal_Cell constraints could be expressed as Equal_Sum_Regions constraints, but this provides easier configuration for a subset of use cases.

region: Region,
        
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
