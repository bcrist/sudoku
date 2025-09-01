//! Requires that each cell in the region contains a larger value than the previous one
//! a.k.a. Thermometers
//! Note only single cell Rects should be used in the region to ensure expected iteration order.
//! Note all Ascending_Cells constraints could be expressed as Ascending_Sum_Regions constraints, but this provides easier configuration for a subset of use cases.

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
