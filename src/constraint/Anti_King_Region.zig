//! Requires that no cell in the region has the same value as another cell in the region which can be visited by a King's move in chess (exactly 1 different in one one or both coordinates)

region: Region,
        
pub fn evaluate(self: @This(), config: Config, state: *State) State.Solve_Status {
    _ = self;
    _ = config;
    _ = state;
    // TODO
    return .not_solvable;
}

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
