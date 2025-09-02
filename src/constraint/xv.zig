/// Implements the X rule from X-V sudoku (both positive and negative constraint) for a rectangular region
/// If an X appears between two cells (horizontally or vertically adjacent), then those cells' values must sum to 10.
/// If no X appears between two cells, then those cells' values must not sum to 10.
pub const X = base.Orthogonally_Adjacent_Dots(struct {
    pub inline fn validate_cells(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, _: Cell, has_dot: bool, a_value: usize, b_value: usize) error{NotSolvable}!void {
        const sum_is_ten = (a_value + b_value) == 10;
        if (has_dot != sum_is_ten) return error.NotSolvable;
    }

    pub fn get_options(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, has_dot: bool, adjacent_value: usize) Cell.Value_Options {
        var options: Cell.Value_Options = .initEmpty();
        if (adjacent_value <= 10) {
            options.set(10 - adjacent_value);
        }
        return if (has_dot) options else options.complement();
    }
});

/// Implements the V rule from X-V sudoku (both positive and negative constraint) for a rectangular region
/// If an V appears between two cells (horizontally or vertically adjacent), then those cells' values must sum to 5.
/// If no V appears between two cells, then those cells' values must not sum to 5.
pub const V = base.Orthogonally_Adjacent_Dots(struct {
    pub inline fn validate_cells(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, _: Cell, has_dot: bool, a_value: usize, b_value: usize) error{NotSolvable}!void {
        const sum_is_five = (a_value + b_value) == 5;
        if (has_dot != sum_is_five) return error.NotSolvable;
    }

    pub fn get_options(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, has_dot: bool, adjacent_value: usize) Cell.Value_Options {
        var options: Cell.Value_Options = .initEmpty();
        if (adjacent_value <= 5) {
            options.set(10 - adjacent_value);
        }
        return if (has_dot) options else options.complement();
    }
});

const Params = base.Orthogonally_Adjacent_Dots_Params;

const Cell = @import("../Cell.zig");
const Rect = @import("../Rect.zig");
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");
