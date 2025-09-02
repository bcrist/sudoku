//! Requires that no cell in the region has the same value as another cell in the region which can be visited by a King's move in chess (exactly 1 different in one one or both coordinates)

region: Region,
bounds: Rect,
king: bool,
knight: bool,
bishop: bool,
rook: bool,

const Init_Options = struct {
    anti_king: bool = false,
    anti_knight: bool = false,
    anti_bishop: bool = false,
    anti_rook: bool = false, // redundant with row/column constraints in standard sudoku.
    anti_queen: bool = false, // partially redundant with row/column constraints in standard sudoku; use anti-bishop mode instead.
};

pub fn init(region: Region, options: Init_Options) Anti_Chess_Region {
    var bounds: Rect = .empty;
    region.expand_bounds(&bounds);

    return .{
        .region = region,
        .bounds = bounds,
        .king = options.anti_king,
        .knight = options.anti_knight,
        .bishop = options.anti_bishop or options.anti_queen,
        .rook = options.anti_rook or options.anti_queen,
    };
}

pub fn evaluate(self: @This(), config: *const Config, state: *State) error{NotSolvable}!void {
    var iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        const options = state.get(config, cell);
        if (options.count() == 1) {
            const value = options.findFirstSet().?;

            if (self.knight) {
                self.evaluate_adjacency(config, state, value, cell.offset(-2, -1));
                self.evaluate_adjacency(config, state, value, cell.offset(-2,  1));
                self.evaluate_adjacency(config, state, value, cell.offset( 2, -1));
                self.evaluate_adjacency(config, state, value, cell.offset( 2,  1));
                self.evaluate_adjacency(config, state, value, cell.offset(-1,  2));
                self.evaluate_adjacency(config, state, value, cell.offset( 1, -2));
                self.evaluate_adjacency(config, state, value, cell.offset( 1,  2));
            }

            if (self.king or self.rook) {
                self.evaluate_adjacency(config, state, value, cell.offset(-1,  0));
                self.evaluate_adjacency(config, state, value, cell.offset( 1,  0));
                self.evaluate_adjacency(config, state, value, cell.offset( 0, -1));
                self.evaluate_adjacency(config, state, value, cell.offset( 0,  1));
            }

            if (self.king or self.bishop) {
                self.evaluate_adjacency(config, state, value, cell.offset(-1, -1));
                self.evaluate_adjacency(config, state, value, cell.offset(-1,  1));
                self.evaluate_adjacency(config, state, value, cell.offset( 1, -1));
                self.evaluate_adjacency(config, state, value, cell.offset( 1,  1));
            }

            if (self.bishop) {
                self.evaluate_direction(config, state, value, cell.offset(-2, -2), -1, -1);
                self.evaluate_direction(config, state, value, cell.offset(-2,  2), -1,  1);
                self.evaluate_direction(config, state, value, cell.offset( 2, -2),  1, -1);
                self.evaluate_direction(config, state, value, cell.offset( 2,  2),  1,  1);
            }

            if (self.rook) {
                self.evaluate_direction(config, state, value, cell.offset(-2,  0), -1,  0);
                self.evaluate_direction(config, state, value, cell.offset( 2,  0),  1,  0);
                self.evaluate_direction(config, state, value, cell.offset( 0, -2),  0, -1);
                self.evaluate_direction(config, state, value, cell.offset( 0,  2),  0,  1);
            }
        }
    }
}

fn evaluate_direction(self: Anti_Chess_Region, config: *const Config, state: *State, anti_value: usize, starting_cell: ?Cell, offset_x: i32, offset_y: i32) void {
    var maybe_cell = starting_cell;
    while (maybe_cell) |cell| {
        if (!self.bounds.contains(cell)) return;
        self.evaluate_adjacency(config, state, anti_value, cell);
        maybe_cell = cell.offset(offset_x, offset_y);
    }
}

fn evaluate_adjacency(self: Anti_Chess_Region, config: *const Config, state: *State, anti_value: usize, maybe_cell: ?Cell) void {
    const cell = maybe_cell orelse return;
    if (!self.region.contains(cell)) return;

    var new_options: Cell.Value_Options = .initFull();
    new_options.unset(anti_value);
    state.intersect(config, cell, new_options);
}

const Anti_Chess_Region = @This();

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Rect = @import("../Rect.zig");
const Config = @import("../Config.zig");
const State = @import("../State.zig");
