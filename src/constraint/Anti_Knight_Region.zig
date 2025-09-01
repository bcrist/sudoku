//! Requires that no cell in the region has the same value as another cell in the region which can be visited by a Knight's move in chess (exactly 1 different in one coordinate and exactly 2 different in the other)

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
