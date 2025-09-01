min: Cell,
max: Cell,

pub const Init_Options = struct {
    rect: ?Rect = null,
    dim: ?usize = null,
    dims: ?Rect = null,
    width: ?usize = null,
    height: ?usize = null,
    offset: ?Cell = null,
};

pub fn init(options: Init_Options) Rect {
    const offset: Cell = options.offset orelse .init(1, 1);
    var w: usize = options.width orelse options.dim orelse 1;
    var h: usize = options.height orelse options.dim orelse 1;

    if (options.rect) |rect| {
        std.debug.assert(options.dim == null);
        std.debug.assert(options.dims == null);
        std.debug.assert(options.width == null);
        std.debug.assert(options.height == null);
        std.debug.assert(options.offset == null);
        return rect;
    }

    if (options.dim) |_| {
        std.debug.assert(options.dims == null);
        std.debug.assert(options.width == null);
        std.debug.assert(options.height == null);
    }

    if (options.dims) |dim_rect| {
        w = dim_rect.width();
        h = dim_rect.height();
        std.debug.assert(options.width == null);
        std.debug.assert(options.height == null);
    }

    return .{
        .min = offset,
        .max = .init(offset.x + w - 1, offset.y + h - 1),
    };
}

pub fn from_cell(cell: Cell) Rect {
    return .{
        .min = cell,
        .max = cell,
    };
}

pub fn width(self: Rect) u16 {
    return if (self.min.x > self.max.x) 0 else self.max.x - self.min.x + 1;
}

pub fn height(self: Rect) u16 {
    return if (self.min.y > self.max.y) 0 else self.max.y - self.min.y + 1;
}

pub fn expand_bounds(self: Rect, bounds: *Rect) void {
    if (bounds.width() == 0 or bounds.height() == 0) {
        bounds.* = self;
    } else {
        bounds.min.x = @min(self.min.x, bounds.min.x);
        bounds.min.y = @min(self.min.y, bounds.min.y);
        bounds.max.x = @max(self.max.x, bounds.max.x);
        bounds.max.y = @max(self.max.y, bounds.max.y);
    }
}

pub fn contains(self: Rect, cell: Cell) bool {
    return self.min.x <= cell.x and self.max.x >= cell.x
        and self.min.y <= cell.y and self.max.y >= cell.y;
}

pub fn iterator(self: Rect, dir: Cell.Iteration_Direction) Iterator {
    return .{
        .dir = dir,
        .rect = self,
        .n = if (self.width() == 0 or self.height() == 0) null else switch (dir) {
            .forward => self.min,
            .reverse => self.max,
        },
    };
}

pub const empty: Rect = .{
    .min = .init(1, 1),
    .max = .origin,
};

pub const origin: Rect = .{
    .min = .origin,
    .max = .origin,
};

pub const Iterator = struct {
    dir: Cell.Iteration_Direction,
    rect: Rect,
    n: ?Cell,

    pub fn next(self: *Iterator) ?Cell {
        const cell = self.n orelse return null;
        var n = cell;
        switch (self.dir) {
            .forward => {
                if (n.x < self.rect.max.x) {
                    n.x += 1;
                } else {
                    n.x = self.rect.min.x;
                    if (n.y < self.rect.max.y) {
                        n.y += 1;
                    } else {
                        self.n = null;
                        return cell;
                    }
                }
            },
            .reverse => {
                if (n.x > self.rect.min.x) {
                    n.x -= 1;
                } else {
                    n.x = self.rect.max.x;
                    if (n.y > self.rect.min.y) {
                        n.y -= 1;
                    } else {
                        self.n = null;
                        return cell;
                    }
                }
            },
        }
        self.n = n;
        return cell;
    }

    pub const done: Iterator = .{
        .dir = .forward,
        .rect = .empty,
        .n = null,
    };
};

const Rect = @This();

const Cell = @import("Cell.zig");
const std = @import("std");
