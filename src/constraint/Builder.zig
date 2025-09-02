gpa: std.mem.Allocator,
arena: std.mem.Allocator,
constraints: std.ArrayList(Constraint),
region_rects: std.ArrayList(Rect),

pub fn init(gpa: std.mem.Allocator, arena: std.mem.Allocator) Builder {
    return .{
        .gpa = gpa,
        .arena = arena,
        .constraints = .empty,
        .region_rects = .empty,
    };
}

pub fn deinit(self: *Builder) void {
    self.region_rects.deinit(self.gpa);
    self.constraints.deinit(self.gpa);
}

pub fn reset(self: *Builder) void {
    self.region_rects.clearRetainingCapacity();
    self.constraints.clearRetainingCapacity();
}

pub fn reset_region(self: *Builder) void {
    self.region_rects.clearRetainingCapacity();
}

fn assert_empty_region(self: Builder) void {
    std.debug.assert(self.region_rects.items.len == 0);
}

pub fn add_rect(self: *Builder, rect: Rect) !void {
    try self.region_rects.ensureUnusedCapacity(self.gpa, 1);
    self.region_rects.appendAssumeCapacity(rect);
}

pub fn add_cell(self: *Builder, cell: Cell) !void {
    try self.add_rect(.from_cell(cell));
}

pub fn add_line(self: *Builder, direction: Cell.Direction, length: usize) !void {
    std.debug.assert(self.region_rects.items.len > 0);
    try self.region_rects.ensureUnusedCapacity(self.gpa, length);
    for (0..length) |_| {
        const prev_rect = self.region_rects.getLast();
        std.debug.assert(prev_rect.width() == 1 and prev_rect.height() == 1);
        const prev = prev_rect.min;
        try self.add_cell(prev.neighbor(direction) orelse return);
    }
}

pub fn add_line_within_region(self: *Builder, direction: Cell.Direction, region: Region) !void {
    std.debug.assert(self.region_rects.items.len > 0);
    const prev_rect = self.region_rects.getLast();
    std.debug.assert(prev_rect.width() == 1 and prev_rect.height() == 1);

    var bounds: Rect = .empty;
    region.expand_bounds(&bounds);

    var cell = prev_rect.min;
    while (true) {
        cell = cell.neighbor(direction) orelse return;
        if (!bounds.contains(cell)) return;
        if (region.contains(cell)) {
            try self.add_cell(cell);
        }
    }
}

pub fn build_region(self: *Builder) !Region {
    std.debug.assert(self.region_rects.items.len > 0);
    if (self.region_rects.items.len == 1) {
        const region: Region = .single(.{ .rect = self.region_rects.items[0] });
        self.region_rects.clearRetainingCapacity();
        return region;
    }
    const rects = try self.arena.dupe(Rect, self.region_rects.items);
    self.region_rects.clearRetainingCapacity();
    return .multi(rects);
}

pub fn region_diagonal_ascending(self: *Builder, dim: usize) !Region {
    self.assert_empty_region();
    try self.add_cell(.init(1, dim));
    try self.add_line(.northeast, dim - 1);
    return try self.build_region();
}

pub fn region_diagonal_descending(self: *Builder, dim: usize) !Region {
    self.assert_empty_region();
    try self.add_cell(.init(1, 1));
    try self.add_line(.southeast, dim - 1);
    return try self.build_region();
}

pub fn region_along_line(self: *Builder, board: Region, starting_cell: Cell, direction: Cell.Direction) !Region {
    self.assert_empty_region();
    try self.add_cell(starting_cell);
    try self.add_line_within_region(direction, board);
    return try self.build_region();
}

pub fn build(self: *Builder) !Config {
    const constraints = try self.arena.dupe(Constraint, self.constraints.items);
    errdefer self.arena.free(constraints);
    const config: Config = try .init(self.arena, constraints);
    self.constraints.clearRetainingCapacity();
    return config;
}

pub fn add(self: *Builder, constraint: Constraint) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 1);
    self.constraints.appendAssumeCapacity(constraint);
}

pub fn add_4x4(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 13);
    self.constraints.appendAssumeCapacity(.{ .values = ._4x4 });
    try self.add_square_rows(4);
    try self.add_square_columns(4);
    try self.add_boxes_4x4();
}
pub fn add_6x6_wide_boxes(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 19);
    self.constraints.appendAssumeCapacity(.{ .values = ._6x6 });
    try self.add_square_rows(6);
    try self.add_square_columns(6);
    try self.add_boxes_6x6_wide();
}
pub fn add_6x6_tall_boxes(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 19);
    self.constraints.appendAssumeCapacity(.{ .values = ._6x6 });
    try self.add_square_rows(6);
    try self.add_square_columns(6);
    try self.add_boxes_6x6_tall();
}
pub fn add_9x9(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 28);
    self.constraints.appendAssumeCapacity(.{ .values = ._9x9 });
    try self.add_square_rows(9);
    try self.add_square_columns(9);
    try self.add_boxes_9x9();
}
pub fn add_12x12_wide_boxes(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 37);
    self.constraints.appendAssumeCapacity(.{ .values = ._12x12 });
    try self.add_square_rows(12);
    try self.add_square_columns(12);
    try self.add_boxes_12x12_wide();
}
pub fn add_12x12_tall_boxes(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 37);
    self.constraints.appendAssumeCapacity(.{ .values = ._12x12 });
    try self.add_square_rows(12);
    try self.add_square_columns(12);
    try self.add_boxes_12x12_tall();
}
pub fn add_16x16(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 49);
    self.constraints.appendAssumeCapacity(.{ .values = ._16x16 });
    try self.add_square_rows(16);
    try self.add_square_columns(16);
    try self.add_boxes_16x16();
}

pub fn add_unique_diagonals(self: *Builder, dim: usize) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 2);
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = try self.region_diagonal_ascending(dim) } });
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = try self.region_diagonal_descending(dim) } });
}

pub fn add_square_rows(self: *Builder, dim: usize) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, dim);
    for (1 .. dim + 1) |row| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .row(row, dim) });
    }
}
pub fn add_square_columns(self: *Builder, dim: usize) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, dim);
    for (1 .. dim + 1) |row| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .column(row, dim) });
    }
}

pub fn add_boxes_4x4(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 4);
    for (1..5) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_4x4(box) });
    }
}

pub fn add_boxes_6x6_wide(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 6);
    for (1..7) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_6x6_wide(box) });
    }
}

pub fn add_boxes_6x6_tall(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 6);
    for (1..7) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_6x6_tall(box) });
    }
}

pub fn add_boxes_9x9(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 9);
    for (1..10) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_9x9(box) });
    }
}

pub fn add_boxes_12x12_wide(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 12);
    for (1..13) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_12x12_wide(box) });
    }
}

pub fn add_boxes_12x12_tall(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 12);
    for (1..13) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_12x12_tall(box) });
    }
}

pub fn add_boxes_16x16(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 16);
    for (1..17) |box| {
        self.constraints.appendAssumeCapacity(.{ .unique_region = .box_16x16(box) });
    }
}

pub fn add_boxes_9x9_window(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 4);
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = .init(3, 3, .init(2, 2)) } });
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = .init(3, 3, .init(6, 2)) } });
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = .init(3, 3, .init(2, 6)) } });
    self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = .init(3, 3, .init(6, 6)) } });
}

pub fn add_disjoint_sets_9x9(self: *Builder) !void {
    try self.constraints.ensureUnusedCapacity(self.gpa, 9);
    self.assert_empty_region();
    try self.region_rects.ensureUnusedCapacity(self.gpa, 9);
    for (0..3) |x| {
        for (0..3) |y| {
            try self.add_cell(.init(x + 1, y + 1));
            try self.add_cell(.init(x + 4, y + 1));
            try self.add_cell(.init(x + 7, y + 1));
            try self.add_cell(.init(x + 1, y + 4));
            try self.add_cell(.init(x + 4, y + 4));
            try self.add_cell(.init(x + 7, y + 4));
            try self.add_cell(.init(x + 1, y + 7));
            try self.add_cell(.init(x + 4, y + 7));
            try self.add_cell(.init(x + 7, y + 7));
            self.constraints.appendAssumeCapacity(.{ .unique_region = .{ .region = try self.build_region() } });
        }
    }
}

pub fn add_thermo(self: *Builder, bulb: Cell, path: []const Cell.Direction) !void {
    self.assert_empty_region();
    try self.region_rects.ensureUnusedCapacity(self.gpa, path.len + 1);
    try self.add_cell(bulb);
    for (path) |dir| {
        try self.add_line(dir, 1);
    }
    try self.add(.{ .ascending_line = .init(try self.build_region(), .{}) });
}

pub fn add_arrow(self: *Builder, bulb: Cell, path: []const Cell.Direction) !void {
    var regions = self.arena.alloc(Region, 2);
    errdefer self.arena.free(regions);

    regions[0] = .single(.{ .offset = bulb });

    self.assert_empty_region();
    try self.region_rects.ensureUnusedCapacity(self.gpa, path.len + 1);
    try self.add_cell(bulb.neighbor(path[0]));
    for (path[1..]) |dir| {
        try self.add_line(dir, 1);
    }
    regions[1] = try self.build_region();

    try self.add(.{ .equal_sum_regions = .{ .regions = regions } });
}

const Builder = @This();

const Cell = @import("../Cell.zig");
const Rect = @import("../Rect.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const Constraint = @import("../constraint.zig").Constraint;
const std = @import("std");
