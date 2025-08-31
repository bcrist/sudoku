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

    pub fn iterator(self: Region) Iterator {
        return switch (self) {
            .single_rect => |rect| .{
                .current = rect.iterator(),
                .remaining = &.{},
            },
            .multi_rect => |slice| .{
                .current = .done,
                .remaining = slice,
            },
        };
    }

    pub fn reverse_iterator(self: Region) Reverse_Iterator {
        return switch (self) {
            .single_rect => |rect| .{
                .current = rect.iterator(),
                .current_rect = 0,
                .rects = &.{},
            },
            .multi_rect => |slice| .{
                .current = .done,
                .current_rect = slice.len,
                .rects = slice,
            },
        };
    }

    pub const Iterator = struct {
        current: Rect.Iterator,
        remaining: []const Rect,

        pub fn next(self: *Iterator) ?Cell {
            next_cell: while (true) {
                const cell = self.current.next() orelse {
                    if (self.remaining.len == 0) return null;
                    self.current = self.remaining[0].iterator();
                    self.remaining = self.remaining[1..];
                    continue;
                };

                for (self.remaining) |rect| {
                    if (rect.contains(cell)) continue :next_cell;
                }

                return cell;
            }
        }
    };

    pub const Reverse_Iterator = struct {
        current: Rect.Reverse_Iterator,
        current_rect: usize,
        rects: []const Rect,

        pub fn next(self: *Reverse_Iterator) ?Cell {
            next_cell: while (true) {
                const cell = self.current.next() orelse {
                    if (self.current_rect == 0) return null;
                    self.current_rect -= 1;
                    self.current = self.rects[self.current_rect].reverse_iterator();
                    continue;
                };

                if (self.current_rect < self.rects.len) {
                    for (self.rects[self.current_rect + 1 ..]) |rect| {
                        if (rect.contains(cell)) continue :next_cell;
                    }
                }

                return cell;
            }
        }
    };
};

const Cell = @import("Cell.zig");
const Rect = @import("Rect.zig");
const std = @import("std");
