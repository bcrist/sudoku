/// If any two orthogonally adjacent cells in a rect are marked by a mark (dot), then those two values may not appear across another dotted pair of values.
pub const Unique_Pairs_Rect = base.Orthogonally_Adjacent_Dots(struct {
    // If set to true, all pairs must have unique ratios, not just unique combinations of digits.
    // e.g. 2/3 and 4/6 "consume" the same ratio
    unique_ratios: bool = false,

    const Permutations = std.bit_set.ArrayBitSet(usize, 64 * 64);

    fn permutation_index(self: @This(), a: usize, b: usize) usize {
        std.debug.assert(a < 64);
        std.debug.assert(b < 64);
        var min = @min(a, b);
        var max = @max(a, b);

        if (self.unique_ratios) {
            const gcf = greatest_common_factor(min, max);
            min /= gcf;
            max /= gcf;
        }

        return min * 64 + max;
    }

    pub fn evaluate(self: @This(), params: base.Orthogonally_Adjacent_Dots_Params, config: *const Config, state: *State) error{NotSolvable}!void {
        var result: State.Solve_Status = .unsolved;

        var permutations: Permutations = .initEmpty();

        var iter = params.rect.iterator(.forward);
        while (iter.next()) |cell| {
            if (cell.x < params.rect.max.x) {
                const other_cell: Cell = .init(cell.x + 1, cell.y);
                if (params.horizontal_dots.isSet(params.horizontal_index(cell))) {
                    self.check_and_collect_permutation(config, state, cell, other_cell, &permutations) catch {
                        result = .not_solvable;
                    };
                }
            }

            if (cell.y < params.rect.max.y) {
                const other_cell: Cell = .init(cell.x, cell.y + 1);
                if (params.vertical_dots.isSet(params.vertical_index(cell))) {
                    self.check_and_collect_permutation(config, state, cell, other_cell, &permutations) catch {
                        result = .not_solvable;
                    };
                }
            }
        }

        iter = params.rect.iterator(.forward);
        while (iter.next()) |cell| {
            if (cell.x < params.rect.max.x) {
                const other_cell: Cell = .init(cell.x + 1, cell.y);
                if (params.horizontal_dots.isSet(params.horizontal_index(cell))) {
                    self.try_update_options(config, state, cell, other_cell, permutations);
                }
            }

            if (cell.y < params.rect.max.y) {
                const other_cell: Cell = .init(cell.x, cell.y + 1);
                if (params.vertical_dots.isSet(params.vertical_index(cell))) {
                    self.try_update_options(config, state, cell, other_cell, permutations);
                }
            }
        }

        if (result == .not_solvable) return error.NotSolvable;
    }
    
    fn check_and_collect_permutation(self: @This(), config: *const Config, state: *State, a: Cell, b: Cell, permutations: *Permutations) error{NotSolvable}!void {
        const a_options = state.get(config, a);
        const b_options = state.get(config, b);

        if (a_options.count() == 1 and b_options.count() == 1) {
            const a_value = a_options.findFirstSet().?;
            const b_value = b_options.findFirstSet().?;

            const index = self.permutation_index(a_value, b_value);

            if (permutations.isSet(index)) return error.NotSolvable;

            permutations.set(index);
        }
    }

    fn try_update_options(self: @This(), config: *const Config, state: *State, a: Cell, b: Cell, permutations: Permutations) void {
        var a_options = state.get(config, a);
        var b_options = state.get(config, b);

        const a_count = a_options.count();
        const b_count = b_options.count();

        if (a_count == 1 and b_count > 1) {
            self.update_options(config, state, b, b_options, a_options.findFirstSet().?, permutations);
        } else if (b_count == 1 and a_count > 1) {
            self.update_options(config, state, a, a_options, b_options.findFirstSet().?, permutations);
        }
    }

    fn update_options(self: @This(), config: *const Config, state: *State, cell: Cell, cell_options: Cell.Value_Options, fixed_value: usize, permutations: Permutations) void {
        var options = cell_options;

        var iter = cell_options.iterator(.{});
        while (iter.next()) |value| {
            const index = self.permutation_index(value, fixed_value);
            if (permutations.isSet(index)) {
                options.unset(value);
            }
        }

        _ = state.intersect(config, cell, options);
    }
});

pub fn greatest_common_factor(a: usize, b: usize) usize {
    // euclidean algorithm
    var x = a;
    var y = b;
    while (y > 0) {
        const temp = y;
        y = x % y;
        x = temp;
    }
    return x;
}

const Cell = @import("../Cell.zig");
const Rect = @import("../Rect.zig");
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");
const std = @import("std");
