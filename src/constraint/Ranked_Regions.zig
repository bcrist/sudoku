//! Up to 50 regions exist in the puzzle.
//! These regions can be ordered from smallest to largest, based on the value of the first cell in the region.
//! If two regions have the same value for the first cell, then the second cell will be compared, etc.
//! If a region is smaller than the one it is being compared to and therefore doesn't have a cell to compare, consider the missing cell to be a 0.
//! 
//! Note this constraint never eliminates any values from the board, it only validates solutions once all regions have been fully solved.
//! There are some cases where we could make deductions before that, but in general, this constraint tends to only be meaningful late in a solve,
//! so the earlier we can bail out the better.
//! 
//! TODO: may be able to do better without too much work - if every region is not known, but has a uniquely known prefix, then we already know the total order, even if we don't know every digit of the regions.
//! similarly, we may know a partial order if some regions start with the same digit/prefix; we can still make deductions about the rank of regions that start with a different rank/prefix.  Use a bitmask to track which regions we know have a proven rank.

region_count: usize,
rank_origin: usize,
buf_region: [max_regions]Region,
buf_direction: [max_regions]Cell.Iteration_Direction,
buf_required_rank: [max_regions]?u8,

pub const max_regions = 50;

comptime {
    std.debug.assert(max_regions <= std.math.maxInt(u8));
}

pub const Ranked_Region = struct { Cell.Iteration_Direction, ?u8, Region };
pub fn init(regions: []const Ranked_Region) Ranked_Regions {
    std.debug.assert(regions.len < max_regions);
    var self: Ranked_Regions = .{
        .retion_count = regions.len,
        .rank_origin = 1,
        .buf_region = undefined,
        .buf_required_rank = undefined,
        .buf_direction = undefined,
    };

    for (regions, &self.buf_region, &self.buf_required_rank, &self.buf_direction) |info, *region, *rank, *dir| {
        region.*, rank.*, dir.* = info;
    }

    return self;
}

pub fn num_regions(self: Ranked_Regions) usize {
    return self.region_count;
}

pub fn get_region(self: Ranked_Regions, region: usize) Region {
    return self.buf_region[region];
}
        
pub fn evaluate(self: Ranked_Regions, config: *const Config, state: *State) error{NotSolvable}!void {
    const n = self.region_count;

    for (self.buf_region[0..n]) |region| {
        var iter = region.iterator(.forward);
        while (iter.next()) |cell| {
            if (state.get(config, cell).count() > 1) return;
        }
    }

    var sorted_region_indices_buf: [max_regions]u8 = undefined;
    const sorted_region_indices = sorted_region_indices_buf[0..n];
    for (0.., sorted_region_indices) |i, *index| index.* = @intCast(i);

    std.sort.block(u8, sorted_region_indices, Sort_Context{
        .c = &self,
        .config = config,
        .state = state,
    }, Sort_Context.less_than);

    for (self.rank_origin.., sorted_region_indices) |rank, region_index| {
        if (self.buf_required_rank[region_index]) |required_rank| {
            if (rank != required_rank) return error.NotSolvable;
        }
    }
}

const Sort_Context = struct {
    c: *const Ranked_Regions,
    config: *const Config,
    state: *const State,

    pub fn less_than(self: Sort_Context, a: u8, b: u8) bool {
        var a_iter = self.c.buf_region[a].iterator(self.c.buf_direction[a]);
        var b_iter = self.c.buf_region[b].iterator(self.c.buf_direction[b]);

        const config = self.config;
        const state = self.state;

        while (true) {
            if (a_iter.next()) |a_cell| {
                const a_value = state.get(config, a_cell).findFirstSet().?;
                const b_value = if (b_iter.next()) |b_cell| state.get(config, b_cell).findFirstSet().? else 0;

                if (a_value != b_value) return a_value < b_value;
            } else if (b_iter.next()) |b_cell| {
                const b_value = state.get(config, b_cell).findFirstSet().?;
                const a_value = if (a_iter.next()) |a_cell| state.get(config, a_cell).findFirstSet().? else 0;

                if (a_value != b_value) return a_value < b_value;
            } else break;
        }
        
        return false; // equal
    }
};

const Ranked_Regions = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const std = @import("std");
