library interactive_table;

import 'package:interactive_table/src/better_interactive_viewer_base.dart';

import 'package:flutter/material.dart';

import 'transformed_data_table.dart';

/// A [InteractiveDataTable] is a widget that allows the user to pan and scale a MaterialDesign like [DataTable].
///
/// The [InteractiveDataTable] manages panning, scrolling and zooming of the table itself.
/// Therefor it tries to be as big as possible, so *don't* wrap it in parents that don't constrain its size, for example a [SingleChildScrollView].
///
/// The header is fixed and the body can be scrolled.
///
/// To zoom with the mouse, use the mouse wheel and hold the ctrl key.
/// To scroll with the mouse, use the mouse wheel. To scroll horizontally, hold the shift key.
@immutable
class InteractiveDataTable extends BetterInteractiveViewerBase {
  /// Construct a [InteractiveDataTable].
  ///
  /// The [transformedDataTableBuilder] parameter configures the table,
  /// the [TransformedDataTableBuilder] tries to mimic the [DataTable] as closely as possible.
  ///
  /// In most use cases you can replace the [DataTable] with the [InteractiveDataTable] and it should work without any major changes.
  InteractiveDataTable({
    super.key,
    required this.transformedDataTableBuilder,
    super.allowNonCoveringScreenZoom,
    super.panAxis,
    super.maxScale,
    super.minScale,
    super.interactionEndFrictionCoefficient,
    super.panEnabled,
    super.scaleEnabled,
    super.showScrollbars,
    super.noMouseDragScroll,
    super.scaleFactor,
    super.transformationController,
    super.doubleTapToZoom,
    super.zoomToWidth,
  });

  /// The table configuration.
  final TransformedDataTableBuilder transformedDataTableBuilder;

  @override
  BetterInteractiveViewerState<InteractiveDataTable> createState() =>
      _InteractiveDataTableState();
}

class _InteractiveDataTableState
    extends BetterInteractiveViewerState<InteractiveDataTable> {
  @override
  final GlobalKey<TransformedDataTableState> childKey = GlobalKey();

  @override
  void updateTransform() {
    childKey.currentState?.transform = transformForRender;
  }

  @override
  Widget buildChild(BuildContext context) {
    return widget.transformedDataTableBuilder.buildTable(
      key: childKey,
      transform: transformForRender,
      onLayoutComplete: calculatedRealChildSize,
      scrollbarController: scrollbarController,
    );
  }

  @override
  HorizontalNonCoveringZoomAlign get nonCoveringZoomAlignment =>
      HorizontalNonCoveringZoomAlign.middle;
}
