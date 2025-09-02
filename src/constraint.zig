
pub const Constraint = union (enum) {
    pub const Builder = @import("constraint/Builder.zig");

    values: Values,
    unique_region: Unique_Region,
    sum_region: Sum_Region,
    sum_between_sentinels: Sum_Between_Sentinels,
    //equal_sum_regions: Equal_Sum_Regions,
    //equal_cells: Equal_Cells,
    //ascending_sum_line: Ascending_Sum_Line,
    //ascending_cells: Ascending_Cells,
    consecutive_cells: Consecutive_Cells,
    ratio_cells: Ratio_Cells,
    anti_chess_region: Anti_Chess_Region,
    ranked_regions: Ranked_Regions,
    white_kropki: kropki.White,
    black_kropki: kropki.Black,
    xv_x: xv.X,
    xv_v: xv.V,
    unique_pairs_rect: misc.Unique_Pairs_Rect,

    pub const Values = @import("constraint/Values.zig");
    pub const Unique_Region = @import("constraint/Unique_Region.zig");
    pub const Sum_Region = @import("constraint/Sum_Region.zig");
    pub const Sum_Between_Sentinels = @import("constraint/Sum_Between_Sentinels.zig");
    pub const Equal_Sum_Regions = @import("constraint/Equal_Sum_Regions.zig");
    pub const Equal_Cells = @import("constraint/Equal_Cells.zig");
    pub const Ascending_Line = @import("constraint/Ascending_Line.zig");
    pub const Consecutive_Cells = @import("constraint/Consecutive_Cells.zig");
    pub const Ratio_Cells = @import("constraint/Ratio_Cells.zig");
    pub const Anti_Chess_Region = @import("constraint/Anti_Chess_Region.zig");
    pub const Ranked_Regions = @import("constraint/Ranked_Regions.zig");
    pub const kropki = @import("constraint/kropki.zig");
    pub const xv = @import("constraint/xv.zig");
    pub const misc = @import("constraint/misc.zig");
    // TODO German/Dutch/Chinese Whispers
    // TODO Renban lines
    // TODO Modular regions
    // TODO palindrome lines
    // TODO between lines
    // TODO entropic lines
    // TODO parity lines
    // TODO Corner Dots
    // TODO X Sums/Skyscraper
    // TODO Row/Column/Box indexing

    pub fn num_regions(self: Constraint) usize {
        switch (self) {
            inline else => |c| {
                if (@hasField(@TypeOf(c), "region")) {
                    return 1;
                } else if (@hasField(@TypeOf(c), "regions")) {
                    return c.regions.len;
                } else return c.num_regions();
            },
        }
    }

    pub fn get_region(self: Constraint, region: usize) Region {
        switch (self) {
            inline else => |c| {
                if (@hasField(@TypeOf(c), "region")) {
                    std.debug.assert(region == 0);
                    return c.region;
                } else if (@hasField(@TypeOf(c), "regions")) {
                    return c.regions[region];
                } else return c.get_region(region);
            },
        }
    }

    pub fn evaluate(self: Constraint, config: *const Config, state: *State) error{NotSolvable}!void {
        return switch (self) {
            inline else => |c| try c.evaluate(config, state),
        };
    }
};

const State = @import("State.zig");
const Config = @import("Config.zig");
const Region = @import("region.zig").Region;
const std = @import("std");
