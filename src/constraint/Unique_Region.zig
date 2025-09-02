//! Requires that all cells in a region must have unique values.
//! This is used for all of the standard sudoku rules (i.e. "digits 1-9 appear exactly once in each row, column, and 3x3 box")
//! It can also be used for irregular sudoku, diagonals, multi/samurai sudoku, disjoint sets, etc.
//! Note the region may be smaller than the cardinality of the set of values that can go in the region
//! 
//! TODO detect when cardinality of options remaining == number of cells in range -- look for values that only appear in one cell

region: Region,

pub fn row(y: usize, width: usize) Unique_Region {
    return .{ .region = .single(.{ .rect = .{
        .min = .init(1, y),
        .max = .init(width, y),
    }})};
}

pub fn column(x: usize, height: usize) Unique_Region {
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x, 1),
        .max = .init(x, height),
    }})};
}

pub fn box_4x4(box: usize) Unique_Region {
    const x = ((box - 1) % 2) * 2;
    const y = ((box - 1) / 2) * 2;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 2, y + 2),
    }})};
}

pub fn box_6x6_wide(box: usize) Unique_Region {
    const x = ((box - 1) % 2) * 3;
    const y = ((box - 1) / 2) * 2;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 3, y + 2),
    }})};
}

pub fn box_6x6_tall(box: usize) Unique_Region {
    const x = ((box - 1) % 3) * 2;
    const y = ((box - 1) / 3) * 3;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 2, y + 3),
    }})};
}

pub fn box_9x9(box: usize) Unique_Region {
    const x = ((box - 1) % 3) * 3;
    const y = ((box - 1) / 3) * 3;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 3, y + 3),
    }})};
}

pub fn box_12x12_wide(box: usize) Unique_Region {
    const x = ((box - 1) % 3) * 4;
    const y = ((box - 1) / 3) * 3;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 4, y + 3),
    }})};
}

pub fn box_12x12_tall(box: usize) Unique_Region {
    const x = ((box - 1) % 4) * 3;
    const y = ((box - 1) / 4) * 4;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 3, y + 4),
    }})};
}

pub fn box_16x16(box: usize) Unique_Region {
    const x = ((box - 1) % 4) * 4;
    const y = ((box - 1) / 4) * 4;
    return .{ .region = .single(.{ .rect = .{
        .min = .init(x + 1, y + 1),
        .max = .init(x + 4, y + 4),
    }})};
}

pub fn evaluate(self: Unique_Region, config: *const Config, state: *State) error{NotSolvable}!void {
    var iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        const options = state.get(config, cell);
        if (options.count() == 1) {
            var iter2 = self.region.iterator(.forward);
            while (iter2.next()) |cell2| {
                if (!std.meta.eql(cell, cell2)) {
                    state.intersect(config, cell2, options.complement());
                }
            }
        }
    }
}

const Unique_Region = @This();

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const std = @import("std");
