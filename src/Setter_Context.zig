// This is not guaranteed to reflect every single solution unless there are less than min_solutions total solutions.
// But if a large number of solutions are found, any cells that remain solved are likely to be highly constrained.
solutions: State,
found_all_solutions: bool,
min_solutions: usize,
max_solutions: usize,
max_backtracks: usize,
max_stochastic_solutions: usize,
max_stochastic_backtracks: usize,

counters: struct {
    solutions: usize,
    backtracks: usize,
    bifurcations: usize,
    evaluations: usize,
    max_depth: usize,

    pub const init: @This() = .{
        .solutions = 0,
        .backtracks = 0,
        .bifurcations = 0,
        .evaluations = 0,
        .max_depth = 0,
    };
} = .init,

const Init_Options = struct {
    min_solutions: usize = 50,
    max_solutions: usize = 100,
    max_backtracks: usize = 200_000,
    max_stochastic_solutions: usize = 10_000,
    max_stochastic_backtracks: usize = 100_000,
};

pub fn init(allocator: std.mem.Allocator, config: *const Config, options: Init_Options) !Setter_Context {
    return .{
        .solutions = try .init_empty(allocator, config.num_cells),
        .found_all_solutions = false,
        .min_solutions = options.min_solutions,
        .max_solutions = options.max_solutions,
        .max_backtracks = options.max_backtracks,
        .max_stochastic_solutions = options.max_stochastic_solutions,
        .max_stochastic_backtracks = options.max_stochastic_backtracks,
    };
}

pub fn deinit(self: Setter_Context, allocator: std.mem.Allocator) void {
    self.solutions.deinit(allocator);
}

pub fn on_solution(self: *Setter_Context, config: *const Config, state: State, depth: usize) !void {
    _ = config;
    self.counters.solutions += 1;
    self.counters.max_depth = @max(self.counters.max_depth, depth);

    for (self.solutions.cells, state.cells) |*out, solution| {
        out.setUnion(solution);
    }

    if (self.counters.solutions > if (self.found_all_solutions) self.max_solutions else self.max_stochastic_solutions) {
        return error.StopSolving;
    }
}

pub fn on_backtrack(self: *Setter_Context, config: *const Config, state: State, depth: usize, _: anyerror) !void {
    _ = config;
    _ = state;
    self.counters.backtracks += 1;
    self.counters.max_depth = @max(self.counters.max_depth, depth);

    if (self.counters.backtracks > if (self.found_all_solutions) self.max_backtracks else self.max_stochastic_backtracks) {
        return error.StopSolving;
    }
}

pub fn on_evaluation(self: *Setter_Context, config: *const Config, state: State, depth: usize) !void {
    _ = config;
    _ = state;
    _ = depth;
    self.counters.evaluations += 1;
}

pub fn on_bifurcation(self: *Setter_Context, config: *const Config, state: State, depth: usize, branch_factor: usize) !void {
    _ = config;
    _ = state;
    _ = depth;
    _ = branch_factor;
    self.counters.bifurcations += 1;
}

const Setter_Context = @This();

const Config = @import("Config.zig");
const State = @import("State.zig");
const std = @import("std");