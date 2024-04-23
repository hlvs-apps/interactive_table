library interactive_table;
//Copied and modified from flutter/lib/src/widgets/table.dart

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/widgets.dart';

import 'transform_table_rendering.dart';

import 'package:interactive_viewer_2/interactive_dev.dart';


class _TableElementRow {
  const _TableElementRow({this.key, required this.children});
  final LocalKey? key;
  final List<Element> children;
}

/// A widget that uses the table layout algorithm for its children.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=_lbE0wsVZSw}
///
/// {@tool dartpad}
/// This sample shows a [TransformTable] with borders, multiple types of column widths
/// and different vertical cell alignments.
///
/// ** See code in examples/api/lib/widgets/table/table.0.dart **
/// {@end-tool}
///
/// If you only have one row, the [Row] widget is more appropriate. If you only
/// have one column, the [SliverList] or [Column] widgets will be more
/// appropriate.
///
/// Rows size vertically based on their contents. To control the individual
/// column widths, use the [columnWidths] property to specify a
/// [TableColumnWidth] for each column. If [columnWidths] is null, or there is a
/// null entry for a given column in [columnWidths], the table uses the
/// [defaultColumnWidth] instead.
///
/// By default, [defaultColumnWidth] is a [FlexColumnWidth]. This
/// [TableColumnWidth] divides up the remaining space in the horizontal axis to
/// determine the column width. If wrapping a [TransformTable] in a horizontal
/// [ScrollView], choose a different [TableColumnWidth], such as
/// [FixedColumnWidth].
///
/// For more details about the table layout algorithm, see [RenderTransformTable].
/// To control the alignment of children, see [TableCell].
///
/// See also:
///
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class TransformTable extends RenderObjectWidget {
  /// Creates a table.
  TransformTable({
    super.key,
    required this.transform,
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
  })  : assert(
            defaultVerticalAlignment != TableCellVerticalAlignment.baseline ||
                textBaseline != null,
            'textBaseline is required if you specify the defaultVerticalAlignment with TableCellVerticalAlignment.baseline'),
        assert(() {
          if (children.any((TableRow row1) =>
              row1.key != null &&
              children.any(
                  (TableRow row2) => row1 != row2 && row1.key == row2.key))) {
            throw FlutterError(
              'Two or more TableRow children of this Table had the same key.\n'
              'All the keyed TableRow children of a Table must have different Keys.',
            );
          }
          return true;
        }()),
        assert(() {
          if (children.isNotEmpty) {
            final int cellCount = children.first.children.length;
            if (children
                .any((TableRow row) => row.children.length != cellCount)) {
              throw FlutterError(
                'Table contains irregular row lengths.\n'
                'Every TableRow in a Table must have the same number of children, so that every cell is filled. '
                'Otherwise, the table will contain holes.',
              );
            }
            if (children.any((TableRow row) => row.children.isEmpty)) {
              throw FlutterError(
                'One or more TableRow have no children.\n'
                'Every TableRow in a Table must have at least one child, so there is no empty row. ',
              );
            }
          }
          return true;
        }()),
        _rowDecorations = children.any((TableRow row) => row.decoration != null)
            ? children
                .map<Decoration?>((TableRow row) => row.decoration)
                .toList(growable: false)
            : null {
    assert(() {
      final List<Widget> flatChildren = children
          .expand<Widget>((TableRow row) => row.children)
          .toList(growable: false);
      return !debugChildrenHaveDuplicateKeys(
        this,
        flatChildren,
        message:
            'Two or more cells in this Table contain widgets with the same key.\n'
            'Every widget child of every TableRow in a Table must have different keys. The cells of a Table are '
            'flattened out for processing, so separate cells cannot have duplicate keys even if they are in '
            'different rows.',
      );
    }());
  }

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

  final List<Decoration?>? _rowDecorations;

  /// The transform to apply to apply to the body of the table.
  /// The resulting transform for the header is calculated automatically.
  final Matrix4 transform;

  @override
  RenderObjectElement createElement() => _TransformTableElement(this);

  @override
  RenderTransformTable createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return RenderTransformTable(
      columns: children.isNotEmpty ? children[0].children.length : 0,
      rows: children.length,
      columnWidths: columnWidths,
      defaultColumnWidth: defaultColumnWidth,
      textDirection: textDirection ?? Directionality.of(context),
      border: border,
      rowDecorations: _rowDecorations,
      configuration: createLocalImageConfiguration(context),
      defaultVerticalAlignment: defaultVerticalAlignment,
      textBaseline: textBaseline,
      transform: transform,
      hideHeadline: hideHeadline,
      onLayoutComplete: onLayoutComplete,
      hideRows: hideRows,
      scrollbarController: scrollbarController,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderTransformTable renderObject) {
    assert(debugCheckHasDirectionality(context));
    assert(renderObject.columns ==
        (children.isNotEmpty ? children[0].children.length : 0));
    assert(renderObject.rows == children.length);
    renderObject
      ..columnWidths = columnWidths
      ..defaultColumnWidth = defaultColumnWidth
      ..textDirection = textDirection ?? Directionality.of(context)
      ..border = border
      ..rowDecorations = _rowDecorations
      ..configuration = createLocalImageConfiguration(context)
      ..defaultVerticalAlignment = defaultVerticalAlignment
      ..textBaseline = textBaseline
      ..transform = transform
      ..hideHeadline = hideHeadline
      ..onLayoutComplete = onLayoutComplete
      ..hideRows = hideRows
      ..scrollbarController = scrollbarController;
  }
}

class _TransformTableElement extends RenderObjectElement {
  _TransformTableElement(TransformTable super.widget);

  @override
  RenderTransformTable get renderObject =>
      super.renderObject as RenderTransformTable;

  List<_TableElementRow> _children = const <_TableElementRow>[];

  bool _doingMountOrUpdate = false;

  Element? _additionalChild;

  @override
  TransformTable get widget => super.widget as TransformTable;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.mount(parent, newSlot);
    int rowIndex = -1;
    _children = widget.children.map<_TableElementRow>((TableRow row) {
      int columnIndex = 0;
      rowIndex += 1;
      return _TableElementRow(
        key: row.key,
        children: row.children.map<Element>((Widget child) {
          return inflateWidget(child, _TableSlot(columnIndex++, rowIndex));
        }).toList(growable: false),
      );
    }).toList(growable: false);
    if (widget.rowOverlay != null) {
      _additionalChild = inflateWidget(widget.rowOverlay!,
          _extraRow); //In dieser Zeile hab ich einen Fehler gemacht den ich 4 Stunden lang gesucht habe
    }
    _updateRenderObjectChildren();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void insertRenderObjectChild(RenderBox child, _TableSlot slot) {
    renderObject.setupParentData(child);
    // Once [mount]/[update] are done, the children are getting set all at once
    // in [_updateRenderObjectChildren].
    if (!_doingMountOrUpdate) {
      if (slot != _extraRow) {
        renderObject.setChild(slot.column, slot.row, child);
      } else {
        renderObject.rowOverlay = child;
      }
    }
  }

  @override
  void moveRenderObjectChild(
      RenderBox child, _TableSlot oldSlot, _TableSlot newSlot) {
    assert(_doingMountOrUpdate);
    // Child gets moved at the end of [update] in [_updateRenderObjectChildren].
  }

  @override
  void removeRenderObjectChild(RenderBox child, _TableSlot slot) {
    if (slot != _extraRow) {
      renderObject.setChild(slot.column, slot.row, null);
    } else {
      renderObject.rowOverlay = null;
    }
  }

  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void update(TransformTable newWidget) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    if (newWidget.children != widget.children) {
      //Diese if Bedingung ist neu, sie spart sehr viel layout Zeit, dadurch wird es viel flüssiger
      final Map<LocalKey, List<Element>> oldKeyedRows =
          <LocalKey, List<Element>>{};
      for (final _TableElementRow row in _children) {
        if (row.key != null) {
          oldKeyedRows[row.key!] = row.children;
        }
      }
      final Iterator<_TableElementRow> oldUnkeyedRows =
          _children.where((_TableElementRow row) => row.key == null).iterator;
      final List<_TableElementRow> newChildren = <_TableElementRow>[];
      final Set<List<Element>> taken = <List<Element>>{};
      for (int rowIndex = 0; rowIndex < newWidget.children.length; rowIndex++) {
        final TableRow row = newWidget.children[rowIndex];
        List<Element> oldChildren;
        if (row.key != null && oldKeyedRows.containsKey(row.key)) {
          oldChildren = oldKeyedRows[row.key]!;
          taken.add(oldChildren);
        } else if (row.key == null && oldUnkeyedRows.moveNext()) {
          oldChildren = oldUnkeyedRows.current.children;
        } else {
          oldChildren = const <Element>[];
        }
        final List<_TableSlot> slots = List<_TableSlot>.generate(
          row.children.length,
          (int columnIndex) => _TableSlot(columnIndex, rowIndex),
        );
        newChildren.add(_TableElementRow(
          key: row.key,
          children: updateChildren(oldChildren, row.children,
              forgottenChildren: _forgottenChildren, slots: slots),
        ));
      }
      while (oldUnkeyedRows.moveNext()) {
        updateChildren(oldUnkeyedRows.current.children, const <Widget>[],
            forgottenChildren: _forgottenChildren);
      }
      for (final List<Element> oldChildren in oldKeyedRows.values
          .where((List<Element> list) => !taken.contains(list))) {
        updateChildren(oldChildren, const <Widget>[],
            forgottenChildren: _forgottenChildren);
      }
      _children = newChildren;
      _updateRenderObjectChildren();
      _forgottenChildren.clear();
    }
    if (newWidget.rowOverlay != widget.rowOverlay) {
      _additionalChild =
          updateChild(_additionalChild, newWidget.rowOverlay, _extraRow);
    }

    super.update(newWidget);
    assert(widget == newWidget);
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  void _updateRenderObjectChildren() {
    renderObject.setFlatChildren(
      _children.isNotEmpty ? _children[0].children.length : 0,
      _children.expand<RenderBox>((_TableElementRow row) {
        return row.children.map<RenderBox>((Element child) {
          final RenderBox box = child.renderObject! as RenderBox;
          return box;
        });
      }).toList(),
    );
    renderObject.rowOverlay = _additionalChild?.renderObject as RenderBox?;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child
        in _children.expand<Element>((_TableElementRow row) => row.children)) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
    if (_additionalChild != null) {
      visitor(_additionalChild!);
    }
  }

  @override
  bool forgetChild(Element child) {
    if (_additionalChild != child) {
      _forgottenChildren.add(child);
    } else {
      _additionalChild = null;
    }
    super.forgetChild(child);
    return true;
  }
}

const _TableSlot _extraRow = _TableSlot(-1, -1);

@immutable
class _TableSlot with Diagnosticable {
  const _TableSlot(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _TableSlot && column == other.column && row == other.row;
  }

  @override
  int get hashCode => Object.hash(column, row);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('x', column));
    properties.add(IntProperty('y', row));
  }
}
