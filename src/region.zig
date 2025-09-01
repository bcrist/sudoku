pub const Region = union (enum) {
    single_rect: Rect,
    multi_rect: []const Rect,

    pub fn single(r: Rect.Init_Options) Region {
        return .{ .single_rect = .init(r) };
    }

    pub fn multi(r: []const Rect) Region {
        return .{ .multi_rect = r };
    }

    pub fn rects(self: *const Region) []const Rect {
        return switch (self.*) {
            .single_rect => |*rect| rect[0..1],
            .multi_rect => |slice| slice,
        };
    }

    pub fn expand_bounds(self: Region, bounds: *Rect) void {
        for (self.rects()) |rect| {
            rect.expand_bounds(bounds);
        }
    }

    pub fn contains(self: Region, cell: Cell) bool {
        for (self.rects()) |rect| {
            if (rect.contains(cell)) return true;
        }
        return false;
    }

    pub fn iterator(self: Region, dir: Cell.Iteration_Direction) Iterator {
        return switch (self) {
            .single_rect => |rect| .{
                .current = rect.iterator(dir),
                .current_rect = 0,
                .rects = &.{},
            },
            .multi_rect => |slice| if (slice.len == 0) .{
                .current = Rect.empty.iterator(dir),
                .current_rect = 0,
                .rects = slice,
            } else switch (dir) {
                .forward => .{
                    .current = slice[0].iterator(.forward),
                    .current_rect = 0,
                    .rects = slice,
                },
                .reverse => .{
                    .current = slice[slice.len - 1].iterator(.reverse),
                    .current_rect = slice.len - 1,
                    .rects = slice,
                },
            },
        };
    }

    pub const Iterator = struct {
        current: Rect.Iterator,
        current_rect: usize,
        rects: []const Rect,

        pub fn next(self: *Iterator) ?Cell {
            next_cell: while (true) {
                const cell = self.current.next() orelse {
                    switch (self.current.dir) {
                        .forward => {
                            if (self.current_rect + 1 >= self.rects.len) return null;
                            self.current_rect += 1;
                        },
                        .reverse => {
                            if (self.current_rect == 0) return null;
                            self.current_rect -= 1;
                        },
                    }
                    self.current = self.rects[self.current_rect].iterator(self.current.dir);
                    continue;
                };

                if (self.current_rect + 1 < self.rects.len) {
                    for (self.rects[self.current_rect + 1 ..]) |rect| {
                        if (rect.contains(cell)) continue :next_cell;
                    }
                }

                return cell;
            }
        }

        pub const done: Iterator = .{
            .current = .done,
            .current_rect = 0,
            .rects = &.{},
        };
    };
};

const Cell = @import("Cell.zig");
const Rect = @import("Rect.zig");
const std = @import("std");
