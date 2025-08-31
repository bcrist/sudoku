//! Requires that the sum of the values in all cells of a region equals a fixed, known value.
//! a.k.a. Killer Cages, Diagonal Sums, X-V (without negative constraint)
//! Note this doesn't enforce uniqueness of all cells in the region; use a separate Unique_Region constraint for that if necessary.
    
region: Region,
sum: u64,

pub fn init(sum: u64, region: Region) Sum_Region {
    return .{
        .region = region,
        .sum = sum,
    };
}

pub fn evaluate(self: Sum_Region, config: Config, state: *State) State.Solve_Status {
    var min: u64 = 0;
    var max: u64 = 0;

    var iter = self.region.iterator();
    while (iter.next()) |cell| {
        const options = state.get(config, cell);
        min += options.findFirstSet() orelse 0;
        max += options.findLastSet() orelse 0;
    }

    if (min == max) {
        return if (min == self.sum) .unsolved else .not_solvable;
    }

    if (min == self.sum) {
        iter = self.region.iterator();
        while (iter.next()) |cell| {
            var options = state.get(config, cell);
            const value = options.findFirstSet() orelse 0;
            options = .initEmpty();
            options.set(value);
            state.intersect(config, cell, options);
        }
        return .unsolved;
    } else if (min > self.sum) return .not_solvable;

    if (max == self.sum) {
        iter = self.region.iterator();
        while (iter.next()) |cell| {
            var options = state.get(config, cell);
            const value = options.findLastSet() orelse 0;
            options = .initEmpty();
            options.set(value);
            state.intersect(config, cell, options);
        }
        return .unsolved;
    } else if (max < self.sum) return .not_solvable;

    iter = self.region.iterator();
    while (iter.next()) |cell| {
        var options = state.get(config, cell);
        if (options.count() <= 1) continue;

        const cell_min = options.findFirstSet().?;
        const cell_max = options.findLastSet().?;

        const min_of_others = min - cell_min;
        const max_of_others = max - cell_max;

        if (max_of_others + cell_min < self.sum) {
            const new_min = self.sum - max_of_others;
            for (cell_min..new_min) |v| {
                options.unset(v);
            }
            state.intersect(config, cell, options);
        }

        if (min_of_others + cell_max > self.sum) {
            const new_max = self.sum - @min(self.sum, min_of_others);
            for (new_max..cell_max) |v| {
                options.unset(v + 1);
            }
            state.intersect(config, cell, options);
        }
    }
    return .unsolved;
}

const Sum_Region = @This();

const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");