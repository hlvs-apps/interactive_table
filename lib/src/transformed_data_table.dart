library interactive_table;

//Copied and modified from flutter/lib/src/material/data_table.dart

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'transform_table.dart';
import 'transform_table_rendering.dart';
import 'transform_table_stateful.dart';
import 'transformed_table_builder.dart';

import 'package:interactive_viewer_2/interactive_dev.dart';

/// Configure the table in [SpreadsheetDataTable].
class TransformedDataTableBuilder
    extends TransformedTableBuilder<TransformedDataTable> {
  TransformedDataTableBuilder({
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.decoration,
    this.dataRowColor,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.showCheckboxColumn = true,
    this.showBottomBorder = false,
    this.disableDivider = false,
    this.dividerThickness,
    required this.rows,
    this.checkboxHorizontalMargin,
    this.border,
  });

  /// The configuration and labels for the columns in the table.
  final List<DataColumn> columns;

  /// The current primary sort key's column.
  ///
  /// If non-null, indicates that the indicated column is the column
  /// by which the data is sorted. The number must correspond to the
  /// index of the relevant column in [columns].
  ///
  /// Setting this will cause the relevant column to have a sort
  /// indicator displayed.
  ///
  /// When this is null, it implies that the table's sort order does
  /// not correspond to any of the columns.
  ///
  /// The direction of the sort is specified using [sortAscending].
  final int? sortColumnIndex;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order.
  ///
  /// If true, the order is ascending (meaning the rows with the
  /// smallest values for the current sort column are first in the
  /// table).
  ///
  /// If false, the order is descending (meaning the rows with the
  /// smallest values for the current sort column are last in the
  /// table).
  ///
  /// Ascending order is represented by an upwards-facing arrow.
  final bool sortAscending;

  /// Invoked when the user selects or unselects every row, using the
  /// checkbox in the heading row.
  ///
  /// If this is null, then the [DataRow.onSelectChanged] callback of
  /// every row in the table is invoked appropriately instead.
  ///
  /// To control whether a particular row is selectable or not, see
  /// [DataRow.onSelectChanged]. This callback is only relevant if any
  /// row is selectable.
  final ValueSetter<bool?>? onSelectAll;

  /// {@template flutter.material.dataTable.decoration}
  /// The background and border decoration for the table.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.decoration] is used. By default there is no
  /// decoration.
  final Decoration? decoration;

  /// {@template flutter.material.dataTable.dataRowColor}
  /// The background color for the data rows.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is selected, pressed, hovered,
  /// focused, disabled or enabled. The color is painted as an overlay to the
  /// row. To make sure that the row's [InkWell] is visible (when pressed,
  /// hovered and focused), it is recommended to use a translucent background
  /// color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowColor] is used. By default, the
  /// background color is transparent unless selected. Selected rows have a grey
  /// translucent color. To set a different color for individual rows, see
  /// [DataRow.color].
  ///
  /// {@template flutter.material.DataTable.dataRowColor}
  /// ```dart
  /// DataTable(
  ///   dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected)) {
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     }
  ///     return null;  // Use the default value.
  ///   }),
  ///   columns: _columns,
  ///   rows: _rows,
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? dataRowColor;

  /// {@template flutter.material.dataTable.dataRowMinHeight}
  /// The minimum height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowMinHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  final double? dataRowMinHeight;

  /// {@template flutter.material.dataTable.dataRowMaxHeight}
  /// The maximum height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowMaxHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  final double? dataRowMaxHeight;

  /// {@template flutter.material.dataTable.dataTextStyle}
  /// The text style for data rows.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataTextStyle] is used. By default, the text
  /// style is [TextTheme.bodyMedium].
  final TextStyle? dataTextStyle;

  /// {@template flutter.material.dataTable.headingRowColor}
  /// The background color for the heading row.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is pressed, hovered, focused when
  /// sorted. The color is painted as an overlay to the row. To make sure that
  /// the row's [InkWell] is visible (when pressed, hovered and focused), it is
  /// recommended to use a translucent color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowColor] is used.
  ///
  /// {@template flutter.material.DataTable.headingRowColor}
  /// ```dart
  /// DataTable(
  ///   columns: _columns,
  ///   rows: _rows,
  ///   headingRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.hovered)) {
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     }
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? headingRowColor;

  /// {@template flutter.material.dataTable.headingRowHeight}
  /// The height of the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowHeight] is used. This value
  /// defaults to 56.0 to adhere to the Material Design specifications.
  final double? headingRowHeight;

  /// {@template flutter.material.dataTable.headingTextStyle}
  /// The text style for the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingTextStyle] is used. By default, the
  /// text style is [TextTheme.titleSmall].
  final TextStyle? headingTextStyle;

  /// {@template flutter.material.dataTable.horizontalMargin}
  /// The horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  ///
  /// When a checkbox is displayed, it is also the margin between the checkbox
  /// the content in the first data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.horizontalMargin] is used. This value
  /// defaults to 24.0 to adhere to the Material Design specifications.
  ///
  /// If [checkboxHorizontalMargin] is null, then [horizontalMargin] is also the
  /// margin between the edge of the table and the checkbox, as well as the
  /// margin between the checkbox and the content in the first data column.
  final double? horizontalMargin;

  /// {@template flutter.material.dataTable.columnSpacing}
  /// The horizontal margin between the contents of each data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.columnSpacing] is used. This value defaults
  /// to 56.0 to adhere to the Material Design specifications.
  final double? columnSpacing;

  /// {@template flutter.material.dataTable.showCheckboxColumn}
  /// Whether the widget should display checkboxes for selectable rows.
  ///
  /// If true, a [Checkbox] will be placed at the beginning of each row that is
  /// selectable. However, if [DataRow.onSelectChanged] is not set for any row,
  /// checkboxes will not be placed, even if this value is true.
  ///
  /// If false, all rows will not display a [Checkbox].
  /// {@endtemplate}
  final bool showCheckboxColumn;

  /// The data to show in each row (excluding the row that contains
  /// the column headings).
  ///
  /// The list may be empty.
  final List<DataRow> rows;

  /// {@template flutter.material.dataTable.dividerThickness}
  /// The width of the divider that appears between [TableRow]s.
  ///
  /// Must be greater than or equal to zero.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dividerThickness] is used. This value
  /// defaults to 1.0.
  ///
  /// If set to 0.0, a hairline border will be shown.
  /// To disable the divider, set [disableDivider] to true.
  final double? dividerThickness;

  /// If set,disables the divider between two rows.
  ///
  /// See also: [dividerThickness]
  final bool disableDivider;

  /// Whether a border at the bottom of the table is displayed.
  ///
  /// By default, a border is not shown at the bottom to allow for a border
  /// around the table defined by [decoration].
  final bool showBottomBorder;

  /// {@template flutter.material.dataTable.checkboxHorizontalMargin}
  /// Horizontal margin around the checkbox, if it is displayed.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.checkboxHorizontalMargin] is used. If that is
  /// also null, then [horizontalMargin] is used as the margin between the edge
  /// of the table and the checkbox, as well as the margin between the checkbox
  /// and the content in the first data column. This value defaults to 24.0.
  final double? checkboxHorizontalMargin;

  /// The style to use when painting the boundary and interior divisions of the table.
  final TableBorder? border;

  /// Apply the configuration to a [TransformedDataTable].
  @override
  TransformedDataTable buildTable(
      {Key? key,
      required Matrix4 transform,
      RenderTransformTableLayoutComplete? onLayoutComplete,
        ScrollbarControllerEncapsulation? scrollbarController}) {
    return TransformedDataTable(
      key: key,
      initialTransform: transform,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSelectAll: onSelectAll,
      decoration: decoration,
      dataRowColor: dataRowColor,
      dataRowMinHeight: dataRowMinHeight,
      dataRowMaxHeight: dataRowMaxHeight,
      dataTextStyle: dataTextStyle,
      headingRowColor: headingRowColor,
      headingRowHeight: headingRowHeight,
      headingTextStyle: headingTextStyle,
      horizontalMargin: horizontalMargin,
      columnSpacing: columnSpacing,
      showCheckboxColumn: showCheckboxColumn,
      showBottomBorder: showBottomBorder,
      dividerThickness: dividerThickness,
      disableDivider: disableDivider,
      onLayoutComplete: onLayoutComplete,
      rows: rows,
      checkboxHorizontalMargin: checkboxHorizontalMargin,
      border: border,
      columns: columns,
      scrollbarController: scrollbarController,
    );
  }
}

/// A Material Design data table.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ktTajqbhIcY}
///
/// Displaying data in a table is expensive, because to lay out the
/// table all the data must be measured twice, once to negotiate the
/// dimensions to use for each column, and once to actually lay out
/// the table given the results of the negotiation.
///
/// For this reason, if you have a lot of data (say, more than a dozen
/// rows with a dozen columns, though the precise limits depend on the
/// target device), it is suggested that you use a
/// [PaginatedDataTable] which automatically splits the data into
/// multiple pages.
///
/// ## Performance considerations when wrapping [TransformedDataTable] with [SingleChildScrollView]
///
/// Wrapping a [TransformedDataTable] with [SingleChildScrollView] is expensive as [SingleChildScrollView]
/// mounts and paints the entire [TransformedDataTable] even when only some rows are visible. If scrolling in
/// one direction is necessary, then consider using a [CustomScrollView], otherwise use [PaginatedDataTable]
/// to split the data into smaller pages.
///
/// {@tool dartpad}
/// This sample shows how to display a [TransformedDataTable] with three columns: name, age, and
/// role. The columns are defined by three [DataColumn] objects. The table
/// contains three rows of data for three example users, the data for which
/// is defined by three [DataRow] objects.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/data_table.png)
///
/// ** See code in examples/api/lib/material/data_table/data_table.0.dart **
/// {@end-tool}
///
///
/// {@tool dartpad}
/// This sample shows how to display a [TransformedDataTable] with alternate colors per
/// row, and a custom color for when the row is selected.
///
/// ** See code in examples/api/lib/material/data_table/data_table.1.dart **
/// {@end-tool}
///
/// [TransformedDataTable] can be sorted on the basis of any column in [columns] in
/// ascending or descending order. If [sortColumnIndex] is non-null, then the
/// table will be sorted by the values in the specified column. The boolean
/// [sortAscending] flag controls the sort order.
///
/// See also:
///
///  * [DataColumn], which describes a column in the data table.
///  * [DataRow], which contains the data for a row in the data table.
///  * [DataCell], which contains the data for a single cell in the data table.
///  * [PaginatedDataTable], which shows part of the data in a data table and
///    provides controls for paging through the remainder of the data.
///  * <https://material.io/design/components/data-tables.html>
class TransformedDataTable extends TransformStatefulWidget {
  /// Creates a widget describing a data table.
  ///
  /// The [columns] argument must be a list of as many [DataColumn]
  /// objects as the table is to have columns, ignoring the leading
  /// checkbox column if any. The [columns] argument must have a
  /// length greater than zero.
  ///
  /// The [rows] argument must be a list of as many [DataRow] objects
  /// as the table is to have rows, ignoring the leading heading row
  /// that contains the column headings (derived from the [columns]
  /// argument). There may be zero rows, but the rows argument must
  /// not be null.
  ///
  /// Each [DataRow] object in [rows] must have as many [DataCell]
  /// objects in the [DataRow.cells] list as the table has columns.
  ///
  /// If the table is sorted, the column that provides the current
  /// primary key should be specified by index in [sortColumnIndex], 0
  /// meaning the first column in [columns], 1 being the next one, and
  /// so forth.
  ///
  /// The actual sort order can be specified using [sortAscending]; if
  /// the sort order is ascending, this should be true (the default),
  /// otherwise it should be false.
  TransformedDataTable({
    super.key,
    required this.columns,
    required super.initialTransform,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.decoration,
    this.dataRowColor,
    @Deprecated(
      'Migrate to use dataRowMinHeight and dataRowMaxHeight instead. '
      'This feature was deprecated after v3.7.0-5.0.pre.',
    )
    double? dataRowHeight,
    double? dataRowMinHeight,
    double? dataRowMaxHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.showCheckboxColumn = true,
    this.showBottomBorder = false,
    this.dividerThickness,
    this.disableDivider = false,
    this.onLayoutComplete,
    required this.rows,
    this.checkboxHorizontalMargin,
    this.border,
    this.scrollbarController,
  })  : assert(columns.isNotEmpty),
        assert(sortColumnIndex == null ||
            (sortColumnIndex >= 0 && sortColumnIndex < columns.length)),
        assert(!rows.any((DataRow row) => row.cells.length != columns.length),
            'All rows must have the same number of cells as there are header cells (${columns.length})'),
        assert(dividerThickness == null || dividerThickness >= 0),
        assert(dataRowMinHeight == null ||
            dataRowMaxHeight == null ||
            dataRowMaxHeight >= dataRowMinHeight),
        assert(
            dataRowHeight == null ||
                (dataRowMinHeight == null && dataRowMaxHeight == null),
            'dataRowHeight ($dataRowHeight) must not be set if dataRowMinHeight ($dataRowMinHeight) or dataRowMaxHeight ($dataRowMaxHeight) are set.'),
        dataRowMinHeight = dataRowHeight ?? dataRowMinHeight,
        dataRowMaxHeight = dataRowHeight ?? dataRowMaxHeight,
        _onlyTextColumn = _initOnlyTextColumn(columns);

  /// The configuration and labels for the columns in the table.
  final List<DataColumn> columns;

  /// The current primary sort key's column.
  ///
  /// If non-null, indicates that the indicated column is the column
  /// by which the data is sorted. The number must correspond to the
  /// index of the relevant column in [columns].
  ///
  /// Setting this will cause the relevant column to have a sort
  /// indicator displayed.
  ///
  /// When this is null, it implies that the table's sort order does
  /// not correspond to any of the columns.
  ///
  /// The direction of the sort is specified using [sortAscending].
  final int? sortColumnIndex;

  /// Called every time after performLayout(), with the calculated size of the table, without transforms and clips applied.
  /// Commonly used for Widgets manipulating this tables transform, e.g. for scrolling.
  @protected
  final RenderTransformTableLayoutComplete onLayoutComplete;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order.
  ///
  /// If true, the order is ascending (meaning the rows with the
  /// smallest values for the current sort column are first in the
  /// table).
  ///
  /// If false, the order is descending (meaning the rows with the
  /// smallest values for the current sort column are last in the
  /// table).
  ///
  /// Ascending order is represented by an upwards-facing arrow.
  final bool sortAscending;

  /// Invoked when the user selects or unselects every row, using the
  /// checkbox in the heading row.
  ///
  /// If this is null, then the [DataRow.onSelectChanged] callback of
  /// every row in the table is invoked appropriately instead.
  ///
  /// To control whether a particular row is selectable or not, see
  /// [DataRow.onSelectChanged]. This callback is only relevant if any
  /// row is selectable.
  final ValueSetter<bool?>? onSelectAll;

  /// {@template flutter.material.dataTable.decoration}
  /// The background and border decoration for the table.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.decoration] is used. By default there is no
  /// decoration.
  final Decoration? decoration;

  /// {@template flutter.material.dataTable.dataRowColor}
  /// The background color for the data rows.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is selected, pressed, hovered,
  /// focused, disabled or enabled. The color is painted as an overlay to the
  /// row. To make sure that the row's [InkWell] is visible (when pressed,
  /// hovered and focused), it is recommended to use a translucent background
  /// color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowColor] is used. By default, the
  /// background color is transparent unless selected. Selected rows have a grey
  /// translucent color. To set a different color for individual rows, see
  /// [DataRow.color].
  ///
  /// {@template flutter.material.DataTable.dataRowColor}
  /// ```dart
  /// DataTable(
  ///   dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected)) {
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     }
  ///     return null;  // Use the default value.
  ///   }),
  ///   columns: _columns,
  ///   rows: _rows,
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? dataRowColor;

  /// {@template flutter.material.dataTable.dataRowMinHeight}
  /// The minimum height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowMinHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  final double? dataRowMinHeight;

  /// {@template flutter.material.dataTable.dataRowMaxHeight}
  /// The maximum height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowMaxHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  final double? dataRowMaxHeight;

  /// {@template flutter.material.dataTable.dataTextStyle}
  /// The text style for data rows.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataTextStyle] is used. By default, the text
  /// style is [TextTheme.bodyMedium].
  final TextStyle? dataTextStyle;

  /// {@template flutter.material.dataTable.headingRowColor}
  /// The background color for the heading row.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is pressed, hovered, focused when
  /// sorted. The color is painted as an overlay to the row. To make sure that
  /// the row's [InkWell] is visible (when pressed, hovered and focused), it is
  /// recommended to use a translucent color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowColor] is used.
  ///
  /// {@template flutter.material.DataTable.headingRowColor}
  /// ```dart
  /// DataTable(
  ///   columns: _columns,
  ///   rows: _rows,
  ///   headingRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.hovered)) {
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     }
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? headingRowColor;

  /// {@template flutter.material.dataTable.headingRowHeight}
  /// The height of the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowHeight] is used. This value
  /// defaults to 56.0 to adhere to the Material Design specifications.
  final double? headingRowHeight;

  /// {@template flutter.material.dataTable.headingTextStyle}
  /// The text style for the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingTextStyle] is used. By default, the
  /// text style is [TextTheme.titleSmall].
  final TextStyle? headingTextStyle;

  /// {@template flutter.material.dataTable.horizontalMargin}
  /// The horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  ///
  /// When a checkbox is displayed, it is also the margin between the checkbox
  /// the content in the first data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.horizontalMargin] is used. This value
  /// defaults to 24.0 to adhere to the Material Design specifications.
  ///
  /// If [checkboxHorizontalMargin] is null, then [horizontalMargin] is also the
  /// margin between the edge of the table and the checkbox, as well as the
  /// margin between the checkbox and the content in the first data column.
  final double? horizontalMargin;

  /// {@template flutter.material.dataTable.columnSpacing}
  /// The horizontal margin between the contents of each data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.columnSpacing] is used. This value defaults
  /// to 56.0 to adhere to the Material Design specifications.
  final double? columnSpacing;

  /// {@template flutter.material.dataTable.showCheckboxColumn}
  /// Whether the widget should display checkboxes for selectable rows.
  ///
  /// If true, a [Checkbox] will be placed at the beginning of each row that is
  /// selectable. However, if [DataRow.onSelectChanged] is not set for any row,
  /// checkboxes will not be placed, even if this value is true.
  ///
  /// If false, all rows will not display a [Checkbox].
  /// {@endtemplate}
  final bool showCheckboxColumn;

  /// The data to show in each row (excluding the row that contains
  /// the column headings).
  ///
  /// The list may be empty.
  final List<DataRow> rows;

  /// {@template flutter.material.dataTable.dividerThickness}
  /// The width of the divider that appears between [TableRow]s.
  ///
  /// Must be greater than or equal to zero.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dividerThickness] is used. This value
  /// defaults to 1.0.
  ///
  /// If set to 0.0, a hairline border will be shown.
  /// To disable the divider, set [disableDivider] to true.
  final double? dividerThickness;

  /// If set,disables the divider between two rows.
  ///
  /// See also: [dividerThickness]
  final bool disableDivider;

  /// Whether a border at the bottom of the table is displayed.
  ///
  /// By default, a border is not shown at the bottom to allow for a border
  /// around the table defined by [decoration].
  final bool showBottomBorder;

  /// {@template flutter.material.dataTable.checkboxHorizontalMargin}
  /// Horizontal margin around the checkbox, if it is displayed.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.checkboxHorizontalMargin] is used. If that is
  /// also null, then [horizontalMargin] is used as the margin between the edge
  /// of the table and the checkbox, as well as the margin between the checkbox
  /// and the content in the first data column. This value defaults to 24.0.
  final double? checkboxHorizontalMargin;

  /// The style to use when painting the boundary and interior divisions of the table.
  final TableBorder? border;

  // Set by the constructor to the index of the only Column that is
  // non-numeric, if there is exactly one, otherwise null.
  final int? _onlyTextColumn;

  /// Configures how to paint the scrollbars.If null, no scrollbars will be painted.
  final ScrollbarControllerEncapsulation? scrollbarController;

  static int? _initOnlyTextColumn(List<DataColumn> columns) {
    int? result;
    for (int index = 0; index < columns.length; index += 1) {
      final DataColumn column = columns[index];
      if (!column.numeric) {
        if (result != null) {
          return null;
        }
        result = index;
      }
    }
    return result;
  }

  static final LocalKey _headingRowKey = UniqueKey();

  /// The default height of the heading row.
  static const double _headingRowHeight = 56.0;

  /// The default horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  static const double _horizontalMargin = 24.0;

  /// The default horizontal margin between the contents of each data column.
  static const double _columnSpacing = 56.0;

  /// The default padding between the heading content and sort arrow.
  static const double _sortArrowPadding = 2.0;

  /// The default divider thickness.
  static const double _dividerThickness = 1.0;

  static const Duration _sortArrowAnimationDuration =
      Duration(milliseconds: 150);

  @override
  TransformedDataTableState createState() => TransformedDataTableState();
}

class TransformedDataTableState
    extends TransformStatefulWidgetState<TransformedDataTable> {
  final GlobalKey<TransformStatefulWidgetState> _transformTableBodyKey =
      GlobalKey<TransformStatefulWidgetState>();
  final GlobalKey<TransformStatefulWidgetState> _transformTableHeaderKey =
      GlobalKey<TransformStatefulWidgetState>();

  @override
  void afterTransformChanged() {
    _transformTableBodyKey.currentState?.setTransform(transform);
    _transformTableHeaderKey.currentState?.setTransform(transform);
  }

  /// {@template flutter.material.dataTable.dataRowHeight}
  /// The height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  @Deprecated(
    'Migrate to use dataRowMinHeight and dataRowMaxHeight instead. '
    'This feature was deprecated after v3.7.0-5.0.pre.',
  )
  double? get dataRowHeight =>
      widget.dataRowMinHeight == widget.dataRowMaxHeight
          ? widget.dataRowMinHeight
          : null;

  void _handleSelectAll(bool? checked, bool someChecked) {
    // If some checkboxes are checked, all checkboxes are selected. Otherwise,
    // use the new checked value but default to false if it's null.
    final bool effectiveChecked = someChecked || (checked ?? false);
    if (widget.onSelectAll != null) {
      widget.onSelectAll!(effectiveChecked);
    } else {
      for (final DataRow row in widget.rows) {
        if (row.onSelectChanged != null && row.selected != effectiveChecked) {
          row.onSelectChanged!(effectiveChecked);
        }
      }
    }
  }

  Widget _buildCheckbox({
    required BuildContext context,
    required bool? checked,
    required VoidCallback? onRowTap,
    required ValueChanged<bool?>? onCheckboxChanged,
    required MaterialStateProperty<Color?>? overlayColor,
    required bool tristate,
    MouseCursor? rowMouseCursor,
  }) {
    final ThemeData themeData = Theme.of(context);
    final double effectiveHorizontalMargin = widget.horizontalMargin ??
        themeData.dataTableTheme.horizontalMargin ??
        TransformedDataTable._horizontalMargin;
    final double effectiveCheckboxHorizontalMarginStart =
        widget.checkboxHorizontalMargin ??
            themeData.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin;
    final double effectiveCheckboxHorizontalMarginEnd =
        widget.checkboxHorizontalMargin ??
            themeData.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin / 2.0;
    Widget contents = Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: effectiveCheckboxHorizontalMarginStart,
          end: effectiveCheckboxHorizontalMarginEnd,
        ),
        child: Center(
          child: Checkbox(
            value: checked,
            onChanged: onCheckboxChanged,
            tristate: tristate,
          ),
        ),
      ),
    );
    if (onRowTap != null) {
      contents = TableRowInkWell(
        onTap: onRowTap,
        overlayColor: overlayColor,
        mouseCursor: rowMouseCursor,
        child: contents,
      );
    }
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: contents,
    );
  }

  Widget _buildHeadingCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required String? tooltip,
    required bool numeric,
    required VoidCallback? onSort,
    required bool sorted,
    required bool ascending,
    required MaterialStateProperty<Color?>? overlayColor,
    required MouseCursor? mouseCursor,
  }) {
    final ThemeData themeData = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    label = Row(
      textDirection: numeric ? TextDirection.rtl : null,
      children: <Widget>[
        label,
        if (onSort != null) ...<Widget>[
          _SortArrow(
            visible: sorted,
            up: sorted ? ascending : null,
            duration: TransformedDataTable._sortArrowAnimationDuration,
          ),
          const SizedBox(width: TransformedDataTable._sortArrowPadding),
        ],
      ],
    );

    final TextStyle effectiveHeadingTextStyle = widget.headingTextStyle ??
        dataTableTheme.headingTextStyle ??
        themeData.dataTableTheme.headingTextStyle ??
        themeData.textTheme.titleSmall!;
    final double effectiveHeadingRowHeight = widget.headingRowHeight ??
        dataTableTheme.headingRowHeight ??
        themeData.dataTableTheme.headingRowHeight ??
        TransformedDataTable._headingRowHeight;
    label = Container(
      padding: padding,
      height: effectiveHeadingRowHeight,
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: AnimatedDefaultTextStyle(
        style:
            DefaultTextStyle.of(context).style.merge(effectiveHeadingTextStyle),
        softWrap: false,
        duration: TransformedDataTable._sortArrowAnimationDuration,
        child: label,
      ),
    );
    if (tooltip != null) {
      label = Tooltip(
        message: tooltip,
        child: label,
      );
    }

    // TODO(dkwingsmt): Only wrap Inkwell if onSort != null. Blocked by
    // https://github.com/flutter/flutter/issues/51152
    label = InkWell(
      onTap: onSort,
      overlayColor: overlayColor,
      mouseCursor: mouseCursor,
      child: label,
    );
    return label;
  }

  Widget _buildDataCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required bool numeric,
    required bool placeholder,
    required bool showEditIcon,
    required GestureTapCallback? onTap,
    required VoidCallback? onSelectChanged,
    required GestureTapCallback? onDoubleTap,
    required GestureLongPressCallback? onLongPress,
    required GestureTapDownCallback? onTapDown,
    required GestureTapCancelCallback? onTapCancel,
    required MaterialStateProperty<Color?>? overlayColor,
    required GestureLongPressCallback? onRowLongPress,
    required MouseCursor? mouseCursor,
  }) {
    final ThemeData themeData = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    if (showEditIcon) {
      const Widget icon = Icon(Icons.edit, size: 18.0);
      label = Expanded(child: label);
      label = Row(
        textDirection: numeric ? TextDirection.rtl : null,
        children: <Widget>[label, icon],
      );
    }

    final TextStyle effectiveDataTextStyle = widget.dataTextStyle ??
        dataTableTheme.dataTextStyle ??
        themeData.dataTableTheme.dataTextStyle ??
        themeData.textTheme.bodyMedium!;
    final double effectiveDataRowMinHeight = widget.dataRowMinHeight ??
        dataTableTheme.dataRowMinHeight ??
        themeData.dataTableTheme.dataRowMinHeight ??
        kMinInteractiveDimension;
    final double effectiveDataRowMaxHeight = widget.dataRowMaxHeight ??
        dataTableTheme.dataRowMaxHeight ??
        themeData.dataTableTheme.dataRowMaxHeight ??
        kMinInteractiveDimension;
    label = Container(
      padding: padding,
      constraints: BoxConstraints(
          minHeight: effectiveDataRowMinHeight,
          maxHeight: effectiveDataRowMaxHeight),
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context)
            .style
            .merge(effectiveDataTextStyle)
            .copyWith(
                color: placeholder
                    ? effectiveDataTextStyle.color!.withOpacity(0.6)
                    : null),
        child: DropdownButtonHideUnderline(child: label),
      ),
    );
    if (onTap != null ||
        onDoubleTap != null ||
        onLongPress != null ||
        onTapDown != null ||
        onTapCancel != null) {
      label = InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onTapCancel: onTapCancel,
        onTapDown: onTapDown,
        overlayColor: overlayColor,
        child: label,
      );
    } else if (onSelectChanged != null || onRowLongPress != null) {
      label = TableRowInkWell(
        onTap: onSelectChanged,
        onLongPress: onRowLongPress,
        overlayColor: overlayColor,
        mouseCursor: mouseCursor,
        child: label,
      );
    }
    return label;
  }

  TableRow _buildTableRow(
      int index,
      LocalKey headingRowKey,
      BoxBorder? border,
      Color? rowColor,
      MaterialStateProperty<Color?> defaultRowColor,
      Set<MaterialState> states,
      List<TableColumnWidth> tableColumns) {
    return TableRow(
      key: index == 0 ? headingRowKey : widget.rows[index - 1].key,
      decoration: BoxDecoration(
        border: border,
        color: rowColor ?? defaultRowColor.resolve(states),
      ),
      children: List<Widget>.filled(tableColumns.length, const _NullWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DataTableThemeData dataTableTheme = DataTableTheme.of(context);
    final MaterialStateProperty<Color?>? effectiveHeadingRowColor =
        widget.headingRowColor ??
            dataTableTheme.headingRowColor ??
            theme.dataTableTheme.headingRowColor;
    final MaterialStateProperty<Color?>? effectiveDataRowColor =
        widget.dataRowColor ??
            dataTableTheme.dataRowColor ??
            theme.dataTableTheme.dataRowColor;
    final MaterialStateProperty<Color?> defaultRowColor =
        MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return theme.colorScheme.primary.withOpacity(0.08);
        }
        return null;
      },
    );
    final bool anyRowSelectable =
        widget.rows.any((DataRow row) => row.onSelectChanged != null);
    final bool displayCheckboxColumn =
        widget.showCheckboxColumn && anyRowSelectable;
    final Iterable<DataRow> rowsWithCheckbox = displayCheckboxColumn
        ? widget.rows.where((DataRow row) => row.onSelectChanged != null)
        : <DataRow>[];
    final Iterable<DataRow> rowsChecked =
        rowsWithCheckbox.where((DataRow row) => row.selected);
    final bool allChecked =
        displayCheckboxColumn && rowsChecked.length == rowsWithCheckbox.length;
    final bool anyChecked = displayCheckboxColumn && rowsChecked.isNotEmpty;
    final bool someChecked = anyChecked && !allChecked;
    final double effectiveHorizontalMargin = widget.horizontalMargin ??
        dataTableTheme.horizontalMargin ??
        theme.dataTableTheme.horizontalMargin ??
        TransformedDataTable._horizontalMargin;
    final double effectiveCheckboxHorizontalMarginStart =
        widget.checkboxHorizontalMargin ??
            dataTableTheme.checkboxHorizontalMargin ??
            theme.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin;
    final double effectiveCheckboxHorizontalMarginEnd =
        widget.checkboxHorizontalMargin ??
            dataTableTheme.checkboxHorizontalMargin ??
            theme.dataTableTheme.checkboxHorizontalMargin ??
            effectiveHorizontalMargin / 2.0;
    final double effectiveColumnSpacing = widget.columnSpacing ??
        dataTableTheme.columnSpacing ??
        theme.dataTableTheme.columnSpacing ??
        TransformedDataTable._columnSpacing;

    final List<TableColumnWidth> tableColumns = List<TableColumnWidth>.filled(
        widget.columns.length + (displayCheckboxColumn ? 1 : 0),
        const _NullTableColumnWidth());
    //TableRow? additionalHeadingRow;
    final List<TableRow> tableRows = List<TableRow>.generate(
      widget.rows.length + 1, // the +1 is for the header row
      (int index) {
        final bool isSelected = index > 0 && widget.rows[index - 1].selected;
        final bool isDisabled = index > 0 &&
            anyRowSelectable &&
            widget.rows[index - 1].onSelectChanged == null;
        final Set<MaterialState> states = <MaterialState>{
          if (isSelected) MaterialState.selected,
          if (isDisabled) MaterialState.disabled,
        };
        final Color? resolvedDataRowColor = index > 0
            ? (widget.rows[index - 1].color ?? effectiveDataRowColor)
                ?.resolve(states)
            : null;
        final Color? resolvedHeadingRowColor =
            effectiveHeadingRowColor?.resolve(<MaterialState>{});
        final Color? rowColor =
            index > 0 ? resolvedDataRowColor : resolvedHeadingRowColor;
        final BorderSide borderSide = Divider.createBorderSide(
          context,
          width: widget.dividerThickness ??
              dataTableTheme.dividerThickness ??
              theme.dataTableTheme.dividerThickness ??
              TransformedDataTable._dividerThickness,
        );
        final Border? border = widget.showBottomBorder
            ? Border(bottom: borderSide)
            : index == 0
                ? null
                : widget.disableDivider
                    ? null
                    : Border(top: borderSide);
        /*additionalHeadingRow = _buildTableRow(index, _headingRowKey, border,
            rowColor, defaultRowColor, states, tableColumns);*/
        return _buildTableRow(index, TransformedDataTable._headingRowKey,
            border, rowColor, defaultRowColor, states, tableColumns);
      },
    );

    int rowIndex;

    int displayColumnIndex = 0;
    if (displayCheckboxColumn) {
      tableColumns[0] = FixedColumnWidth(
          effectiveCheckboxHorizontalMarginStart +
              Checkbox.width +
              effectiveCheckboxHorizontalMarginEnd);
      tableRows[0].children[0] = _buildCheckbox(
        context: context,
        checked: someChecked ? null : allChecked,
        onRowTap: null,
        onCheckboxChanged: (bool? checked) =>
            _handleSelectAll(checked, someChecked),
        overlayColor: null,
        tristate: true,
      );
      rowIndex = 1;
      for (final DataRow row in widget.rows) {
        final Set<MaterialState> states = <MaterialState>{
          if (row.selected) MaterialState.selected,
        };
        tableRows[rowIndex].children[0] = _buildCheckbox(
          context: context,
          checked: row.selected,
          onRowTap: row.onSelectChanged == null
              ? null
              : () => row.onSelectChanged?.call(!row.selected),
          onCheckboxChanged: row.onSelectChanged,
          overlayColor: row.color ?? effectiveDataRowColor,
          rowMouseCursor: row.mouseCursor?.resolve(states) ??
              dataTableTheme.dataRowCursor?.resolve(states),
          tristate: false,
        );
        rowIndex += 1;
      }
      displayColumnIndex += 1;
    }

    for (int dataColumnIndex = 0;
        dataColumnIndex < widget.columns.length;
        dataColumnIndex += 1) {
      final DataColumn column = widget.columns[dataColumnIndex];

      final double paddingStart;
      if (dataColumnIndex == 0 &&
          displayCheckboxColumn &&
          widget.checkboxHorizontalMargin != null) {
        paddingStart = effectiveHorizontalMargin;
      } else if (dataColumnIndex == 0 && displayCheckboxColumn) {
        paddingStart = effectiveHorizontalMargin / 2.0;
      } else if (dataColumnIndex == 0 && !displayCheckboxColumn) {
        paddingStart = effectiveHorizontalMargin;
      } else {
        paddingStart = effectiveColumnSpacing / 2.0;
      }

      final double paddingEnd;
      if (dataColumnIndex == widget.columns.length - 1) {
        paddingEnd = effectiveHorizontalMargin;
      } else {
        paddingEnd = effectiveColumnSpacing / 2.0;
      }

      final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
        start: paddingStart,
        end: paddingEnd,
      );
      if (dataColumnIndex == widget._onlyTextColumn) {
        tableColumns[displayColumnIndex] =
            const IntrinsicColumnWidth(flex: 1.0);
      } else {
        tableColumns[displayColumnIndex] = const IntrinsicColumnWidth();
      }
      final Set<MaterialState> headerStates = <MaterialState>{
        if (column.onSort == null) MaterialState.disabled,
      };
      tableRows[0].children[displayColumnIndex] = _buildHeadingCell(
        context: context,
        padding: padding,
        label: column.label,
        tooltip: column.tooltip,
        numeric: column.numeric,
        onSort: column.onSort != null
            ? () => column.onSort!(
                dataColumnIndex,
                widget.sortColumnIndex != dataColumnIndex ||
                    !widget.sortAscending)
            : null,
        sorted: dataColumnIndex == widget.sortColumnIndex,
        ascending: widget.sortAscending,
        overlayColor: effectiveHeadingRowColor,
        mouseCursor: column.mouseCursor?.resolve(headerStates) ??
            dataTableTheme.headingCellCursor?.resolve(headerStates),
      );
      rowIndex = 1;
      for (final DataRow row in widget.rows) {
        final Set<MaterialState> states = <MaterialState>{
          if (row.selected) MaterialState.selected,
        };
        final DataCell cell = row.cells[dataColumnIndex];
        tableRows[rowIndex].children[displayColumnIndex] = _buildDataCell(
          context: context,
          padding: padding,
          label: cell.child,
          numeric: column.numeric,
          placeholder: cell.placeholder,
          showEditIcon: cell.showEditIcon,
          onTap: cell.onTap,
          onDoubleTap: cell.onDoubleTap,
          onLongPress: cell.onLongPress,
          onTapCancel: cell.onTapCancel,
          onTapDown: cell.onTapDown,
          onSelectChanged: row.onSelectChanged == null
              ? null
              : () => row.onSelectChanged?.call(!row.selected),
          overlayColor: row.color ?? effectiveDataRowColor,
          onRowLongPress: row.onLongPress,
          mouseCursor: row.mouseCursor?.resolve(states) ??
              dataTableTheme.dataRowCursor?.resolve(states),
        );
        rowIndex += 1;
      }
      displayColumnIndex += 1;
    }

    return RepaintBoundary(
      child: Container(
        decoration: widget.decoration ??
            dataTableTheme.decoration ??
            theme.dataTableTheme.decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: widget.border?.borderRadius,
          child: RepaintBoundary(
            //huge performance increase
            child: TransformTableStateful(
              key: _transformTableHeaderKey,
              columnWidths: tableColumns.asMap(),
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: tableRows,
              hideRows: true,
              border: widget.border,
              initialTransform: transform,
              scrollbarController: widget.scrollbarController,
              rowOverlay: Material(
                type: MaterialType.transparency,
                child: RepaintBoundary(
                  //huge performance increase
                  child: TransformTableStateful(
                    key: _transformTableBodyKey,
                    columnWidths: tableColumns.asMap(),
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: tableRows,
                    hideHeadline: true,
                    border: widget.border,
                    initialTransform: transform,
                    onLayoutComplete: widget.onLayoutComplete,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rectangular area of a Material that responds to touch but clips
/// its ink splashes to the current table row of the nearest table.
///
/// Must have an ancestor [Material] widget in which to cause ink
/// reactions and an ancestor [Table] widget to establish a row.
///
/// The [TableRowInkWell] must be in the same coordinate space (modulo
/// translations) as the [Table]. If it's rotated or scaled or
/// otherwise transformed, it will not be able to describe the
/// rectangle of the row in its own coordinate system as a [Rect], and
/// thus the splash will not occur. (In general, this is easy to
/// achieve: just put the [TableRowInkWell] as the direct child of the
/// [Table], and put the other contents of the cell inside it.)
///
/// See also:
///
///  * [TransformedDataTable], which makes use of [TableRowInkWell] when
///    [DataRow.onSelectChanged] is defined and [DataCell.onTap]
///    is not.
class TableRowInkWell extends InkResponse {
  /// Creates an ink well for a table row.
  const TableRowInkWell({
    super.key,
    super.child,
    super.onTap,
    super.onDoubleTap,
    super.onLongPress,
    super.onHighlightChanged,
    super.onSecondaryTap,
    super.onSecondaryTapDown,
    super.overlayColor,
    super.mouseCursor,
  }) : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
        );

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    return () {
      RenderObject cell = referenceBox;
      RenderObject? table = cell.parent;
      final Matrix4 transform = Matrix4.identity();
      while (table is RenderObject && table is! RenderTransformTable) {
        table.applyPaintTransform(cell, transform);
        assert(table == cell.parent);
        cell = table;
        table = table.parent;
      }
      if (table is RenderTransformTable) {
        final TableCellParentData cellParentData =
            cell.parentData! as TableCellParentData;
        assert(cellParentData.y != null);
        final Rect rect = table.getRowBox(cellParentData.y!);
        table.applyPaintTransform(cell, transform);
        Matrix4 onlyTableTransform = Matrix4.identity();
        table.applyPaintTransformForFirstChildInRow(
            cellParentData.y!, onlyTableTransform);

        Offset offset = Offset(
            (transform.getTranslation().x -
                    onlyTableTransform.getTranslation().x) *
                (1 / transform.getScaleOnZAxis()),
            0);
        return rect.shift(-offset);
      }
      return Rect.zero;
    };
  }

  @override
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasTransformTable(context));
    return super.debugCheckContext(context);
  }
}

bool debugCheckHasTransformTable(BuildContext context) {
  assert(() {
    if (context.widget is! TransformTable &&
        context.findAncestorWidgetOfExactType<TransformTable>() == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No TransformTable widget found.'),
        ErrorDescription(
            '${context.widget.runtimeType} widgets require a TransformTable widget ancestor.'),
        context.describeWidget(
            'The specific widget that could not find a TransformTable ancestor was'),
        context.describeOwnershipChain(
            'The ownership chain for the affected widget is'),
      ]);
    }
    return true;
  }());
  return true;
}

class _SortArrow extends StatefulWidget {
  const _SortArrow({
    required this.visible,
    required this.up,
    required this.duration,
  });

  final bool visible;

  final bool? up;

  final Duration duration;

  @override
  _SortArrowState createState() => _SortArrowState();
}

class _SortArrowState extends State<_SortArrow> with TickerProviderStateMixin {
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  late AnimationController _orientationController;
  late Animation<double> _orientationAnimation;
  double _orientationOffset = 0.0;

  bool? _up;

  static final Animatable<double> _turnTween =
      Tween<double>(begin: 0.0, end: math.pi)
          .chain(CurveTween(curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _up = widget.up;
    _opacityAnimation = CurvedAnimation(
      parent: _opacityController = AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
      curve: Curves.fastOutSlowIn,
    )..addListener(_rebuild);
    _opacityController.value = widget.visible ? 1.0 : 0.0;
    _orientationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _orientationAnimation = _orientationController.drive(_turnTween)
      ..addListener(_rebuild)
      ..addStatusListener(_resetOrientationAnimation);
    if (widget.visible) {
      _orientationOffset = widget.up! ? 0.0 : math.pi;
    }
  }

  void _rebuild() {
    setState(() {
      // The animations changed, so we need to rebuild.
    });
  }

  void _resetOrientationAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      assert(_orientationAnimation.value == math.pi);
      _orientationOffset += math.pi;
      _orientationController.value =
          0.0; // TODO(ianh): This triggers a pointless rebuild.
    }
  }

  @override
  void didUpdateWidget(_SortArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool skipArrow = false;
    final bool? newUp = widget.up ?? _up;
    if (oldWidget.visible != widget.visible) {
      if (widget.visible &&
          (_opacityController.status == AnimationStatus.dismissed)) {
        _orientationController.stop();
        _orientationController.value = 0.0;
        _orientationOffset = newUp! ? 0.0 : math.pi;
        skipArrow = true;
      }
      if (widget.visible) {
        _opacityController.forward();
      } else {
        _opacityController.reverse();
      }
    }
    if ((_up != newUp) && !skipArrow) {
      if (_orientationController.status == AnimationStatus.dismissed) {
        _orientationController.forward();
      } else {
        _orientationController.reverse();
      }
    }
    _up = newUp;
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _orientationController.dispose();
    super.dispose();
  }

  static const double _arrowIconBaselineOffset = -1.5;
  static const double _arrowIconSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Transform(
        transform:
            Matrix4.rotationZ(_orientationOffset + _orientationAnimation.value)
              ..setTranslationRaw(0.0, _arrowIconBaselineOffset, 0.0),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_upward,
          size: _arrowIconSize,
        ),
      ),
    );
  }
}

class _NullTableColumnWidth extends TableColumnWidth {
  const _NullTableColumnWidth();

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
