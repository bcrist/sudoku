//! A set of values are defined to be "sentinels" (usually 1 and 9).
//! When the cells in a region are iterated, any cells that appear between these sentinel values are summed.
//! The final sum must equal a constant.
//! Optionally, the constraint can be inverted, so that the first sentinel visited disables summing cells, instead of enabling it.
//! If the region contains more than two sentinels (more than 1 in the inverted case) then there may be several separate sections of cells that contribute to the sum.
//! a.k.a. Sandwich sudoku
region: Region,
sum: u64,
sentinels: Cell.Value_Options,
direction: Cell.Iteration_Direction,
sum_before_first_sentinel: bool,

pub const Init_Options = struct {
    sentinels: Cell.Value_Options = Cell.options("1 9"),
    direction: Cell.Iteration_Direction = .forward,
    sum_before_first_sentinel: bool = false,
};

pub fn init(sum: u64, region: Region, options: Init_Options) Sum_Between_Sentinels {
    return .{
        .region = region,
        .sum = sum,
        .sentinels = options.sentinels,
        .direction = options.direction,
        .sum_before_first_sentinel = options.sum_before_first_sentinel,
    };
}

pub fn evaluate(self: Sum_Between_Sentinels, config: *const Config, state: *State) error{NotSolvable}!void {
    try base.evaluate_sum_cells(config, state, self.iterator(config, state), self.sum, self.sum);
}

fn iterator(self: Sum_Between_Sentinels, config: *const Config, state: *const State) Iterator {
    return .{
        .inner = self.region.iterator(self.direction),
        .sentinels = self.sentinels,
        .config = config,
        .state = state,
        .summing = self.sum_before_first_sentinel,
        .last_options = .initEmpty(),
        .abort = false,
    };
}

const Iterator = struct {
    inner: Region.Iterator,
    sentinels: Cell.Value_Options,
    config: *const Config,
    state: *const State,
    summing: bool,
    abort: bool,
    last_options: Cell.Value_Options,

    pub fn next(self: *Iterator) ?Cell {
        while (self.inner.next()) |cell| {
            const options = self.state.get(self.config, cell);
            if (options.intersectWith(self.sentinels).eql(.initEmpty())) {
                // This cell is a non-sentinel; we either need to sum it or skip it depending on the mode.
                if (self.summing) {
                    self.last_options = options;
                    return cell;
                }
            } else if (options.intersectWith(self.sentinels.complement()).eql(.initEmpty())) {
                // This cell has no options other than to be a sentinel; toggle summing behavior
                self.summing = !self.summing;
            } else {
                // This cell may or may not be a sentinel.  Since this means we don't yet know which set of cells to sum, we should just give up for now
                self.abort = true;
                self.inner = .done;
                return null;
            }
        }
        return null;
    }
};

const Sum_Between_Sentinels = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");
