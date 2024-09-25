import 'transformed_table_builder.dart';
import 'transform_table_rendering.dart';
import 'transform_table.dart';

import 'package:interactive_viewer_2/interactive_dev.dart';

import 'package:flutter/material.dart';

/// A Wrapper for TransformTable with a state, which can be used to manipulate the transform of the table, without rebuilding the whole table.
/// The transform can be manipulated if you have a reference to the state, e.g. by using a GlobalKey.
/// Any other modification needs an rebuild, and with an rebuild the transform is reset to initialTransform.
/// This is useful for scrolling, as the table can be scrolled without rebuilding the whole table.
class TransformTableStateful extends TransformStatefulWidget {
  /// Creates a table.
  const TransformTableStateful({
    super.key,
    required super.initialTransform,
    this.children = const <TableRow>[],
    this.rowOverlay,
    this.hideHeadline = false,
    this.hideRows = false,
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.onLayoutComplete,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.scrollbarController,
    this.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
  });

  /// The rows of the table.
  ///
  /// Every row in a table must have the same number of children.
  final List<TableRow> children;

  final Widget? rowOverlay;

  final bool hideHeadline;

  final bool hideRows;

  /// Configures how to paint the scrollbars.If null, no scrollbars will be painted.
  final ScrollbarControllerEncapsulation? scrollbarController;

  /// Called every time after performLayout(), with the calculated size of the table, without transforms and clips applied.
  /// Commonly used for Widgets manipulating this tables transform, e.g. for scrolling.
  @protected
  final RenderTransformTableLayoutComplete onLayoutComplete;

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead. By default, that uses flex sizing to
  /// distribute free space equally among the columns.
  ///
  /// The [FixedColumnWidth] class can be used to specify a specific width in
  /// pixels. That is the cheapest way to size a table's columns.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// The keys of this map (column indexes) are zero-based.
  ///
  /// If this is set to null, then an empty map is assumed.
  final Map<int, TableColumnWidth>? columnWidths;

  /// How to determine with widths of columns that don't have an explicit sizing
  /// algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null. Defaults to [FlexColumnWidth], which will
  /// divide the remaining horizontal space up evenly between columns of the
  /// same type [TableColumnWidth].
  ///
  /// A [TransformTable] in a horizontal [ScrollView] must use a [FixedColumnWidth], or
  /// an [IntrinsicColumnWidth] as the horizontal space is infinite.
  final TableColumnWidth defaultColumnWidth;

  /// The direction in which the columns are ordered.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// The style to use when painting the boundary and interior divisions of the table.
  final TableBorder? border;

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  ///
  /// Cells may specify a vertical alignment by wrapping their contents in a
  /// [TableCell] widget.
  final TableCellVerticalAlignment defaultVerticalAlignment;

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  ///
  /// This must be set if using baseline alignment. There is no default because there is no
  /// way for the framework to know the correct baseline _a priori_.
  final TextBaseline? textBaseline;

  @override
  TransformTableStatefulState createState() => TransformTableStatefulState();
}

/// The state of a [TransformTableStateful].
/// Can be used to manipulate the transform of the table, without rebuilding the whole table.
class TransformTableStatefulState
    extends TransformStatefulWidgetState<TransformTableStateful> {
  LocalKey childKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return TransformTable(
      key: childKey,
      transform: transform,
      children: widget.children,
      rowOverlay: widget.rowOverlay,
      hideHeadline: widget.hideHeadline,
      hideRows: widget.hideRows,
      columnWidths: widget.columnWidths,
      defaultColumnWidth: widget.defaultColumnWidth,
      textDirection: widget.textDirection,
      border: widget.border,
      onLayoutComplete: widget.onLayoutComplete,
      defaultVerticalAlignment: widget.defaultVerticalAlignment,
      textBaseline: widget.textBaseline,
      scrollbarController: widget.scrollbarController,
    );
  }
}
