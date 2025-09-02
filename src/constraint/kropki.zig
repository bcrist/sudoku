/// Implements the white kropki dot rules (both positive and negative constraint) for a rectangular region
/// If a white kropki dot appears between two cells (horizontally or vertically adjacent), then those cells' values must differ by exactly 1.
/// If no white kropki dot appears between two cells, then those cells' values must differ by more than 1.
pub const White = base.Orthogonally_Adjacent_Dots(struct {
    pub inline fn validate_cells(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, _: Cell, has_dot: bool, a_value: usize, b_value: usize) error{NotSolvable}!void {
        const cells_are_consecutive = @max(a_value, b_value) - @min(a_value, b_value) == 1;
        if (has_dot != cells_are_consecutive) return error.NotSolvable;
    }

    pub fn get_options(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, has_dot: bool, adjacent_value: usize) Cell.Value_Options {
        var options: Cell.Value_Options = .initEmpty();

        if (adjacent_value < 63) {
            options.set(adjacent_value + 1);
        }

        if (adjacent_value > 0) {
            options.set(adjacent_value - 1);
        }

        return if (has_dot) options else options.complement();
    }
});

/// Implements the black kropki dot rules (both positive and negative constraint) for a rectangular region
/// If a black kropki dot appears between two cells (horizontally or vertically adjacent), then the ratio of those cells' values must be exactly 2.
/// If no black kropki dot appears between two cells, then the ratio of those cells' values must not be exactly 2.
pub const Black = base.Orthogonally_Adjacent_Dots(struct {
    pub inline fn validate_cells(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, _: Cell, has_dot: bool, a_value: usize, b_value: usize) error{NotSolvable}!void {
        const min_value = @min(a_value, b_value);
        const max_value = @max(a_value, b_value);
        const double_value = min_value * 2;
        const max_value_is_double = max_value == double_value;
        if (has_dot != max_value_is_double) return error.NotSolvable;
    }

    pub fn get_options(_: @This(), _: Params, _: *const Config, _: *State, _: Cell, has_dot: bool, adjacent_value: usize) Cell.Value_Options {
        var options: Cell.Value_Options = .initEmpty();

        if (adjacent_value < 32) {
            options.set(adjacent_value * 2);
        }

        if ((adjacent_value & 1) == 0 and adjacent_value > 0) {
            options.set(adjacent_value / 2);
        }

        return if (has_dot) options else options.complement();
    }
});

const Params = base.Orthogonally_Adjacent_Dots_Params;

const Cell = @import("../Cell.zig");
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const base = @import("base.zig");
