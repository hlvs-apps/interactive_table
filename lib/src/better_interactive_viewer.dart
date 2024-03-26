library interactive_table;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'extensions.dart';
import 'scrollbars/transform_and_scrollbars_widget.dart';
import 'better_interactive_viewer_base.dart';

class BetterInteractiveViewer extends BetterInteractiveViewerBase {
  final Widget child;
  final HorizontalNonCoveringZoomAlign nonCoveringZoomAlignmentHorizontal;
  final VerticalNonCoveringZoomAlign nonCoveringZoomAlignmentVertical;
  final DoubleTapZoomOutBehaviour doubleTapZoomOutBehaviour;

  BetterInteractiveViewer({
    super.key,
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
    super.doubleTapToZoom,
    super.transformationController,
    this.nonCoveringZoomAlignmentHorizontal =
        HorizontalNonCoveringZoomAlign.middle,
    this.nonCoveringZoomAlignmentVertical = VerticalNonCoveringZoomAlign.middle,
    this.doubleTapZoomOutBehaviour =
        DoubleTapZoomOutBehaviour.zoomOutToMinScale,
    required this.child,
  });

  @override
  BetterInteractiveViewerBaseState createState() =>
      _BetterInteractiveViewerState();
}

class _BetterInteractiveViewerState
    extends BetterInteractiveViewerBaseState<BetterInteractiveViewer> {
  @override
  Widget buildChild(BuildContext context) {
    return KeyedSubtree(
      key: childKey,
      child: widget.child,
    );
  }

  @override
  Widget buildTransformAndScrollbars(BuildContext context, Widget child) {
    return TransformAndScrollbarsWidget(
      scrollbarController: scrollbarController,
      transform: transformForRender,
      onResize: () => Future.microtask(afterResize),
      child: child,
    );
  }

  @override
  HorizontalNonCoveringZoomAlign get nonCoveringZoomAlignmentHorizontal =>
      widget.nonCoveringZoomAlignmentHorizontal;

  @override
  VerticalNonCoveringZoomAlign get nonCoveringZoomAlignmentVertical =>
      widget.nonCoveringZoomAlignmentVertical;

  @override
  void updateTransform() {
    setState(() {});
  }

  @override
  DoubleTapZoomOutBehaviour get doubleTapZoomOutBehaviour =>
      widget.doubleTapZoomOutBehaviour;
}
