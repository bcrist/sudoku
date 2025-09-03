constraints: []const Constraint,
num_cells: usize,
bounds: Rect,
cell_map: []const Cell.Index,
initial_state: State,

pub fn init(allocator: std.mem.Allocator, constraints: []const Constraint) !Config {
    var bounds: Rect = .empty;
    for (constraints) |c| {
        for (0..c.num_regions()) |region| {
            c.get_region(region).expand_bounds(&bounds);
        }
    }

    const cell_map = try allocator.alloc(Cell.Index, bounds.width() * bounds.height());
    errdefer allocator.free(cell_map);
    @memset(cell_map, .invalid);

    var self: Config = .{
        .constraints = constraints,
        .num_cells = 0,
        .bounds = bounds,
        .cell_map = cell_map,
        .initial_state = .{ .cells = &.{}, .modified = false },
    };

    for (constraints) |c| {
        for (0..c.num_regions()) |region| {
            var iter = c.get_region(region).iterator(.forward);
            while (iter.next()) |cell| {
                const index = self.cell_map_index(cell);
                if (cell_map[index] == .invalid) {
                    cell_map[index] = Cell.Index.init(self.num_cells);
                    self.num_cells += 1;
                }
            }
        }
    }

    {
        const Cell_Strength = struct {
            cell: Cell,
            strength: u32,

            pub fn order(_: void, a: @This(), b: @This()) bool {
                return a.strength > b.strength;
            }
        };
        var cell_strength = try allocator.alloc(Cell_Strength, self.num_cells);
        defer allocator.free(cell_strength);
        @memset(cell_strength, .{ .cell = .origin, .strength = 0 });

        for (constraints) |c| {
            for (0..c.num_regions()) |region| {
                var iter = c.get_region(region).iterator(.forward);
                while (iter.next()) |cell| {
                    const index = cell_map[self.cell_map_index(cell)].raw();
                    cell_strength[index].cell = cell;
                    cell_strength[index].strength += 1; // TODO allow constraints to customize the weight they add to each cell
                }
            }
        }

        // sort from highest to lowest strength
        std.sort.block(Cell_Strength, cell_strength, {}, Cell_Strength.order);

        // reorder cell_map
        for (0.., cell_strength) |i, s| {
            const index = self.cell_map_index(s.cell);
            cell_map[index] = Cell.Index.init(i);
        }
    }

    self.initial_state = try .init(allocator, self.num_cells);
    return self;
}

pub fn deinit(self: *const Config, allocator: std.mem.Allocator) void {
    self.initial_state.deinit(allocator);
    allocator.free(self.cell_map);
}

pub fn init_cell(self: *Config, cell: Cell, value: u6) void {
    self.initial_state.set(self, cell, value);
}

pub fn init_cells(self: *Config, cell_data: []const u8) void {
    var cell: Cell = self.bounds.min;
    for (cell_data) |ch| {
        if (ch == '\n') {
            cell.x = self.bounds.min.x;
            cell.y += 1;
        } else {
            self.initial_state.set_options(self, cell, Cell.options(&.{ ch }));
            cell.x += 1;
        }
    }
}

pub const Solve_Result = struct {
    solution: ?State,
    context: Default_Context,
};

pub fn solve(self: *const Config, allocator: std.mem.Allocator, context: Default_Context) !Solve_Result {
    var ctx = context;
    var state = try self.initial_state.clone(allocator);
    switch (try state.solve(allocator, self, &ctx)) {
        .solved => {
            return .{
                .solution = state,
                .context = ctx,
            };
        },
        else => {
            state.deinit(allocator);
            return .{
                .solution = null,
                .context = ctx,
            };
        },
    }
}

pub fn cell_index(self: *const Config, cell: Cell) Cell.Index {
    if (!self.bounds.contains(cell)) return .invalid;
    const map_index = self.cell_map_index(cell);
    if (map_index >= self.cell_map.len) return .invalid;
    return self.cell_map[map_index];
}

fn cell_map_index(self: *const Config, cell: Cell) usize {
    return (cell.y - self.bounds.min.y) * self.bounds.width() + (cell.x - self.bounds.min.x);
}

const Config = @This();

const Cell = @import("Cell.zig");
const Rect = @import("Rect.zig");
const State = @import("State.zig");
const Constraint = @import("constraint.zig").Constraint;
const Default_Context = @import("Default_Context.zig");
const std = @import("std");
