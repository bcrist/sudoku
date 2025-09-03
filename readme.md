# Variant Sudoku Solver

A zig library that can solve sudoku puzzles, including variants such as:

* Samurai/Mini/Mega Sudoku (4x4, 6x6, 12x12, 16x16, etc)
* Window Sudoku
* Irregular-regions
* Diagonals
* Killer cages
* Arrows
* Thermos
* Kropki dots
* XV
* Odd/Even cells

Some variants that are _not_ currently supported include:

* Fog-of-war (or any other variant that involves dynamic discovery of additional constraints while solving)
* Incompletely specified constraints (e.g. "draw a line such that...", etc.)  These could likely be supported with some work, but it's usually harder to write a more generalized form of these constraints.
* "Wrogn" constraints (where some or all constraints need to be ignored or "inverted" and the solver must deduce which ones are correct)

## How it works
The core algorithm used to solve puzzles has two parts:
1. Evaluate all constraints until no new information is discovered
2. Bifurcate on the value of one particular cell and recurse

During the first step, if any constraints have been violated, the puzzle is unsolvable.  Otherwise, constraints may be able to eliminate some digits from the set of possible digits for one or more cells.  This repeats until the full set of constraints can be visited without eliminating any additional possible values.  Easy standard sudoku puzzles can often be completely solved with this step alone.

During the second step the algorithm asks "What happens if I set one cell to a particular digit?"  If the puzzle eventually becomes unsolvable with that digit, it tries again with a different digit until there are no options remaining.  Effectively this acts as a depth-first search, but since the constraints are re-evaluated every time a new cell is selected, the search space converges faster than you might expect (as long as the puzzle has enough constraints to guarantee a single unique solution).  In manual solving, this strategy is known as bifurcation or "guess and check" and is often frowned-upon, and there exist more efficient algorithms, but bifurcation provides maximum flexibility of constraints, is guaranteed to work for any puzzle, and makes it possible to find every unique solution, if more than one exists.  There are, however, a few things it's not good at:

1. Some puzzles solve very slowly.  e.g. Puzzles where the intended strategy involves "coloring", i.e. symbolically solving the entire puzzle, then at the end disambiguating the mapping of colors/symbols to digits.
2. Discovering what partial deductions can be made about a severely under-constrained puzzle.
3. Explaining the logical deductions required to solve the puzzle.

The last two are things that are mainly useful for puzzle setters.  The first can be mitigated somewhat, for a large increase in computational cost.  The second is something that very few automated solvers attempt, as it effectively requires programming implementations of all of the manual solving strategies other than bifurcation, and even then, there are likely to be puzzles that can only be solved by resorting to bifurcation (and indeed many solving strategies can be considered "bifurcation with limited lookahead").

## Usage
Zig 0.15.1 is required (newer versions may or may not work).  Add the library to your project with:

```
$ zig fetch --save git+https://github.com/bcrist/sudoku
```

Then in your `build.zig`, add the `sudoku` module as an import to your root module.

Typical usage example:

```zig
const gpa = std.heap.smp_allocator;

var arena: std.heap.ArenaAllocator = .init(gpa);
defer arena.deinit();

var b: sudoku.Constraint.Builder = .init(gpa, arena.allocator());
defer b.deinit();

try b.add_9x9();

var config = try b.build();
config.init_cells(
    \\   5  9  
    \\   6  87 
    \\4 32 8   
    \\6      5 
    \\  9 3 4  
    \\ 8      7
    \\   7 46 1
    \\ 21  9   
    \\  6  2   
);

var stdout_buf: [64]u8 = undefined;
const w = std.fs.File.stdout().writer(&stdout_buf);

const result = try config.solve(gpa, .default);
if (result.solution) |solution| {
    defer solution.deinit(gpa);
    try solution.debug(cfg, &w.interface);
} else {
    try w.interface.writeAll("No solution found!\n");
}

try w.interface.flush();
```

All of the rules that the puzzle must follow are encoded into a [`sudoku.Constraint`](./src/constraint.zig) array and stored in a [`sudoku.Config`](./src/Config.zig) struct.  This includes the basic Sudoku rules (i.e. "Place the digits 1-9 into every row, column, and 3x3 box so that no digit is repeated in any row/column/box") if applicable.  The [`sudoku.Constraint.Builder`](./src/constraint/Builder.zig) struct contains helpers for setting up these constraints.

The [`sudoku.Config`](./src/Config.zig) struct also contains a [`sudoku.State`](./src/State.zig) struct that allows you to set up any given digits.  You can set a given digit with calls to `config.init_cells(string)` or `config.init_cell(.init(x, y), digit);` (note the standard constraints assume 1-based indexing for x and y coordinates).  You could alternatively encode these as constraints:

```zig
try builder.add(.{ .values = .init_range(digit, digit, .single(.{ .offset = .init(x, y) })) });
```

 but such constraints will never provide any extra information after the first time they're evaluated, so doing it that way will just add extra busywork for the solver.

To solve the puzzle, in most cases you can just call `const result = config.solve(allocator, .default);`.  If a solution is found, `result.solution` will be non-null, and you can print the solution with `result.solution.?.debug(config, writer)`.  Also note that you will leak memory if you don't call `result.solution.?.deinit(allocator);`.

By default, the solver will stop if it finds more than one solution.  If you want to see how many other solutions there are you can pass `.multi_solution` or a custom `sudoku.Default_Context` to `config.solve`.  The number of solutions will be found in `result.context.counters.solutions`.  Note that severely under-constrained configurations with thousands or millions of solutions may take a long time to solve, so `.multi_solution` will give up after 101 solutions.  The result solution will always just be the first solution found.  If you want to examine all of the solutions, you have to create a custom context with an `on_solution` callback and use `sudoku.State.solve` directly.  For example, to print every solution to `stdout`:

```zig
const Context = struct {
    pub fn on_solution(self: @This(), cfg: sudoku.Config, solution: sudoku.State, depth: usize) !void {
        _ = self;
        _ = depth;
        var buf: [64]u8 = undefined;
        const w = std.fs.File.stdout().writer(&buf);
        try w.interface.writeAll("Found solution:\n");
        try solution.debug(cfg, &w.interface);
        try w.interface.flush();
    }
};

var temp = config.initial_state;
_ = try temp.solve(allocator, config, Context{});
```

As mentioned above, the default solver does not handle severely under-constrained puzzles well.  A special alternative [`sudoku.Setter_Context`](./src/Setter_Context.zig) is therefore provided.  This context keeps track of the union of all solutions discovered, such as a puzzle setter might want to know when designing a puzzle.  When this context is used, the solver switches to a stochastic breadth-first-search strategy, which is not guaranteed to find all solutions and always runs until a certain number of boards have been examined (`Init_Options.max_stochastic_backtracks`) or a certain number of solutions have been found (`Init_Options.max_stochastic_solutions`).  If very few solutions are found (less than `Init_Options.min_solutions`), then it will switch back to the default depth-first-search strategy to ensure all solutions have been found.  As with the default context, the first solution found will be assigned to the `State` struct before returning.

## Values, Cells, Rects, and Regions

The [`sudoku.Cell`](./src/Cell.zig) struct acts as a reference to a particular cell in the puzzle (i.e. the things that you write a number into in standard sudoku).  The state of each cell is represented by a 64-bit `std.bit_set.IntegerBitSet`.  This means that puzzles can have up to 64 distinct symbols (i.e. digits).  By convention, the first ten bits (i.e. the least significant bits) represent the digits 0-9, so that arithmetic constraints don't need to do any mapping between symbol indices and values.

Cells are assumed to be located on a 2D grid, and usually they will be in a square or rectangular pattern, so the [`sudoku.Rect`](./src/Rect.zig) struct can be used to refer to any finite rectangle on the infinite, virtual "board".  Cells within the rect can be iterated using `rect.iterator()`.

Sometimes it's desirable to refer to non-rectangular regions. (e.g. for Samurai Sudoku, disjoint sets, renban lines, whispers lines, etc.)  A [`sudoku.Region`](./src/region.zig) struct can either directly store either a single `Rect` (since this is the most common case) or it can store a slice of rects, where the region is considered to be the set of cells that is covered by at least one of the rects.  The cells can be iterated with `region.iterator()`.  Note if multiple rects cover the same cell, it will only be visited once, and it will be when processing the largest index of the rects array that contains that cell.

Most constraints have a `region` field that determines what area of the board they affect.  [Config.init()](./src/Config.zig) will automatically determine the set of cells that at least one of the constraints is interested in, and map it to a slot in the [State.cells](./src/State.zig) array.

## Constraints

All puzzles should have at least one [Values](./src/constraint/Values.zig) constraint, which determines which "digits" are being used.  Normally, this will cover all cells in the puzzle.  In rare cases, you might have multiple, non-overlapping Values constraints; e.g. if part of the puzzle uses the digits 1-9 and a different part uses digits 1-6.  Values constraints can also be used for rules like odd/even regions.

All of the standard sudoku rules are handled by [Unique_Region](./src/constraint/Unique_Region.zig) constraints.  This constraint ensures that all cells in a particular region must have unique values.  It can also be used for irregular sudoku, diagonals, multi/samurai sudoku, disjoint sets, etc.  Note that while it's common for the region to be the same size as the cardinality of the `Values` constraint covering that region, it may also be a smaller region.  Of course, if it's a larger region, then the puzzle is unsolvable by definition.

Take a look at [tests.zig](./tests.zig) for some examples of how to set up various constraints.

If there's a type of variant sudoku that you want to solve but can't because none of the available constraint types adequately handle it, feel free to open an issue.
