cells: []Cell.Value_Options,
modified: bool,

pub fn init(allocator: std.mem.Allocator, num_cells: usize) !State {
    const cells = try allocator.alloc(Cell.Value_Options, num_cells);
    @memset(cells, .initFull());
    return .{
        .cells = cells,
        .modified = false,
    };
}

pub fn init_empty(allocator: std.mem.Allocator, num_cells: usize) !State {
    const cells = try allocator.alloc(Cell.Value_Options, num_cells);
    @memset(cells, .initEmpty());
    return .{
        .cells = cells,
        .modified = false,
    };
}

pub fn clone(self: State, allocator: std.mem.Allocator) !State {
    return .{
        .cells = try allocator.dupe(Cell.Value_Options, self.cells),
        .modified = false,
    };
}

pub fn deinit(self: State, allocator: std.mem.Allocator) void {
    allocator.free(self.cells);
}

pub const Solve_Status = enum {
    unsolved,
    solved,
    not_solvable,
};

pub fn status(self: State) Solve_Status {
    for (self.cells) |cell_options| {
        switch (cell_options.count()) {
            0 => return .not_solvable,
            1 => {},
            else => return .unsolved,
        }
    }
    return .solved;
}

pub fn get(self: State, config: Config, cell: Cell) Cell.Value_Options {
    const index = config.cell_index(cell);
    const raw = index.maybe_raw() orelse return .initEmpty();
    if (raw >= self.cells.len) return .initEmpty();
    return self.cells[raw];
}

pub fn set(self: *State, config: Config, cell: Cell, value: u6) void {
    const index = config.cell_index(cell);
    const raw = index.maybe_raw() orelse return;
    if (raw >= self.cells.len) return;
    var options: Cell.Value_Options = .initEmpty();
    options.set(value);
    if (!self.cells[raw].eql(options)) {
        self.cells[raw] = options;
        self.modified = true;
    }
}

pub fn intersect(self: *State, config: Config, cell: Cell, options: Cell.Value_Options) void {
    const index = config.cell_index(cell);
    const raw = index.maybe_raw() orelse return;
    if (raw >= self.cells.len) return;
    const old = self.cells[raw];
    const new = old.intersectWith(options);
    if (!new.eql(old)) {
        self.cells[raw] = new;
        self.modified = true;
    }
}

pub fn debug(self: State, config: Config, writer: *std.io.Writer) !void {
    for (config.bounds.min.y .. config.bounds.max.y + 1) |y| {
        for (config.bounds.min.x .. config.bounds.max.x + 1) |x| {
            const options = self.get(config, .init(x, y));
            try writer.writeByte(switch (options.count()) {
                0 => ' ',
                1 => ch: {
                    const value = options.findFirstSet().?;
                    break :ch switch (value) {
                        0...9 => @intCast('0' + value),
                        10...36 => @intCast('a' + value - 10),
                        else => '#',
                    };
                },
                else => '?',
            });
        }
        try writer.writeByte('\n');
    }
}

pub fn debug_full(self: State, config: Config, writer: *std.io.Writer) !void {
    for (config.bounds.min.y .. config.bounds.max.y + 1) |y| {
        for (config.bounds.min.x .. config.bounds.max.x + 1) |x| {
            const options = self.get(config, .init(x, y));
            try writer.print("{b:0>10} ", .{ options.mask });
        }
        try writer.writeByte('\n');
    }
}

pub fn solve(self: *State, allocator: std.mem.Allocator, config: Config, ctx: anytype) !Solve_Status {
    const Wrapper = Context_Wrapper(@TypeOf(ctx));
    var wrapped: Wrapper = try .init(allocator, config.num_cells, ctx);
    defer wrapped.deinit(allocator);
    defer if (wrapped.solution.modified) {
        @memcpy(self.cells, wrapped.solution.cells);
        self.modified = true;
    };

    if (Wrapper.Context == Setter_Context) {
        var snapshot = try self.clone(allocator);
        defer snapshot.deinit(allocator);

        var rng: std.Random.Xoshiro256 = .{ .s = .{
            std.crypto.random.int(u64),
            std.crypto.random.int(u64),
            std.crypto.random.int(u64),
            std.crypto.random.int(u64),
        }};
        const rnd = rng.random();

        while (true) {
            @memcpy(self.cells, snapshot.cells);
            self.solve_wrapped(allocator, config, @TypeOf(ctx), &wrapped, rnd) catch |err| switch (err) {
                error.StopSolving => break,
                else => return err,
            };
        }

        if (ctx.counters.solutions < ctx.min_solutions) {
            ctx.counters.solutions = 0;
            ctx.found_all_solutions = true;
            @memcpy(self.cells, snapshot.cells);
            self.solve_wrapped(allocator, config, @TypeOf(ctx), &wrapped, null) catch |err| switch (err) {
                error.StopSolving => {
                    ctx.found_all_solutions = false;
                },
                else => {
                    ctx.found_all_solutions = false;
                    return err;
                },
            };
        }

    } else {
        self.solve_wrapped(allocator, config, @TypeOf(ctx), &wrapped, null) catch |err| switch (err) {
            error.StopSolving => {},
            else => return err,
        };
    }

    return if (wrapped.solution.modified) .solved else .unsolved;
}

fn solve_wrapped(self: *State, allocator: std.mem.Allocator, config: Config, comptime Inner: type, ctx: *Context_Wrapper(Inner), maybe_rnd: ?std.Random) !void {
    ctx.depth += 1;
    defer ctx.depth -= 1;

    self.modified = true;
    while (self.modified) {
        self.modified = false;

        for (config.constraints) |c| {
            if (c.evaluate(config, self) == .not_solvable) {
                try ctx.on_evaluation(config, self.*);
                try ctx.on_backtrack(config, self.*);
                return;
            }
        }

        try ctx.on_evaluation(config, self.*);
    }
    
    switch (self.status()) {
        .solved => try ctx.on_solution(config, self.*),
        .not_solvable => try ctx.on_backtrack(config, self.*),
        .unsolved => if (maybe_rnd) |rnd| {
            const unsolved_cell: usize = for (0..100) |_| {
                const i = rnd.intRangeLessThan(usize, 0, self.cells.len);
                if (self.cells[i].count() > 1) break i;
            } else for (0.., self.cells) |i, cell| {
                if (cell.count() > 1) break i;
            } else unreachable;

            const options = self.cells[unsolved_cell];
            const count = options.count();
            var skip = rnd.intRangeLessThan(usize, 0, count);
            var iter = options.iterator(.{});
            const v = while (iter.next()) |value| {
                if (skip == 0) break value;
                skip -= 1;
            } else unreachable;

            try ctx.on_bifurcation(config, self.*, count);

            var selection: Cell.Value_Options = .initEmpty();
            selection.set(v);
            self.cells[unsolved_cell] = selection;
            try self.solve_wrapped(allocator, config, Inner, ctx, rnd);

        } else {
            var snapshot = try self.clone(allocator);
            defer snapshot.deinit(allocator);

            const first_unsolved_cell: usize = for (0.., self.cells) |i, cell| {
                if (cell.count() > 1) break i;
            } else unreachable;

            const options = self.cells[first_unsolved_cell];

            try ctx.on_bifurcation(config, self.*, options.count());

            var iter = options.iterator(.{});
            while (iter.next()) |v| {
                @memcpy(self.cells, snapshot.cells);
                var selection: Cell.Value_Options = .initEmpty();
                selection.set(v);
                self.cells[first_unsolved_cell] = selection;
                try self.solve_wrapped(allocator, config, Inner, ctx, null);
            }
        },
    }
}

fn Context_Wrapper(comptime Inner: type) type {
    const info = @typeInfo(Inner);
    return struct {
        solution: State,
        inner: Inner,
        depth: usize,

        pub const Context = if (info == .pointer) info.pointer.child else Inner;

        const First_Solution_Self = @This();

        pub fn init(allocator: std.mem.Allocator, num_cells: usize, inner: Inner) !First_Solution_Self {
            return .{
                .solution = try .init(allocator, num_cells),
                .inner = inner,
                .depth = 0,
            };
        }

        pub fn deinit(self: First_Solution_Self, allocator: std.mem.Allocator) void {
            self.solution.deinit(allocator);
        }

        pub fn on_solution(self: *First_Solution_Self, config: Config, state: State) !void {
            if (!self.solution.modified) {
                @memcpy(self.solution.cells, state.cells);
                self.solution.modified = true;
            }

            if (@hasDecl(Context, "on_solution")) {
                return self.inner.on_solution(config, state, self.depth);
            }
        }

        pub fn on_backtrack(self: *First_Solution_Self, config: Config, state: State) !void {
            if (@hasDecl(Context, "on_backtrack")) {
                return self.inner.on_backtrack(config, state, self.depth);
            }
        }

        pub fn on_evaluation(self: *First_Solution_Self, config: Config, state: State) !void {
            if (@hasDecl(Context, "on_evaluation")) {
                return self.inner.on_evaluation(config, state, self.depth);
            }
        }

        pub fn on_bifurcation(self: *First_Solution_Self, config: Config, state: State, branch_factor: usize) !void {
            if (@hasDecl(Context, "on_bifurcation")) {
                return self.inner.on_bifurcation(config, state, self.depth, branch_factor);
            }
        }
    };
}

const State = @This();

const Setter_Context = @import("Setter_Context.zig");
const Cell = @import("Cell.zig");
const Config = @import("Config.zig");
const std = @import("std");
