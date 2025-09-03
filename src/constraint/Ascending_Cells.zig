//! Requires that each cell in the region contains a larger value than the previous one
//! a.k.a. Thermometers
//! Note only single cell Rects should be used in the region to ensure expected iteration order.

region: Region,
        
pub fn evaluate(self: @This(), config: *const Config, state: *State) error{NotSolvable}!void {
    var prev: Cell.Value_Options = .initFull();
    var iter = self.region.iterator(.forward);
    while (iter.next()) |cell| {
        prev = state.intersect(config, cell, get_ascending_options(prev));
    }

    prev = .initFull();
    iter = self.region.iterator(.reverse);
    while (iter.next()) |cell| {
        prev = state.intersect(config, cell, get_descending_options(prev));
    }
}

pub fn get_ascending_options(prev: Cell.Value_Options) Cell.Value_Options {
    const prev_lsb = prev.findFirstSet() orelse return .initFull();
    var bad_options: Cell.Value_Options = .initEmpty();
    bad_options.set(prev_lsb);
    bad_options.mask |= bad_options.mask - 1;
    return bad_options.complement();
}

pub fn get_descending_options(prev: Cell.Value_Options) Cell.Value_Options {
    const prev_msb = prev.findLastSet() orelse return .initFull();
    var new_options: Cell.Value_Options = .initEmpty();
    new_options.set(prev_msb);
    new_options.mask -= 1;
    return new_options;
}

const Cell = @import("../Cell.zig");
const Region = @import("../region.zig").Region;
const Config = @import("../Config.zig");
const State = @import("../State.zig");
