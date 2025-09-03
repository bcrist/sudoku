//! Requires that all cells in the region contain the same value
//! Note all Equal_Cell constraints could be expressed as Equal_Sum_Regions constraints, but this provides easier configuration for a subset of use cases.

region: Region,
        
pub fn evaluate(self: @This(), config: *const Config, state: *State) error{NotSolvable}!void {
    var options: Cell.Value_Options = .initFull();
    var iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        options.setIntersection(state.get(config, cell));
    }

    iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        _ = state.intersect(config, cell, options);
    }
}

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
