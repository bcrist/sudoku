/// Base for constraints that involve the presence or absence of a "dot" between any pair of orthogonally-adjacent cells within a rect
pub fn Orthogonally_Adjacent_Dots(comptime Impl: type) type {
    return struct {
        const Self = @This();
       
        params: Orthogonally_Adjacent_Dots_Params,
        impl: Impl,

        pub fn init(allocator: std.mem.Allocator, rect: Rect) !Self {
            const default_evaluate_mutual_options = if (@hasDecl(Impl, "default_evaluate_mutual_options")) Impl.default_evaluate_mutual_options else true;

            var params: Orthogonally_Adjacent_Dots_Params = try .init(allocator, rect, default_evaluate_mutual_options);
            errdefer params.deinit(allocator);

            const impl: Impl = if (@hasDecl(Impl, "init")) impl: {
                if (@typeInfo(@TypeOf(Impl.init)) == Impl) {
                    break :impl Impl.init;
                } else {
                    break :impl try Impl.init(allocator, params);
                }
            } else .{};

            return .{
                .params = params,
                .impl = impl,
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.params.deinit(allocator);
            if (@hasDecl(Impl, "deinit")) {
                self.impl.deinit(allocator);
            }
        }

        pub fn add_dot(self: *Self, a: Cell, b: Cell) void {
            if (a.x == b.x) {
                const min_y = @min(a.y, b.y);
                const max_y = @max(a.y, b.y);
                std.debug.assert(max_y == min_y + 1);
                self.add_horizontal_dot(.init(a.x, min_y));
            } else if (a.y == b.y) {
                const min_x = @min(a.x, b.x);
                const max_x = @max(a.x, b.x);
                std.debug.assert(max_x == min_x + 1);
                self.add_vertical_dot(.init(min_x, a.y));
            } else unreachable;
        }

        pub fn add_horizontal_dot(self: *Self, left_cell: Cell) void {
            self.params.horizontal_dots.set(self.params.horizontal_index(left_cell));
        }

        pub fn add_vertical_dot(self: *Self, top_cell: Cell) void {
            self.params.vertical_dots.set(self.params.vertical_index(top_cell));
        }

        pub fn num_regions(_: Self) usize {
            return 1;
        }

        pub fn get_region(self: Self, region: usize) Region {
            std.debug.assert(region == 0);
            return .single(.{ .rect = self.params.rect });
        }

        pub fn evaluate(self: Self, config: *const Config, state: *State) State.Solve_Status {
            if (@hasDecl(Impl, "evaluate")) {
                return self.impl.evaluate(self.params, config, state);
            }

            var result: State.Solve_Status = .unsolved;

            var iter = self.params.rect.iterator(.forward);
            while (iter.next()) |cell| {
                if (cell.x < self.params.rect.max.x) {
                    const other_cell: Cell = .init(cell.x + 1, cell.y);
                    const has_dot = self.params.horizontal_dots.isSet(self.params.horizontal_index(cell));

                    if (@hasDecl(Impl, "evaluate_horizontal")) {
                        if (self.impl.evaluate_horizontal(self.params, config, state, cell, other_cell, has_dot) == .not_solvable) {
                            result = .not_solvable;
                        }
                    } else {
                        if (self.default_evaluate(config, state, cell, other_cell, has_dot) == .not_solvable) {
                            result = .not_solvable;
                        }
                    }
                }

                if (cell.y < self.params.rect.max.y) {
                    const other_cell: Cell = .init(cell.x, cell.y + 1);
                    const has_dot = self.params.vertical_dots.isSet(self.params.vertical_index(cell));

                    if (@hasDecl(Impl, "evaluate_vertical")) {
                        if (self.impl.evaluate_vertical(self.params, config, state, cell, other_cell, has_dot) == .not_solvable) {
                            result = .not_solvable;
                        }
                    } else {
                        if (self.default_evaluate(config, state, cell, other_cell, has_dot) == .not_solvable) {
                            result = .not_solvable;
                        }
                    }
                }
            }

            if (@hasDecl(Impl, "evaluate_extra")) {
                if (self.impl.evaluate_extra(self.params, config, state) == .not_solvable) {
                    result = .not_solvable;
                }
            }

            return result;
        }

        pub fn default_evaluate(self: Self, config: *const Config, state: *State, a: Cell, b: Cell, has_dot: bool) State.Solve_Status {
            const a_options = state.get(config, a);
            const b_options = state.get(config, b);

            if (a_options.count() == 1) {
                const a_value = a_options.findFirstSet().?;
                if (b_options.count() == 1) {
                    const b_value = b_options.findFirstSet().?;
                    if (self.impl.validate_cells(self.params, config, state, a, b, has_dot, a_value, b_value) == .not_solvable) {
                        return .not_solvable;
                    }
                } else {
                    self.update_cell_options(config, state, b, has_dot, a_value);
                }
            } else if (b_options.count() == 1) {
                const b_value = b_options.findFirstSet().?;
                self.update_cell_options(config, state, a, has_dot, b_value);
            } else if (self.params.evaluate_mutual_options) {
                self.update_cell_options_multi(config, state, a, has_dot, b_options);
                self.update_cell_options_multi(config, state, b, has_dot, a_options);
            }

            return .unsolved;
        }

        fn update_cell_options(self: Self, config: *const Config, state: *State, cell: Cell, has_dot: bool, adjacent_value: usize) void {
            state.intersect(config, cell, self.impl.get_options(self.params, config, state, cell, has_dot, adjacent_value));
        }
    
        fn update_cell_options_multi(self: Self, config: *const Config, state: *State, cell: Cell, has_dot: bool, adjacent_options: Cell.Value_Options) void {
            var new_options: Cell.Value_Options = .initEmpty();
            var iter = adjacent_options.iterator(.{});
            while (iter.next()) |adjacent_value| {
                new_options.setUnion(self.impl.get_options(self.params, config, state, cell, has_dot, adjacent_value));
            }
            state.intersect(config, cell, new_options);
        }
    };
}
 pub const Orthogonally_Adjacent_Dots_Params = struct {
    rect: Rect,
    horizontal_dots: std.DynamicBitSetUnmanaged,
    vertical_dots: std.DynamicBitSetUnmanaged,
    evaluate_mutual_options: bool, // disabling this will result in more bifurcation/backtracking, but may end up being faster overall

    pub fn init(allocator: std.mem.Allocator, rect: Rect, default_evaluate_mutual_options: bool) !Orthogonally_Adjacent_Dots_Params {
        var horizontal_dots: std.DynamicBitSetUnmanaged = try .initEmpty(allocator, (rect.width() - 1) * rect.height());
        errdefer horizontal_dots.deinit(allocator);

        var vertical_dots: std.DynamicBitSetUnmanaged = try .initEmpty(allocator, (rect.height() - 1) * rect.width());
        errdefer vertical_dots.deinit(allocator);

        return .{
            .rect = rect, 
            .horizontal_dots = horizontal_dots,
            .vertical_dots = vertical_dots,
            .evaluate_mutual_options = default_evaluate_mutual_options,
        };
    }

    pub fn deinit(self: *Orthogonally_Adjacent_Dots_Params, allocator: std.mem.Allocator) void {
        self.horizontal_dots.deinit(allocator);
        self.vertical_dots.deinit(allocator);
    }

    pub fn horizontal_index(self: Orthogonally_Adjacent_Dots_Params, left_cell: Cell) usize {
        std.debug.assert(left_cell.x >= self.rect.min.x);
        std.debug.assert(left_cell.x < self.rect.max.x);
        std.debug.assert(left_cell.y >= self.rect.min.y);
        std.debug.assert(left_cell.y <= self.rect.max.y);

        const offset_x = left_cell.x - self.rect.min.x;
        const offset_y = left_cell.y - self.rect.min.y;
        return (self.rect.width() - 1) * offset_y + offset_x;
    }

    pub fn vertical_index(self: Orthogonally_Adjacent_Dots_Params, top_cell: Cell) usize {
        std.debug.assert(top_cell.x >= self.rect.min.x);
        std.debug.assert(top_cell.x <= self.rect.max.x);
        std.debug.assert(top_cell.y >= self.rect.min.y);
        std.debug.assert(top_cell.y < self.rect.max.y);

        const offset_x = top_cell.x - self.rect.min.x;
        const offset_y = top_cell.y - self.rect.min.y;
        return (self.rect.height() - 1) * offset_x + offset_y;
    }
};

pub fn evaluate_sum_cells(config: *const Config, state: *State, iterator: anytype, sum: usize) State.Solve_Status {
    const has_abort = @hasField(@TypeOf(iterator), "abort");
    const has_last_options = @hasField(@TypeOf(iterator), "last_options");

    var min: u64 = 0;
    var max: u64 = 0;

    var iter = iterator;
    while (iter.next()) |cell| {
        const options = if (has_last_options) iter.last_options else state.get(config, cell);
        min += options.findFirstSet() orelse 0;
        max += options.findLastSet() orelse 0;
    }
    if (has_abort and iter.abort) return .unsolved;

    if (min == max) {
        return if (min == sum) .unsolved else .not_solvable;
    }

    if (min == sum) {
        iter = iterator;
        while (iter.next()) |cell| {
            var options = if (has_last_options) iter.last_options else state.get(config, cell);
            const value = options.findFirstSet() orelse 0;
            options = .initEmpty();
            options.set(value);
            state.intersect(config, cell, options);
        }
        return .unsolved;
    } else if (min > sum) return .not_solvable;

    if (max == sum) {
        iter = iterator;
        while (iter.next()) |cell| {
            var options = if (has_last_options) iter.last_options else state.get(config, cell);
            const value = options.findLastSet() orelse 0;
            options = .initEmpty();
            options.set(value);
            state.intersect(config, cell, options);
        }
        return .unsolved;
    } else if (max < sum) return .not_solvable;

    iter = iterator;
    while (iter.next()) |cell| {
        var options = if (has_last_options) iter.last_options else state.get(config, cell);
        if (options.count() <= 1) continue;

        const cell_min = options.findFirstSet().?;
        const cell_max = options.findLastSet().?;

        const min_of_others = min - cell_min;
        const max_of_others = max - cell_max;

        if (max_of_others + cell_min < sum) {
            const new_min = sum - max_of_others;
            for (cell_min..new_min) |v| {
                options.unset(v);
            }
            state.intersect(config, cell, options);
        }

        if (min_of_others + cell_max > sum) {
            const new_max = sum - @min(sum, min_of_others);
            for (new_max..cell_max) |v| {
                options.unset(v + 1);
            }
            state.intersect(config, cell, options);
        }
    }
    return .unsolved;
}

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Rect = @import("../Rect.zig");
const Config = @import("../Config.zig");
const State = @import("../State.zig");
const std = @import("std");
