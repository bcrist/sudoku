test "basic" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
    defer b.deinit();

    try b.add(.{ .values = .init_range(1, 5, .single(.{ .width = 5, .height = 1 })) });
    try b.add(.{ .unique_region = .row(1, 5) });

    var config = try b.build();
    config.init_cell(.init(1, 1), 3);
    config.init_cell(.init(2, 1), 2);
    config.init_cell(.init(3, 1), 4);
    config.init_cell(.init(4, 1), 1);

    const result = try config.solve(std.testing.allocator, .no_backtracks);
    defer result.solution.?.deinit(std.testing.allocator);
    try check_solution(&config, result,
        \\32415
        \\
    );
}

test "standard sudoku (easy)" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
    defer b.deinit();

    try b.add_9x9();

    var config = try b.build();
    config.init_cells(
        \\26  9    
        \\ 5 3   17
        \\318 2  5 
        \\ 9 8    3
        \\ 72 3 58 
        \\5    7 9 
        \\ 4  1 679
        \\72   6 4 
        \\    7  25
    );
    
    const result = try config.solve(std.testing.allocator, .no_backtracks);
    defer result.solution.?.deinit(std.testing.allocator);
    try check_solution(&config, result,
        \\267195438
        \\954368217
        \\318724956
        \\491852763
        \\672931584
        \\583647192
        \\845213679
        \\729586341
        \\136479825
        \\
    );
}

test "standard sudoku (hard)" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
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
    
    const result = try config.solve(std.testing.allocator, .default);
    defer result.solution.?.deinit(std.testing.allocator);
    try check_solution(&config, result,
        \\867541932
        \\152693874
        \\493278516
        \\614987253
        \\279135468
        \\385426197
        \\938754621
        \\721869345
        \\546312789
        \\
    );
}

test "https://www.youtube.com/watch?v=Nbp5FRyACmA" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
    defer b.deinit();

    const board: sudoku.Rect = .init(.{ .dim = 4 });

    try b.add(.{ .values = .init_range(1, 9, .single(.{ .rect = board })) });
    try b.add_square_rows(4);
    try b.add_square_columns(4);
    try b.add_boxes_4x4();
    try b.add(.{ .sum_region = .init(17, .single(.{ .width = 1, .height = 2, .offset = .init(2, 2) })) });
    try b.add(.{ .sum_region = .init( 6, .single(.{ .width = 1, .height = 2, .offset = .init(3, 1) })) });
    try b.add(.{ .sum_region = .init( 5, .single(.{ .width = 1, .height = 2, .offset = .init(4, 2) })) });

    var white_kropki: sudoku.Constraint.kropki.White = try .init(std.testing.allocator, board);
    defer white_kropki.deinit(std.testing.allocator);
    white_kropki.add_horizontal_dot(.init(1, 2));
    white_kropki.add_horizontal_dot(.init(3, 2));
    white_kropki.add_horizontal_dot(.init(1, 4));
    white_kropki.add_vertical_dot(.init(2, 2));
    try b.add(.{ .white_kropki = white_kropki });

    var black_kropki: sudoku.Constraint.kropki.Black = try .init(std.testing.allocator, board);
    defer black_kropki.deinit(std.testing.allocator);
    try b.add(.{ .black_kropki = black_kropki });

    var unique_ratios: sudoku.Constraint.misc.Unique_Pairs_Rect = try .init(std.testing.allocator, board);
    defer unique_ratios.deinit(std.testing.allocator);
    unique_ratios.impl.unique_ratios = true;
    unique_ratios.params.horizontal_dots.toggleAll();
    unique_ratios.params.vertical_dots.toggleAll();
    try b.add(.{ .unique_pairs_rect = unique_ratios });

    var config = try b.build();
    
    const result = try config.solve(std.testing.allocator, .default);
    defer result.solution.?.deinit(std.testing.allocator);
    try check_solution(&config, result,
        \\4619
        \\7854
        \\2971
        \\6538
        \\
    );
}

test "standard sudoku details" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
    defer b.deinit();

    try b.add_9x9();

    var config = try b.build();
    config.init_cells(
        \\26  9    
        \\ 5 3   17
        \\318 2  5 
        \\ 9 8    3
        \\ 72 3 58 
        \\5    7 9 
        \\ 4  1 679
        \\72   6 4 
        \\    7  25
    );

    var temp: std.ArrayList(u8) = .empty;
    defer temp.deinit(std.testing.allocator);

    var writer = temp.writer(std.testing.allocator).adaptToNewApi(&.{});

    var state = config.initial_state;

    try std.testing.expectEqual(.unsolved, config.constraints[0].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 1111111110 1111111110 1000000000 1111111110 1111111110 1111111110 1111111110 
        \\1111111110 0000100000 1111111110 0000001000 1111111110 1111111110 1111111110 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 1111111110 0000000100 1111111110 1111111110 0000100000 1111111110 
        \\1111111110 1000000000 1111111110 0100000000 1111111110 1111111110 1111111110 1111111110 0000001000 
        \\1111111110 0010000000 0000000100 1111111110 0000001000 1111111110 0000100000 0100000000 1111111110 
        \\0000100000 1111111110 1111111110 1111111110 1111111110 0010000000 1111111110 1000000000 1111111110 
        \\1111111110 0000010000 1111111110 1111111110 0000000010 1111111110 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1111111110 1111111110 1111111110 0001000000 1111111110 0000010000 1111111110 
        \\1111111110 1111111110 1111111110 1111111110 0010000000 1111111110 1111111110 0000000100 0000100000 
        \\
        , temp.items);

    // column constraints
    try std.testing.expectEqual(.unsolved, config.constraints[10].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[11].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[12].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[13].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[14].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[15].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[16].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[17].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[18].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 1011111010 1011110110 1000000000 1100111110 1110011110 0001001000 0101010110 
        \\1101010010 0000100000 1011111010 0000001000 0101110000 1100111110 1110011110 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 1011110110 0000000100 1100111110 1110011110 0000100000 0101010110 
        \\1101010010 1000000000 1011111010 0100000000 0101110000 1100111110 1110011110 0001001000 0000001000 
        \\1101010010 0010000000 0000000100 1011110110 0000001000 1100111110 0000100000 0100000000 0101010110 
        \\0000100000 0100001000 1011111010 1011110110 0101110000 0010000000 1110011110 1000000000 0101010110 
        \\1101010010 0000010000 1011111010 1011110110 0000000010 1100111110 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1011111010 1011110110 0101110000 0001000000 1110011110 0000010000 0101010110 
        \\1101010010 0100001000 1011111010 1011110110 0010000000 1100111110 1110011110 0000000100 0000100000 
        \\
        , temp.items);

    // row constraints
    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[2].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[3].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[4].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[5].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[6].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[7].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[8].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[9].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 0010110010 0010110010 1000000000 0100110010 0110010010 0000001000 0100010010 
        \\1101010000 0000100000 1001010000 0000001000 0101010000 1100010100 1100010100 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 1011010000 0000000100 1000010000 1010010000 0000100000 0001010000 
        \\0001010010 1000000000 0011110010 0100000000 0001110000 0000110110 0010010110 0001000000 0000001000 
        \\1001010010 0010000000 0000000100 1001010010 0000001000 1000010010 0000100000 0100000000 0001010010 
        \\0000100000 0100001000 0001011010 0001010110 0101010000 0010000000 0100011110 1000000000 0101010110 
        \\0100000000 0000010000 0000101000 0000100100 0000000010 0100101100 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1000101010 1000100010 0100100000 0001000000 1100001010 0000010000 0100000010 
        \\1101010010 0100001000 1001011010 1001010010 0010000000 1100011010 1100011010 0000000100 0000100000 
        \\
        , temp.items);

    // box constraints
    try std.testing.expectEqual(.unsolved, config.constraints[19].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[20].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[21].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[22].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[23].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[24].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[25].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[26].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[27].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 0010010000 0010100010 1000000000 0100100010 0100010000 0000001000 0100010000 
        \\1000010000 0000100000 1000010000 0000001000 0101000000 0100000000 1100010100 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 0011000000 0000000100 0000010000 1000010000 0000100000 0001010000 
        \\0001010010 1000000000 0001010010 0100000000 0001110000 0000110110 0010010110 0001000000 0000001000 
        \\0001010010 0010000000 0000000100 1001010010 0000001000 1000010010 0000100000 0100000000 0000010010 
        \\0000100000 0100001000 0001011010 0001010110 0001010000 0010000000 0000010110 1000000000 0000010110 
        \\0100000000 0000010000 0000100000 0000100100 0000000010 0100101100 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1000100010 1000100000 0100100000 0001000000 0100001010 0000010000 0100000010 
        \\1001000010 0000001000 1001000010 1000010000 0010000000 1100011000 0100001010 0000000100 0000100000 
        \\
        , temp.items);

    // column constraints
    try std.testing.expectEqual(.unsolved, config.constraints[10].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[11].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[12].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[13].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[14].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[15].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[16].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[17].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[18].evaluate(&config, &state));

    // row constraints
    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[2].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[3].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[4].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[5].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[6].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[7].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[8].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[9].evaluate(&config, &state));

    // box constraints
    try std.testing.expectEqual(.unsolved, config.constraints[19].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[20].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[21].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[22].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[23].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[24].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[25].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[26].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[27].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 0010010000 0000100010 1000000000 0000100010 0100010000 0000001000 0100010000 
        \\1000010000 0000100000 1000010000 0000001000 0001000000 0100000000 0000010100 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 0010000000 0000000100 0000010000 1000000000 0000100000 0001000000 
        \\0000010010 1000000000 0000010010 0100000000 0000110000 0000100110 0010010110 0001000000 0000001000 
        \\0001010010 0010000000 0000000100 1001010010 0000001000 1000000010 0000100000 0100000000 0000010010 
        \\0000100000 0100000000 0001011010 0001010110 0001010000 0010000000 0000010110 1000000000 0000010110 
        \\0100000000 0000010000 0000100000 0000000100 0000000010 0000001000 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1000000010 0000100000 0100100000 0001000000 0100001010 0000010000 0100000010 
        \\0001000010 0000001000 0001000010 0000010000 0010000000 1000000000 0100000010 0000000100 0000100000 
        \\
        , temp.items);

    // column constraints
    try std.testing.expectEqual(.unsolved, config.constraints[10].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[11].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[12].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[13].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[14].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[15].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[16].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[17].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[18].evaluate(&config, &state));

    // row constraints
    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[2].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[3].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[4].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[5].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[6].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[7].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[8].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[9].evaluate(&config, &state));

    // box constraints
    try std.testing.expectEqual(.unsolved, config.constraints[19].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[20].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[21].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[22].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[23].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[24].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[25].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[26].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[27].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 0010010000 0000000010 1000000000 0000100000 0100010000 0000001000 0100010000 
        \\1000010000 0000100000 1000010000 0000001000 0001000000 0100000000 0000010100 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 0010000000 0000000100 0000010000 1000000000 0000100000 0001000000 
        \\0000010010 1000000000 0000010010 0100000000 0000100000 0000000100 0010000110 0001000000 0000001000 
        \\0001000000 0010000000 0000000100 1000000000 0000001000 0000000010 0000100000 0100000000 0000010000 
        \\0000100000 0100000000 0000001010 0001000000 0000010000 0010000000 0000000110 1000000000 0000000110 
        \\0100000000 0000010000 0000100000 0000000100 0000000010 0000001000 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1000000000 0000100000 0100000000 0001000000 0000001000 0000010000 0000000010 
        \\0001000010 0000001000 0001000010 0000010000 0010000000 1000000000 0100000000 0000000100 0000100000 
        \\
        , temp.items);

    // column constraints
    try std.testing.expectEqual(.unsolved, config.constraints[10].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[11].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[12].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[13].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[14].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[15].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[16].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[17].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[18].evaluate(&config, &state));

    // row constraints
    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[2].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[3].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[4].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[5].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[6].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[7].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[8].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[9].evaluate(&config, &state));

    // box constraints
    try std.testing.expectEqual(.unsolved, config.constraints[19].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[20].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[21].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[22].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[23].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[24].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[25].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[26].evaluate(&config, &state));
    try std.testing.expectEqual(.unsolved, config.constraints[27].evaluate(&config, &state));

    temp.clearRetainingCapacity();
    try state.debug_full(&config, &writer.new_interface);
    try std.testing.expectEqualStrings(
        \\0000000100 0001000000 0010000000 0000000010 1000000000 0000100000 0000010000 0000001000 0100000000 
        \\1000000000 0000100000 0000010000 0000001000 0001000000 0100000000 0000000100 0000000010 0010000000 
        \\0000001000 0000000010 0100000000 0010000000 0000000100 0000010000 1000000000 0000100000 0001000000 
        \\0000010000 1000000000 0000000010 0100000000 0000100000 0000000100 0010000000 0001000000 0000001000 
        \\0001000000 0010000000 0000000100 1000000000 0000001000 0000000010 0000100000 0100000000 0000010000 
        \\0000100000 0100000000 0000001000 0001000000 0000010000 0010000000 0000000010 1000000000 0000000100 
        \\0100000000 0000010000 0000100000 0000000100 0000000010 0000001000 0001000000 0010000000 1000000000 
        \\0010000000 0000000100 1000000000 0000100000 0100000000 0001000000 0000001000 0000010000 0000000010 
        \\0000000010 0000001000 0001000000 0000010000 0010000000 1000000000 0100000000 0000000100 0000100000 
        \\
        , temp.items);

    try std.testing.expect(state.status() == .solved);
}

fn check_solution(config: *const sudoku.Config, result: sudoku.Config.Solve_Result, expected: []const u8) !void {
    errdefer {
        std.debug.print(
            \\
            \\   Solutions: {}
            \\   Max depth: {}
            \\  Backtracks: {}
            \\Bifurcations: {}
            \\ Evaluations: {}
            \\
            \\
            , .{
                result.context.counters.solutions,
                result.context.counters.max_depth,
                result.context.counters.backtracks,
                result.context.counters.bifurcations,
                result.context.counters.evaluations,
            });

        if (result.solution) |solution| {
            var buf: [64]u8 = undefined;
            var stderr = std.fs.File.stderr().writerStreaming(&buf);
            solution.debug(config, &stderr.interface) catch {};
            stderr.interface.writeByte('\n') catch {};
            stderr.interface.flush() catch {};
        } else {
            std.debug.print("(no solution)\n\n", .{});
        }
    }

    var w: std.io.Writer.Allocating = .init(std.testing.allocator);
    defer w.deinit();
    if (result.solution) |solution| {
        try solution.debug(config, &w.writer);
    }
    try std.testing.expectEqualStrings(expected, w.written());

    try std.testing.expect(result.context.counters.solutions > 0);
    try std.testing.expect(result.context.counters.solutions <= result.context.max_solutions);
    try std.testing.expect(result.context.counters.backtracks <= result.context.max_backtracks);
}

test "Cell.options" {
    try std.testing.expectEqual(0b0, sudoku.Cell.options("").mask);
    try std.testing.expectEqual(0b1, sudoku.Cell.options("0").mask);
    try std.testing.expectEqual(0b10, sudoku.Cell.options("1").mask);
    try std.testing.expectEqual(0b100, sudoku.Cell.options("2").mask);
    try std.testing.expectEqual(0b1000, sudoku.Cell.options("3").mask);
    try std.testing.expectEqual(0b10000, sudoku.Cell.options("4").mask);
    try std.testing.expectEqual(0b100000, sudoku.Cell.options("5").mask);
    try std.testing.expectEqual(0b1000000, sudoku.Cell.options("6").mask);
    try std.testing.expectEqual(0b10000000, sudoku.Cell.options("7").mask);
    try std.testing.expectEqual(0b100000000, sudoku.Cell.options("8").mask);
    try std.testing.expectEqual(0b1000000000, sudoku.Cell.options("9").mask);
    try std.testing.expectEqual(0b10000000000, sudoku.Cell.options("a").mask);
    try std.testing.expectEqual(0b1000000000000000000000000000000000000, sudoku.Cell.options("A").mask);
    try std.testing.expectEqual(0b1000001111100000, sudoku.Cell.options("56798f").mask);
    try std.testing.expectEqual(0x4000_0000_0000_0000, sudoku.Cell.options("@").mask);
    try std.testing.expectEqual(0x8000_0000_0000_0000, sudoku.Cell.options("#").mask);
    try std.testing.expectEqual(0xFFFF_FFFF_FFFF_FFFF, sudoku.Cell.options("*").mask);
    try std.testing.expectEqual(0xFFFF_FFFF_FFFF_FFFF, sudoku.Cell.options(" ").mask);
}

test "Cell.debug" {
    try std.testing.expectEqual(' ', sudoku.Cell.debug_options(.{ .mask = 0b0 }));
    try std.testing.expectEqual('0', sudoku.Cell.debug_options(.{ .mask = 0b1 }));
    try std.testing.expectEqual('1', sudoku.Cell.debug_options(.{ .mask = 0b10 }));
    try std.testing.expectEqual('2', sudoku.Cell.debug_options(.{ .mask = 0b100 }));
    try std.testing.expectEqual('3', sudoku.Cell.debug_options(.{ .mask = 0b1000 }));
    try std.testing.expectEqual('4', sudoku.Cell.debug_options(.{ .mask = 0b10000 }));
    try std.testing.expectEqual('5', sudoku.Cell.debug_options(.{ .mask = 0b100000 }));
    try std.testing.expectEqual('6', sudoku.Cell.debug_options(.{ .mask = 0b1000000 }));
    try std.testing.expectEqual('7', sudoku.Cell.debug_options(.{ .mask = 0b10000000 }));
    try std.testing.expectEqual('8', sudoku.Cell.debug_options(.{ .mask = 0b100000000 }));
    try std.testing.expectEqual('9', sudoku.Cell.debug_options(.{ .mask = 0b1000000000 }));
    try std.testing.expectEqual('a', sudoku.Cell.debug_options(.{ .mask = 0b10000000000 }));
    try std.testing.expectEqual('b', sudoku.Cell.debug_options(.{ .mask = 0b100000000000 }));
    try std.testing.expectEqual('c', sudoku.Cell.debug_options(.{ .mask = 0b1000000000000 }));
    try std.testing.expectEqual('d', sudoku.Cell.debug_options(.{ .mask = 0b10000000000000 }));
    try std.testing.expectEqual('e', sudoku.Cell.debug_options(.{ .mask = 0b100000000000000 }));
    try std.testing.expectEqual('f', sudoku.Cell.debug_options(.{ .mask = 0b1000000000000000 }));
    try std.testing.expectEqual('?', sudoku.Cell.debug_options(.{ .mask = 0b1000000001000000 }));
    try std.testing.expectEqual('@', sudoku.Cell.debug_options(.{ .mask = 0x4000_0000_0000_0000 }));
    try std.testing.expectEqual('#', sudoku.Cell.debug_options(.{ .mask = 0x8000_0000_0000_0000 }));
    try std.testing.expectEqual('*', sudoku.Cell.debug_options(.{ .mask = 0xFFFF_FFFF_FFFF_FFFF }));
}

test "Rect iterator" {
    const rect: sudoku.Rect = .init(.{
        .width = 3,
        .height = 3,
        .offset = .init(3, 3),
    });

    var iter = rect.iterator(.forward);
    try std.testing.expectEqual(sudoku.Cell.init(3, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(5, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(5, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(5, 5), iter.next().?);
    try std.testing.expectEqual(null, iter.next());

    iter = rect.iterator(.reverse);
    try std.testing.expectEqual(sudoku.Cell.init(5, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(5, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(5, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 3), iter.next().?);
    try std.testing.expectEqual(null, iter.next());
}

test "Region iterator" {
    const rect1: sudoku.Rect = .init(.{
        .width = 4,
        .height = 2,
    });
    const rect2: sudoku.Rect = .init(.{
        .width = 2,
        .height = 4,
        .offset = .init(2, 2),
    });
    const region: sudoku.Region = .multi(&.{ rect1, rect2, .from_cell(.init(15, 15)), rect2 });

    var iter = region.iterator(.forward);
    try std.testing.expectEqual(sudoku.Cell.init(1, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(1, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(15, 15), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 5), iter.next().?);
    try std.testing.expectEqual(null, iter.next());

    iter = region.iterator(.reverse);
    try std.testing.expectEqual(sudoku.Cell.init(3, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 5), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 4), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 3), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(15, 15), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(1, 2), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(4, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(3, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(2, 1), iter.next().?);
    try std.testing.expectEqual(sudoku.Cell.init(1, 1), iter.next().?);
    
    try std.testing.expectEqual(null, iter.next());
}

test "Unique_Region constraint" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    var b: sudoku.Constraint.Builder = .init(std.testing.allocator, arena.allocator());
    defer b.deinit();

    try b.add(.{ .values = .init_range(1, 5, .single(.{ .width = 5, .height = 1 })) });
    try b.add(.{ .unique_region = .row(1, 5) });

    var config = try b.build();
    config.init_cell(.init(1, 1), 3);
    var state = config.initial_state;

    try std.testing.expectEqual(.unsolved, config.constraints[0].evaluate(&config, &state));

    try std.testing.expectEqual(0b001000, state.cells[0].mask);
    try std.testing.expectEqual(0b111110, state.cells[1].mask);
    try std.testing.expectEqual(0b111110, state.cells[2].mask);
    try std.testing.expectEqual(0b111110, state.cells[3].mask);
    try std.testing.expectEqual(0b111110, state.cells[4].mask);

    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));

    try std.testing.expectEqual(0b001000, state.cells[0].mask);
    try std.testing.expectEqual(0b110110, state.cells[1].mask);
    try std.testing.expectEqual(0b110110, state.cells[2].mask);
    try std.testing.expectEqual(0b110110, state.cells[3].mask);
    try std.testing.expectEqual(0b110110, state.cells[4].mask);

    state.set(&config, .init(3, 1), 5);

    try std.testing.expectEqual(0b001000, state.cells[0].mask);
    try std.testing.expectEqual(0b110110, state.cells[1].mask);
    try std.testing.expectEqual(0b100000, state.cells[2].mask);
    try std.testing.expectEqual(0b110110, state.cells[3].mask);
    try std.testing.expectEqual(0b110110, state.cells[4].mask);

    try std.testing.expectEqual(.unsolved, config.constraints[0].evaluate(&config, &state));

    try std.testing.expectEqual(0b001000, state.cells[0].mask);
    try std.testing.expectEqual(0b110110, state.cells[1].mask);
    try std.testing.expectEqual(0b100000, state.cells[2].mask);
    try std.testing.expectEqual(0b110110, state.cells[3].mask);
    try std.testing.expectEqual(0b110110, state.cells[4].mask);

    try std.testing.expectEqual(.unsolved, config.constraints[1].evaluate(&config, &state));

    try std.testing.expectEqual(0b001000, state.cells[0].mask);
    try std.testing.expectEqual(0b010110, state.cells[1].mask);
    try std.testing.expectEqual(0b100000, state.cells[2].mask);
    try std.testing.expectEqual(0b010110, state.cells[3].mask);
    try std.testing.expectEqual(0b010110, state.cells[4].mask);
}

const sudoku = @import("sudoku");
const std = @import("std");
