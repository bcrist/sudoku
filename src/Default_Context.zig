max_solutions: usize,
max_backtracks: usize,

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

pub const default: Default_Context = .{
    .max_solutions = 1,

    // If you hit this, probably a new, smarter constraint type needs to be implemented
    .max_backtracks = 1_000_000,
};

pub const multi_solution: Default_Context = .{
    .max_solutions = 100,

    // If you hit this, probably a new, smarter constraint type needs to be implemented
    .max_backtracks = 100_000_000,
};

pub const no_backtracks: Default_Context = .{
    .max_solutions = 1,
    .max_backtracks = 0,
};

pub fn on_solution(self: *Default_Context, config: *const Config, state: State, depth: usize) !void {
    _ = config;
    _ = state;
    self.counters.solutions += 1;
    self.counters.max_depth = @max(self.counters.max_depth, depth);

    if (self.counters.solutions > self.max_solutions) {
        return error.StopSolving;
    }
}

pub fn on_backtrack(self: *Default_Context, config: *const Config, state: State, depth: usize, _: anyerror) !void {
    _ = config;
    _ = state;
    self.counters.backtracks += 1;
    self.counters.max_depth = @max(self.counters.max_depth, depth);

    if (self.counters.backtracks > self.max_backtracks) {
        return error.StopSolving;
    }
}

pub fn on_evaluation(self: *Default_Context, config: *const Config, state: State, depth: usize) !void {
    _ = config;
    _ = state;
    _ = depth;
    self.counters.evaluations += 1;
}

pub fn on_bifurcation(self: *Default_Context, config: *const Config, state: State, depth: usize, branch_factor: usize) !void {
    _ = config;
    _ = state;
    _ = depth;
    _ = branch_factor;
    self.counters.bifurcations += 1;
}

const Default_Context = @This();

const Config = @import("Config.zig");
const State = @import("State.zig");
const std = @import("std");