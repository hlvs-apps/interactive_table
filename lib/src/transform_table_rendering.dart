//Copied and modified from flutter/lib/src/rendering/table.dart

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:interactive_viewer_2/interactive_dev.dart';


import 'package:flutter/rendering.dart';

typedef RenderTransformTableLayoutComplete = void Function(Size size)?;

/// A table where the columns and rows are sized to fit the contents of the cells.
class RenderTransformTable extends RenderBox {
  /// Creates a table render object.
  ///
  ///  * `columns` must either be null or non-negative. If `columns` is null,
  ///    the number of columns will be inferred from length of the first sublist
  ///    of `children`.
  ///  * `rows` must either be null or non-negative. If `rows` is null, the
  ///    number of rows will be inferred from the `children`. If `rows` is not
  ///    null, then `children` must be null.
  ///  * `children` must either be null or contain lists of all the same length.
  ///    if `children` is not null, then `rows` must be null.
  ///  * [columnWidths] may be null, in which case it defaults to an empty map.
  RenderTransformTable({
    int? columns,
    int? rows,
    Matrix4? transform,
    bool hideHeadline = false,
    bool hideRows = false,
    Map<int, TableColumnWidth>? columnWidths,
    TableColumnWidth defaultColumnWidth = const FlexColumnWidth(),
    required TextDirection textDirection,
    this.onLayoutComplete,
    ScrollbarControllerEncapsulation? scrollbarController,
    TableBorder? border,
    List<Decoration?>? rowDecorations,
    ImageConfiguration configuration = ImageConfiguration.empty,
    TableCellVerticalAlignment defaultVerticalAlignment =
        TableCellVerticalAlignment.top,
    TextBaseline? textBaseline,
    List<List<RenderBox>>? children,
  })  : assert(columns == null || columns >= 0),
        assert(rows == null || rows >= 0),
        assert(rows == null || children == null),
        _textDirection = textDirection,
        _columns = columns ??
            (children != null && children.isNotEmpty
                ? children.first.length
                : 0),
        _rows = rows ?? 0,
        _columnWidths = columnWidths ?? HashMap<int, TableColumnWidth>(),
        _defaultColumnWidth = defaultColumnWidth,
        _border = border,
        _textBaseline = textBaseline,
        _defaultVerticalAlignment = defaultVerticalAlignment,
        _transform = transform ?? Matrix4.identity(),
        _hideHeadline = hideHeadline,
        _hideRows = hideRows,
        _configuration = configuration {
    _children = <RenderBox?>[]..length = _columns * _rows;
    this.rowDecorations =
        rowDecorations; // must use setter to initialize box painters array
    this.scrollbarController =
        scrollbarController; // must use setter to initialize the listener
    children?.forEach(addRow);
  }

  // Children are stored in row-major order.
  // _children.length must be rows * columns
  List<RenderBox?> _children = const <RenderBox?>[];

  /// Add a scrollbar controller to this table.
  /// This is used to control the scrollbars of the table.
  ScrollbarControllerEncapsulation? get scrollbarController => _scrollbarController;

  ScrollbarControllerEncapsulation? _scrollbarController;

  set scrollbarController(ScrollbarControllerEncapsulation? value) {
    if (_scrollbarController == value) {
      return;
    }
    _scrollbarController?.removeListener(_onScrollbarControllerScrollChanged);
    _scrollbarController = value;
    _scrollbarController?.addListener(_onScrollbarControllerScrollChanged);
  }

  void _onScrollbarControllerScrollChanged() {
    markNeedsPaint(onlyPaintingTransform: true);
  }

  /// The number of vertical alignment lines in this table.
  ///
  /// Changing the number of columns will remove any children that no longer fit
  /// in the table.
  ///
  /// Changing the number of columns is an expensive operation because the table
  /// needs to rearrange its internal representation.
  int get columns => _columns;
  int _columns;

  set columns(int value) {
    assert(value >= 0);
    if (value == columns) {
      return;
    }
    final int oldColumns = columns;
    final List<RenderBox?> oldChildren = _children;
    _columns = value;
    _children = List<RenderBox?>.filled(columns * rows, null);
    final int columnsToCopy = math.min(columns, oldColumns);
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columnsToCopy; x += 1) {
        _children[x + y * columns] = oldChildren[x + y * oldColumns];
      }
    }
    if (oldColumns > columns) {
      for (int y = 0; y < rows; y += 1) {
        for (int x = columns; x < oldColumns; x += 1) {
          final int xy = x + y * oldColumns;
          if (oldChildren[xy] != null) {
            dropChild(oldChildren[xy]!);
          }
        }
      }
    }
    markNeedsLayout();
  }

  /// The transform of the table.
  Matrix4 get transform => _transform;
  Matrix4 _transform;

  set transform(Matrix4 value) {
    if (transform == value) {
      return;
    }
    _transform = value;
    markNeedsPaint(onlyPaintingTransform: true);
  }

  /// Called every time after performLayout(), with the calculated size of the table, without transforms and clips applied.
  /// Commonly used for Widgets manipulating this tables transform, e.g. for scrolling.
  RenderTransformTableLayoutComplete onLayoutComplete;

  /// Hide all rows except the headline, used to stack two tables on top of each other, so that the material widget can be put in between, so that ink splashes from the rows are not drawn over the headline.
  bool get hideRows => _hideRows;
  bool _hideRows = false;

  set hideRows(bool value) {
    if (hideRows == value) {
      return;
    }
    _hideRows = value;
    markNeedsPaint(onlyPaintingTransform: true);
  }

  /// The number of horizontal alignment lines in this table.
  ///
  /// Changing the number of rows will remove any children that no longer fit
  /// in the table.
  int get rows => _rows;
  int _rows;

  set rows(int value) {
    assert(value >= 0);
    if (value == rows) {
      return;
    }
    if (_rows > value) {
      for (int xy = columns * value; xy < _children.length; xy += 1) {
        if (_children[xy] != null) {
          dropChild(_children[xy]!);
        }
      }
    }
    _rows = value;
    _children.length = columns * rows;
    markNeedsLayout();
  }

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// This property can never return null. If it is set to null, and the existing
  /// map is not empty, then the value is replaced by an empty map. (If it is set
  /// to null while the current value is an empty map, the value is not changed.)
  Map<int, TableColumnWidth>? get columnWidths =>
      Map<int, TableColumnWidth>.unmodifiable(_columnWidths);
  Map<int, TableColumnWidth> _columnWidths;

  set columnWidths(Map<int, TableColumnWidth>? value) {
    if (_columnWidths == value) {
      return;
    }
    if (_columnWidths.isEmpty && value == null) {
      return;
    }
    _columnWidths = value ?? HashMap<int, TableColumnWidth>();
    markNeedsLayout();
  }

  /// Determines how the width of column with the given index is determined.
  void setColumnWidth(int column, TableColumnWidth value) {
    if (_columnWidths[column] == value) {
      return;
    }
    _columnWidths[column] = value;
    markNeedsLayout();
  }

  /// How to determine with widths of columns that don't have an explicit sizing algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null.
  TableColumnWidth get defaultColumnWidth => _defaultColumnWidth;
  TableColumnWidth _defaultColumnWidth;

  set defaultColumnWidth(TableColumnWidth value) {
    if (defaultColumnWidth == value) {
      return;
    }
    _defaultColumnWidth = value;
    markNeedsLayout();
  }

  /// The direction in which the columns are ordered.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  /// The style to use when painting the boundary and interior divisions of the table.
  TableBorder? get border => _border;
  TableBorder? _border;

  set border(TableBorder? value) {
    if (border == value) {
      return;
    }
    _border = value;
    markNeedsPaint();
  }

  /// The decorations to use for each row of the table.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  List<Decoration> get rowDecorations =>
      List<Decoration>.unmodifiable(_rowDecorations ?? const <Decoration>[]);

  // _rowDecorations and _rowDecorationPainters need to be in sync. They have to
  // either both be null or have same length.
  List<Decoration?>? _rowDecorations;
  List<BoxPainter?>? _rowDecorationPainters;

  set rowDecorations(List<Decoration?>? value) {
    if (_rowDecorations == value) {
      return;
    }
    _rowDecorations = value;
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) {
        painter?.dispose();
      }
    }
    _rowDecorationPainters = _rowDecorations != null
        ? List<BoxPainter?>.filled(_rowDecorations!.length, null)
        : null;
  }

  /// The settings to pass to the [rowDecorations] when painting, so that they
  /// can resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;

  set configuration(ImageConfiguration value) {
    if (value == _configuration) {
      return;
    }
    _configuration = value;
    markNeedsPaint();
  }

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  TableCellVerticalAlignment get defaultVerticalAlignment =>
      _defaultVerticalAlignment;
  TableCellVerticalAlignment _defaultVerticalAlignment;

  set defaultVerticalAlignment(TableCellVerticalAlignment value) {
    if (_defaultVerticalAlignment == value) {
      return;
    }
    _defaultVerticalAlignment = value;
    markNeedsLayout();
  }

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;

  set textBaseline(TextBaseline? value) {
    if (_textBaseline == value) {
      return;
    }
    _textBaseline = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableCellParentData) {
      child.parentData = TableCellParentData();
    }
  }

  /// Whether to hide the headline, used to stack two tables on top of each other, so that the material widget can be put in between, so that ink splashes from the rows are not drawn over the headline.
  bool get hideHeadline => _hideHeadline;
  bool _hideHeadline = false;

  set hideHeadline(bool value) {
    if (_hideHeadline == value) {
      return;
    }
    _hideHeadline = value;
    markNeedsPaint(onlyPaintingTransform: true);
  }

  RenderBox? _rowOverlay;

  set rowOverlay(RenderBox? value) {
    if (_rowOverlay == value) {
      return;
    }
    if (_rowOverlay != null) {
      dropChild(_rowOverlay!);
    }
    _rowOverlay = value;
    if (value != null) {
      adoptChild(value);
    }
    markNeedsLayout();
  }

  /// Replaces the children of this table with the given cells.
  ///
  /// The cells are divided into the specified number of columns before
  /// replacing the existing children.
  ///
  /// If the new cells contain any existing children of the table, those
  /// children are moved to their new location in the table rather than
  /// removed from the table and re-added.
  void setFlatChildren(int columns, List<RenderBox?> cells) {
    if (cells == _children && columns == _columns) {
      return;
    }
    assert(columns >= 0);
    // consider the case of a newly empty table
    if (columns == 0 || cells.isEmpty) {
      assert(cells.isEmpty);
      _columns = columns;
      if (_children.isEmpty) {
        assert(_rows == 0);
        return;
      }
      for (final RenderBox? oldChild in _children) {
        if (oldChild != null) {
          dropChild(oldChild);
        }
      }
      _rows = 0;
      _children.clear();
      markNeedsLayout();
      return;
    }
    assert(cells.length % columns == 0);
    // fill a set with the cells that are moving (it's important not
    // to dropChild a child that's remaining with us, because that
    // would clear their parentData field)
    final Set<RenderBox> lostChildren = HashSet<RenderBox>();
    for (int y = 0; y < _rows; y += 1) {
      for (int x = 0; x < _columns; x += 1) {
        final int xyOld = x + y * _columns;
        final int xyNew = x + y * columns;
        if (_children[xyOld] != null &&
            (x >= columns ||
                xyNew >= cells.length ||
                _children[xyOld] != cells[xyNew])) {
          lostChildren.add(_children[xyOld]!);
        }
      }
    }
    // adopt cells that are arriving, and cross cells that are just moving off our list of lostChildren
    int y = 0;
    while (y * columns < cells.length) {
      for (int x = 0; x < columns; x += 1) {
        final int xyNew = x + y * columns;
        final int xyOld = x + y * _columns;
        if (cells[xyNew] != null &&
            (x >= _columns || y >= _rows || _children[xyOld] != cells[xyNew])) {
          if (!lostChildren.remove(cells[xyNew])) {
            adoptChild(cells[xyNew]!);
          }
        }
      }
      y += 1;
    }
    // drop all the lost children
    lostChildren.forEach(dropChild);
    // update our internal values
    _columns = columns;
    _rows = cells.length ~/ columns;
    _children = List<RenderBox?>.of(cells);
    assert(_children.length == rows * columns);
    markNeedsLayout();
  }

  /// Replaces the children of this table with the given cells.
  void setChildren(List<List<RenderBox>>? cells) {
    // TODO(ianh): Make this smarter, like setFlatChildren
    if (cells == null) {
      setFlatChildren(0, const <RenderBox?>[]);
      return;
    }
    for (final RenderBox? oldChild in _children) {
      if (oldChild != null) {
        dropChild(oldChild);
      }
    }
    _children.clear();
    _columns = cells.isNotEmpty ? cells.first.length : 0;
    _rows = 0;
    cells.forEach(addRow);
    assert(_children.length == rows * columns);
  }

  /// Adds a row to the end of the table.
  ///
  /// The newly added children must not already have parents.
  void addRow(List<RenderBox?> cells) {
    assert(cells.length == columns);
    assert(_children.length == rows * columns);
    _rows += 1;
    _children.addAll(cells);
    for (final RenderBox? cell in cells) {
      if (cell != null) {
        adoptChild(cell);
      }
    }
    markNeedsLayout();
  }

  /// Replaces the child at the given position with the given child.
  ///
  /// If the given child is already located at the given position, this function
  /// does not modify the table. Otherwise, the given child must not already
  /// have a parent.
  void setChild(int x, int y, RenderBox? value) {
    assert(x >= 0 && x < columns && y >= 0 && y < rows);
    assert(_children.length == rows * columns);
    final int xy = x + y * columns;
    final RenderBox? oldChild = _children[xy];
    if (oldChild == value) {
      return;
    }
    if (oldChild != null) {
      dropChild(oldChild);
    }
    _children[xy] = value;
    if (value != null) {
      adoptChild(value);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox? child in _children) {
      child?.attach(owner);
    }
    _rowOverlay?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) {
        painter?.dispose();
      }
      _rowDecorationPainters =
          List<BoxPainter?>.filled(_rowDecorations!.length, null);
    }
    for (final RenderBox? child in _children) {
      child?.detach();
    }
    _rowOverlay?.detach();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    assert(_children.length == rows * columns);
    for (final RenderBox? child in _children) {
      if (child != null) {
        visitor(child);
      }
    }
    if (_rowOverlay != null) {
      visitor(_rowOverlay!);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMinWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMinWidth +=
          columnWidth.minIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMinWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMaxWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMaxWidth +=
          columnWidth.maxIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMaxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // winner of the 2016 world's most expensive intrinsic dimension function award
    // honorable mention, most likely to improve if taught about memoization award
    assert(_children.length == rows * columns);
    final List<double> widths =
        _computeColumnWidths(BoxConstraints.tightForFinite(width: width));
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      double rowHeight = 0.0;
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          rowHeight =
              math.max(rowHeight, child.getMaxIntrinsicHeight(widths[x]));
        }
      }
      rowTop += rowHeight;
    }
    return rowTop;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  double? _baselineDistance;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // returns the baseline of the first cell that has a baseline in the first row
    assert(!debugNeedsLayout);
    return _baselineDistance;
  }

  /// Returns the list of [RenderBox] objects that are in the given
  /// column, in row order, starting from the first row.
  ///
  /// This is a lazily-evaluated iterable.
  // The following uses sync* because it is public API documented to return a
  // lazy iterable.
  Iterable<RenderBox> column(int x) sync* {
    for (int y = 0; y < rows; y += 1) {
      final int xy = x + y * columns;
      final RenderBox? child = _children[xy];
      if (child != null) {
        yield child;
      }
    }
  }

  /// Returns the list of [RenderBox] objects that are on the given
  /// row, in column order, starting with the first column.
  ///
  /// This is a lazily-evaluated iterable.
  // The following uses sync* because it is public API documented to return a
  // lazy iterable.
  Iterable<RenderBox> row(int y) sync* {
    final int start = y * columns;
    final int end = (y + 1) * columns;
    for (int xy = start; xy < end; xy += 1) {
      final RenderBox? child = _children[xy];
      if (child != null) {
        yield child;
      }
    }
  }

  List<double> _computeColumnWidths(BoxConstraints constraints) {
    assert(_children.length == rows * columns);
    // We apply the constraints to the column widths in the order of
    // least important to most important:
    // 1. apply the ideal widths (maxIntrinsicWidth)
    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go

    // 1. apply ideal widths, and collect information we'll need later
    final List<double> widths = List<double>.filled(columns, 0.0);
    final List<double> minWidths = List<double>.filled(columns, 0.0);
    final List<double?> flexes = List<double?>.filled(columns, null);
    double tableWidth = 0.0; // running tally of the sum of widths[x] for all x
    double unflexedTableWidth =
        0.0; // sum of the maxIntrinsicWidths of any column that has null flex
    double totalFlex = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      // apply ideal width (maxIntrinsicWidth)
      final double maxIntrinsicWidth =
          columnWidth.maxIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(maxIntrinsicWidth.isFinite);
      assert(maxIntrinsicWidth >= 0.0);
      widths[x] = maxIntrinsicWidth;
      tableWidth += maxIntrinsicWidth;
      // collect min width information while we're at it
      final double minIntrinsicWidth =
          columnWidth.minIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(minIntrinsicWidth.isFinite);
      assert(minIntrinsicWidth >= 0.0);
      minWidths[x] = minIntrinsicWidth;
      assert(maxIntrinsicWidth >= minIntrinsicWidth);
      // collect flex information while we're at it
      final double? flex = columnWidth.flex(columnCells);
      if (flex != null) {
        assert(flex.isFinite);
        assert(flex > 0.0);
        flexes[x] = flex;
        totalFlex += flex;
      } else {
        unflexedTableWidth = unflexedTableWidth + maxIntrinsicWidth;
      }
    }
    final double maxWidthConstraint = constraints.maxWidth;
    final double minWidthConstraint = constraints.minWidth;

    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    if (totalFlex > 0.0) {
      // this can only grow the table, but it _will_ grow the table at
      // least as big as the target width.
      final double targetWidth;
      if (maxWidthConstraint.isFinite) {
        targetWidth = maxWidthConstraint;
      } else {
        targetWidth = minWidthConstraint;
      }
      if (tableWidth < targetWidth) {
        final double remainingWidth = targetWidth - unflexedTableWidth;
        assert(remainingWidth.isFinite);
        assert(remainingWidth >= 0.0);
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double flexedWidth = remainingWidth * flexes[x]! / totalFlex;
            assert(flexedWidth.isFinite);
            assert(flexedWidth >= 0.0);
            if (widths[x] < flexedWidth) {
              final double delta = flexedWidth - widths[x];
              tableWidth += delta;
              widths[x] = flexedWidth;
            }
          }
        }
        assert(tableWidth + precisionErrorTolerance >= targetWidth);
      }
    } // step 2 and 3 are mutually exclusive

    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    else if (tableWidth < minWidthConstraint) {
      final double delta = (minWidthConstraint - tableWidth) / columns;
      for (int x = 0; x < columns; x += 1) {
        widths[x] = widths[x] + delta;
      }
      tableWidth = minWidthConstraint;
    }

    // beyond this point, unflexedTableWidth is no longer valid

    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go
    if (tableWidth > maxWidthConstraint) {
      double deficit = tableWidth - maxWidthConstraint;
      // Some columns may have low flex but have all the free space.
      // (Consider a case with a 1px wide column of flex 1000.0 and
      // a 1000px wide column of flex 1.0; the sizes coming from the
      // maxIntrinsicWidths. If the maximum table width is 2px, then
      // just applying the flexes to the deficit would result in a
      // table with one column at -998px and one column at 990px,
      // which is wildly unhelpful.)
      // Similarly, some columns may be flexible, but not actually
      // be shrinkable due to a large minimum width. (Consider a
      // case with two columns, one is flex and one isn't, both have
      // 1000px maxIntrinsicWidths, but the flex one has 1000px
      // minIntrinsicWidth also. The whole deficit will have to come
      // from the non-flex column.)
      // So what we do is we repeatedly iterate through the flexible
      // columns shrinking them proportionally until we have no
      // available columns, then do the same to the non-flexible ones.
      int availableColumns = columns;
      while (deficit > precisionErrorTolerance &&
          totalFlex > precisionErrorTolerance) {
        double newTotalFlex = 0.0;
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double newWidth =
                widths[x] - deficit * flexes[x]! / totalFlex;
            assert(newWidth.isFinite);
            if (newWidth <= minWidths[x]) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
              flexes[x] = null;
              availableColumns -= 1;
            } else {
              deficit -= widths[x] - newWidth;
              widths[x] = newWidth;
              newTotalFlex += flexes[x]!;
            }
            assert(widths[x] >= 0.0);
          }
        }
        totalFlex = newTotalFlex;
      }
      while (deficit > precisionErrorTolerance && availableColumns > 0) {
        // Now we have to take out the remaining space from the
        // columns that aren't minimum sized.
        // To make this fair, we repeatedly remove equal amounts from
        // each column, clamped to the minimum width, until we run out
        // of columns that aren't at their minWidth.
        final double delta = deficit / availableColumns;
        assert(delta != 0);
        int newAvailableColumns = 0;
        for (int x = 0; x < columns; x += 1) {
          final double availableDelta = widths[x] - minWidths[x];
          if (availableDelta > 0.0) {
            if (availableDelta <= delta) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
            } else {
              deficit -= delta;
              widths[x] = widths[x] - delta;
              newAvailableColumns += 1;
            }
          }
        }
        availableColumns = newAvailableColumns;
      }
    }
    return widths;
  }

  // cache the table geometry for painting purposes
  final List<double> _rowTops = <double>[];
  Iterable<double>? _columnLefts;
  late double _tableWidth;

  Rect getRowBox(int row) {
    assert(row >= 0);
    assert(row < rows);
    assert(!debugNeedsLayout);

    return Rect.fromLTWH(
        0.0, 0.0, _tableWidth, _rowTops[row + 1] - _rowTops[row]);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    final Offset offset = childParentData.offset;
    if (row(0).contains(child)) {
      transform.multiply(_transformHeader);
    } else {
      transform.multiply(_transform);
    }
    transform.translate(offset.dx, offset.dy);
  }

  void applyPaintTransformForFirstChildInRow(int y, Matrix4 transform) {
    RenderBox? child = _children[y * columns];
    if (child == null) {
      return;
    }
    applyPaintTransform(child, transform);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final int rows = this.rows;
    final int columns = this.columns;
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      // TODO(ianh): if columns is zero, this should be zero width
      // TODO(ianh): if columns is not zero, this should be based on the column width specifications
      _tableWidth = 0.0;
      size = constraints.constrain(Size.zero);
      return;
    }
    final List<double> widths = _computeColumnWidths(constraints);
    final List<double> positions = List<double>.filled(columns, 0.0);
    switch (textDirection) {
      case TextDirection.rtl:
        positions[columns - 1] = 0.0;
        for (int x = columns - 2; x >= 0; x -= 1) {
          positions[x] = positions[x + 1] + widths[x + 1];
        }
        _columnLefts = positions.reversed;
        _tableWidth = positions.first + widths.first;
      case TextDirection.ltr:
        positions[0] = 0.0;
        for (int x = 1; x < columns; x += 1) {
          positions[x] = positions[x - 1] + widths[x - 1];
        }
        _columnLefts = positions;
        _tableWidth = positions.last + widths.last;
    }
    _rowTops.clear();
    _baselineDistance = null;
    // then, lay out each row
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      _rowTops.add(rowTop);
      double rowHeight = 0.0;
      bool haveBaseline = false;
      double beforeBaselineDistance = 0.0;
      double afterBaselineDistance = 0.0;
      final List<double> baselines = List<double>.filled(columns, 0.0);
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData =
              child.parentData! as TableCellParentData;
          childParentData.x = x;
          childParentData.y = y;
          switch (
              childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(textBaseline != null,
                  'An explicit textBaseline is required when using baseline alignment.');
              child.layout(BoxConstraints.tightFor(width: widths[x]),
                  parentUsesSize: true);
              final double? childBaseline =
                  child.getDistanceToBaseline(textBaseline!, onlyReal: true);
              if (childBaseline != null) {
                beforeBaselineDistance =
                    math.max(beforeBaselineDistance, childBaseline);
                afterBaselineDistance = math.max(
                    afterBaselineDistance, child.size.height - childBaseline);
                baselines[x] = childBaseline;
                haveBaseline = true;
              } else {
                rowHeight = math.max(rowHeight, child.size.height);
                childParentData.offset = Offset(positions[x], rowTop);
              }
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
            case TableCellVerticalAlignment.intrinsicHeight:
              child.layout(BoxConstraints.tightFor(width: widths[x]),
                  parentUsesSize: true);
              rowHeight = math.max(rowHeight, child.size.height);
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }
      if (haveBaseline) {
        if (y == 0) {
          _baselineDistance = beforeBaselineDistance;
        }
        rowHeight =
            math.max(rowHeight, beforeBaselineDistance + afterBaselineDistance);
      }
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData =
              child.parentData! as TableCellParentData;
          switch (
              childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              childParentData.offset = Offset(
                  positions[x], rowTop + beforeBaselineDistance - baselines[x]);
            case TableCellVerticalAlignment.top:
              childParentData.offset = Offset(positions[x], rowTop);
            case TableCellVerticalAlignment.middle:
              childParentData.offset = Offset(
                  positions[x], rowTop + (rowHeight - child.size.height) / 2.0);
            case TableCellVerticalAlignment.bottom:
              childParentData.offset =
                  Offset(positions[x], rowTop + rowHeight - child.size.height);
            case TableCellVerticalAlignment.fill:
            case TableCellVerticalAlignment.intrinsicHeight:
              child.layout(
                  BoxConstraints.tightFor(width: widths[x], height: rowHeight));
              childParentData.offset = Offset(positions[x], rowTop);
          }
        }
      }
      rowTop += rowHeight;
    }
    final RenderBox? additionalChild = _rowOverlay;
    if (additionalChild != null) {
      additionalChild.layout(constraints);
      final TableCellParentData childParentData =
          additionalChild.parentData! as TableCellParentData;
      childParentData.x = 0;
      childParentData.y = 0;
      childParentData.offset = const Offset(0, 0);
    }
    _rowTops.add(rowTop);
    //size = constraints.constrain(Size(_tableWidth, rowTop));
    if (onLayoutComplete != null) {
      onLayoutComplete!(Size(_tableWidth, rowTop));
    }
    size = constraints.biggest;
    assert(_rowTops.length == rows + 1);
  }

  Matrix4 get _transformHeader {
    Matrix4 transformHeader = transform.clone();
    transformHeader
        .setTranslation((transformHeader.getTranslation()..y = 0)..z = 0);
    return transformHeader;
  }

  //Dafür und für das clip rect habe ich 5 Stunden gebraucht
  Rect get _bodyArea => Rect.fromLTRB(
      0, _rowTops[1] * transform.getScaleOnZAxis(), size.width, size.height);

  Rect get _clipRectComplete => Rect.fromLTRB(0, 0, size.width, size.height);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    assert(_children.length == rows * columns);
    //Check first if outside bounds
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return false;
    }

    if (scrollbarController?.horizontalScrollbar.hitTest(position) ?? false) {
      return true;
    }

    if (scrollbarController?.verticalScrollbar.hitTest(position) ?? false) {
      return true;
    }

    //Then check for heading line
    if (!hideHeadline) {
      for (int index = columns - 1; index >= 0; index -= 1) {
        final RenderBox? child = _children[index];
        if (child != null) {
          final BoxParentData childParentData =
              child.parentData! as BoxParentData;
          final bool isHit = result.addWithPaintTransform(
            transform: _transformHeader,
            position: position,
            hitTest: (BoxHitTestResult result, Offset transformed) {
              return result.addWithPaintOffset(
                offset: childParentData.offset,
                position: transformed,
                hitTest: (BoxHitTestResult result, Offset transformed) {
                  return child.hitTest(result, position: transformed);
                },
              );
            },
          );
          if (isHit) {
            return true;
          }
        }
      }
    }

    if (_rowOverlay != null) {
      if (_rowOverlay?.hitTest(result, position: position) ?? false) {
        return true;
      }
    }

    if (!hideRows) {
      for (int index = _children.length - 1; index >= 0; index -= 1) {
        final RenderBox? child = _children[index];
        if (child != null) {
          final BoxParentData childParentData =
              child.parentData! as BoxParentData;
          final bool isHit = result.addWithPaintTransform(
            transform: transform,
            position: position,
            hitTest: (BoxHitTestResult result, Offset transformed) {
              return result.addWithPaintOffset(
                offset: childParentData.offset,
                position: transformed,
                hitTest: (BoxHitTestResult result, Offset transformed) {
                  return child.hitTest(result, position: transformed);
                },
              );
            },
          );
          if (isHit) {
            return true;
          }
        }
      }
    }
    return false;
  }

  final LayerHandle<TransformLayer> _containerRowsDecorationLayer =
      LayerHandle();
  final LayerHandle<TransformLayer> _containerRowsLayer = LayerHandle();

  final LayerHandle<TransformLayer> _containerHeaderDecorationLayer =
      LayerHandle();
  final LayerHandle<TransformLayer> _containerHeaderLayer = LayerHandle();

  final LayerHandle<TransformLayer> _containerBorderLayer = LayerHandle();

  @override
  void dispose() {
    _containerRowsDecorationLayer.layer = null;
    _containerRowsLayer.layer = null;
    _containerHeaderDecorationLayer.layer = null;
    _containerHeaderLayer.layer = null;
    _containerBorderLayer.layer = null;
    _scrollbarController?.removeListener(_onScrollbarControllerScrollChanged);
    super.dispose();
  }

  bool _repaintOnlyTransform = false;
  bool _doCompleteRepaint = false;

  bool get _doNeedCompleteRepaint {
    bool value = !(!_doCompleteRepaint && _repaintOnlyTransform);
    _repaintOnlyTransform = false;
    _doCompleteRepaint = false;
    return value;
  }

  static Matrix4 _getTransformPlusOffset(Matrix4 transform, Offset offset) {
    Matrix4 transformPlusOffset = transform.clone();
    transformPlusOffset.translate(offset.dx, offset.dy);
    return transformPlusOffset;
  }

  @override
  void markNeedsPaint({bool onlyPaintingTransform = false}) {
    if (_painting) {
      return;
    }
    if (onlyPaintingTransform) {
      _repaintOnlyTransform = true;
    } else {
      _doCompleteRepaint = true;
    }
    super.markNeedsPaint();
  }

  //We use composited layers for caching, so this is true
  @override
  bool get alwaysNeedsCompositing => true;

  bool _painting = false;

  @override
  void paint(PaintingContext context, Offset offset) {
    _painting = true;
    try {
      doPaint(context, offset);
    } finally {
      _painting = false;
    }
  }

  void doPaint(PaintingContext context, Offset offset) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      if (border != null) {
        final Rect borderRect =
            Rect.fromLTWH(offset.dx, offset.dy, _tableWidth, 0.0);
        border!.paint(context.canvas, borderRect,
            rows: const <double>[], columns: const <double>[]);
      }
      return;
    }
    assert(_rowTops.length == rows + 1);

    //Dramatically improved zoom/scroll performance by caching the layers
    bool completeRepaint = _doNeedCompleteRepaint;

    final Rect bodyArea = _bodyArea;
    final Matrix4 transformHeader = _transformHeader;
    Matrix4 transform = this.transform;

    context.pushClipRect(true, offset, _clipRectComplete,
        clipBehavior: Clip.hardEdge, (context, offset) {
      if (!hideRows) {
        if (_rowDecorations != null) {
          assert(_rowDecorations!.length == _rowDecorationPainters!.length);
          context.pushClipRect(true, offset, bodyArea,
              clipBehavior: Clip.hardEdge, (context, offset) {
            final Matrix4 rowDecorationTransform =
                _getTransformPlusOffset(transform, offset);
            if (completeRepaint ||
                _containerRowsDecorationLayer.layer == null ||
                _containerRowsDecorationLayer.layer is! TransformLayer) {
              _containerRowsDecorationLayer.layer = context.pushTransform(
                  true, offset, rowDecorationTransform,
                  oldLayer: _containerRowsDecorationLayer.layer,
                  (context, offset) {
                final Canvas canvas = context.canvas;
                for (int y = 1; y < rows; y += 1) {
                  if (_rowDecorations!.length <= y) {
                    break;
                  }
                  if (_rowDecorations![y] != null) {
                    _rowDecorationPainters![y] ??=
                        _rowDecorations![y]!.createBoxPainter(markNeedsPaint);
                    _rowDecorationPainters![y]!.paint(
                      canvas,
                      Offset(0, _rowTops[y]),
                      configuration.copyWith(
                          size:
                              Size(_tableWidth, _rowTops[y + 1] - _rowTops[y])),
                    );
                  }
                }
              });
            } else {
              _containerRowsDecorationLayer.layer!.offset = offset;
              _containerRowsDecorationLayer.layer!.transform =
                  rowDecorationTransform;
              context.addLayer(_containerRowsDecorationLayer.layer!);
            }
          });
        }
        context.pushClipRect(true, offset, bodyArea,
            clipBehavior: Clip.hardEdge, (context, offset) {
          final Matrix4 rowsTransform =
              _getTransformPlusOffset(transform, offset);
          if (completeRepaint ||
              _containerRowsLayer.layer == null ||
              _containerRowsLayer.layer is! TransformLayer) {
            _containerRowsLayer.layer = context.pushTransform(
                true, offset, rowsTransform,
                oldLayer: _containerRowsLayer.layer, (context, offset) {
              for (int index = columns; index < _children.length; index += 1) {
                final RenderBox? child = _children[index];
                if (child != null) {
                  final BoxParentData childParentData =
                      child.parentData! as BoxParentData;
                  context.paintChild(child, childParentData.offset);
                }
              }
            });
          } else {
            _containerRowsLayer.layer!.offset = offset;
            _containerRowsLayer.layer!.transform = rowsTransform;
            context.addLayer(_containerRowsLayer.layer!);
          }
        });
      }

      if (_rowOverlay != null) {
        context.pushClipRect(true, offset, bodyArea,
            clipBehavior: Clip.hardEdge, (context, offset) {
          context.paintChild(_rowOverlay!, offset);
        });
      }

      if (!hideHeadline) {
        if (_rowDecorations != null) {
          final Matrix4 headerDecorationTransform =
              _getTransformPlusOffset(transformHeader, offset);
          if (completeRepaint ||
              _containerHeaderDecorationLayer.layer == null ||
              _containerHeaderDecorationLayer.layer is! TransformLayer) {
            _containerHeaderDecorationLayer.layer = context.pushTransform(
                true, offset, headerDecorationTransform,
                oldLayer: _containerHeaderDecorationLayer.layer,
                (context, offset) {
              final Canvas canvas = context.canvas;
              if (_rowDecorations!.isNotEmpty) {
                if (_rowDecorations![0] != null) {
                  _rowDecorationPainters![0] ??=
                      _rowDecorations![0]!.createBoxPainter(markNeedsPaint);
                  _rowDecorationPainters![0]!.paint(
                    canvas,
                    Offset(0, _rowTops[0]),
                    configuration.copyWith(
                        size: Size(_tableWidth, _rowTops[1] - _rowTops[0])),
                  );
                }
              }
            });
          } else {
            _containerHeaderDecorationLayer.layer!.offset = offset;
            _containerHeaderDecorationLayer.layer!.transform =
                headerDecorationTransform;
            context.addLayer(_containerHeaderDecorationLayer.layer!);
          }
        }

        final Matrix4 headerTransform =
            _getTransformPlusOffset(transformHeader, offset);
        if (completeRepaint ||
            _containerHeaderLayer.layer == null ||
            _containerHeaderLayer.layer is! TransformLayer) {
          _containerHeaderLayer.layer = context.pushTransform(
              true, offset, headerTransform,
              oldLayer: _containerHeaderLayer.layer, (context, offset) {
            for (int index = 0; index < columns; index += 1) {
              final RenderBox? child = _children[index];
              if (child != null) {
                final BoxParentData childParentData =
                    child.parentData! as BoxParentData;
                context.paintChild(child, childParentData.offset);
              }
            }
          });
        } else {
          _containerHeaderLayer.layer!.offset = offset;
          _containerHeaderLayer.layer!.transform = headerTransform;
          context.addLayer(_containerHeaderLayer.layer!);
        }
      }

      assert(_rows == _rowTops.length - 1);
      assert(_columns == _columnLefts!.length);
      if (border != null) {
        //TODO(hlvs) wont work if not 2 transform_tables are stacked on top of each other for separate headline and body drawing like in [TransformedDataTable]
        // The border rect might not fill the entire height of this render object
        // if the rows underflow. We always force the columns to fill the width of
        // the render object, which means the columns cannot underflow.
        Matrix4 borderTransform = transform;
        bool alternateBorder = hideRows && !hideHeadline;
        if (alternateBorder) {
          borderTransform = transformHeader;
        }
        if (completeRepaint ||
            _containerBorderLayer.layer == null ||
            _containerBorderLayer.layer is! TransformLayer) {
          _containerBorderLayer.layer = context.pushTransform(
              true, offset, borderTransform,
              oldLayer: _containerBorderLayer.layer, (context, offset) {
            final Rect borderRect = Rect.fromLTWH(offset.dx, offset.dy,
                _tableWidth, (alternateBorder ? _rowTops[1] : _rowTops.last));
            final Iterable<double> rows = _rowTops.getRange(
                1, alternateBorder ? 1 : (_rowTops.length - 1));
            final Iterable<double> columns = _columnLefts!.skip(1);
            border!.paint(context.canvas, borderRect,
                rows: rows, columns: columns);
          });
        } else {
          _containerBorderLayer.layer!.offset = offset;
          _containerBorderLayer.layer!.transform = borderTransform;
          context.addLayer(_containerBorderLayer.layer!);
        }
      } else {
        _containerBorderLayer.layer = null;
      }
    });
    _scrollbarController?.updateAndPaint(
        context, transform, size, Size(_tableWidth, _rowTops.last));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<TableBorder>('border', border, defaultValue: null));
    properties.add(DiagnosticsProperty<Map<int, TableColumnWidth>>(
        'specified column widths', _columnWidths,
        level: _columnWidths.isEmpty
            ? DiagnosticLevel.hidden
            : DiagnosticLevel.info));
    properties.add(DiagnosticsProperty<TableColumnWidth>(
        'default column width', defaultColumnWidth));
    properties.add(MessageProperty('table size', '$columns\u00D7$rows'));
    properties.add(IterableProperty<String>(
        'column offsets', _columnLefts?.map(debugFormatDouble),
        ifNull: 'unknown'));
    properties.add(IterableProperty<String>(
        'row offsets', _rowTops.map(debugFormatDouble),
        ifNull: 'unknown'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (_children.isEmpty) {
      return <DiagnosticsNode>[DiagnosticsNode.message('table is empty')];
    }

    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        final String name = 'child ($x, $y)';
        if (child != null) {
          children.add(child.toDiagnosticsNode(name: name));
        } else {
          children.add(DiagnosticsProperty<Object>(name, null,
              ifNull: 'is null', showSeparator: false));
        }
      }
    }
    return children;
  }
}
