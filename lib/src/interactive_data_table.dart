library interactive_table;
//Copied and modified from InteractiveViewer.dart

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'scrollbars/auto_platform_scrollbar_controller.dart';
import 'scrollbars/transform_scrollbar_controller.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

import 'package:flutter/material.dart';

import 'transformed_data_table.dart';
import 'extensions.dart';

///
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
class InteractiveDataTable extends StatefulWidget {
  /// Construct a [InteractiveDataTable].
  ///
  /// The [transformedDataTableBuilder] parameter configures the table,
  /// the [TransformedDataTableBuilder] tries to mimic the [DataTable] as closely as possible.
  ///
  /// In most use cases you can replace the [DataTable] with the [InteractiveDataTable] and it should work without any major changes.
  InteractiveDataTable({
    super.key,
    required this.transformedDataTableBuilder,
    this.allowNonCoveringScreenZoom = true,
    this.panAxis = PanAxis.free,
    this.maxScale = 2.5,
    this.minScale = 0.2,
    this.interactionEndFrictionCoefficient = _kDrag,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.showScrollbars = true,
    this.scaleFactor = kDefaultMouseScrollToScaleFactor,
    this.transformationController,
    this.doubleTapToZoom = true,
    this.zoomToWidth = true,
  })  : assert(minScale > 0),
        assert(interactionEndFrictionCoefficient > 0),
        assert(minScale.isFinite),
        assert(maxScale > 0),
        assert(!maxScale.isNaN),
        assert(maxScale >= minScale);

  /// When set to [PanAxis.aligned], panning is only allowed in the horizontal
  /// axis or the vertical axis, diagonal panning is not allowed.
  ///
  /// When set to [PanAxis.vertical] or [PanAxis.horizontal] panning is only
  /// allowed in the specified axis. For example, if set to [PanAxis.vertical],
  /// panning will only be allowed in the vertical axis. And if set to [PanAxis.horizontal],
  /// panning will only be allowed in the horizontal axis.
  ///
  /// When set to [PanAxis.free] panning is allowed in all directions.
  ///
  /// Defaults to [PanAxis.free].
  final PanAxis panAxis;

  /// If false, the user will be prevented from panning.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [scaleEnabled], which is similar but for scale.
  final bool panEnabled;

  /// If false, the user will be prevented from scaling.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [panEnabled], which is similar but for panning.
  final bool scaleEnabled;

  /// Zooms the table to the width of the viewport, every time something with the table layout changes.
  final bool zoomToWidth;

  /// Allows the user to zoom by double tapping.
  final bool doubleTapToZoom;

  /// Determines the amount of scale to be performed per pointer scroll.
  ///
  /// Defaults to [kDefaultMouseScrollToScaleFactor].
  ///
  /// Increasing this value above the default causes scaling to feel slower,
  /// while decreasing it causes scaling to feel faster.
  ///
  /// The amount of scale is calculated as the exponential function of the
  /// [PointerScrollEvent.scrollDelta] to [scaleFactor] ratio. In the Flutter
  /// engine, the mousewheel [PointerScrollEvent.scrollDelta] is hardcoded to 20
  /// per scroll, while a trackpad scroll can be any amount.
  ///
  /// Affects only pointer device scrolling, not pinch to zoom.
  final double scaleFactor;

  /// The maximum allowed scale.
  ///
  /// The scale will be clamped between this and [minScale] inclusively.
  ///
  /// Defaults to 2.5.
  ///
  /// Must be greater than zero and greater than [minScale].
  final double maxScale;

  /// The minimum allowed scale.
  ///
  /// The scale will be clamped between this and [maxScale] inclusively.
  ///
  /// Defaults to 0.8.
  ///
  /// Must be a finite number greater than zero and less than [maxScale].
  final double minScale;

  /// Changes the deceleration behavior after a gesture.
  ///
  /// Defaults to 0.0000135.
  ///
  /// Must be a finite number greater than zero.
  final double interactionEndFrictionCoefficient;

  /// A [TransformationController] for the transformation performed on the
  /// child.
  ///
  /// Whenever the child is transformed, the [Matrix4] value is updated and all
  /// listeners are notified. If the value is set, InteractiveDataTable will update
  /// to respect the new value.
  ///
  /// {@tool dartpad}
  /// This example shows how transformationController can be used to animate the
  /// transformation back to its starting position.
  ///
  /// ** See code in examples/api/lib/widgets/interactive_viewer/interactive_viewer.transformation_controller.0.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [ValueNotifier], the parent class of TransformationController.
  ///  * [TextEditingController] for an example of another similar pattern.
  final TransformationController? transformationController;

  /// The table configuration.
  final TransformedDataTableBuilder transformedDataTableBuilder;

  /// Allows the user to zoom out the table so that it is displayed smaller than the viewports width and height.
  /// It gets centered if its smaller than the width and displayed at the top if its smaller than the height.
  final bool allowNonCoveringScreenZoom;

  /// Whether to show scrollbars.
  final bool showScrollbars;

  // Used as the coefficient of friction in the inertial translation animation.
  // This value was eyeballed to give a feel similar to Google Photos.
  static const double _kDrag = 0.0000135;

  /// Returns the closest point to the given point on the given line segment.
  @visibleForTesting
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared = math.pow(l2.x - l1.x, 2.0).toDouble() +
        math.pow(l2.y - l1.y, 2.0).toDouble();

    // In this case, l1 == l2.
    if (lengthSquared == 0) {
      return l1;
    }

    // Calculate how far down the line segment the closest point is and return
    // the point.
    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction =
        clampDouble(l1P.dot(l1L2) / lengthSquared, 0.0, 1.0);
    return l1 + l1L2 * fraction;
  }

  /// Given a quad, return its axis aligned bounding box.
  @visibleForTesting
  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(
        quad.point1.x,
        math.min(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(
        quad.point1.y,
        math.min(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(
        quad.point1.x,
        math.max(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(
        quad.point1.y,
        math.max(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  /// Returns true iff the point is inside the rectangle given by the Quad,
  /// inclusively.
  /// Algorithm from https://math.stackexchange.com/a/190373.
  @visibleForTesting
  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  /// Get the point inside (inclusively) the given Quad that is nearest to the
  /// given Vector3.
  @visibleForTesting
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    // If the point is inside the axis aligned bounding box, then it's ok where
    // it is.
    if (pointIsInside(point, quad)) {
      return point;
    }

    // Otherwise, return the nearest point on the quad.
    final List<Vector3> closestPoints = <Vector3>[
      InteractiveDataTable.getNearestPointOnLine(
          point, quad.point0, quad.point1),
      InteractiveDataTable.getNearestPointOnLine(
          point, quad.point1, quad.point2),
      InteractiveDataTable.getNearestPointOnLine(
          point, quad.point2, quad.point3),
      InteractiveDataTable.getNearestPointOnLine(
          point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    late Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) +
            math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  @override
  State<InteractiveDataTable> createState() => _InteractiveDataTableState();
}

class _InteractiveDataTableState extends State<InteractiveDataTable>
    with TickerProviderStateMixin {
  TransformationController? _transformationController;

  final GlobalKey<TransformedDataTableState> _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset>? _animation;
  Animation<double>? _scaleAnimation;
  late Offset _scaleAnimationFocalPoint;
  late AnimationController _controller;
  late AnimationController _scaleController;
  Axis? _currentAxis; // Used with panAxis.
  Offset? _referenceFocalPoint; // Point where the current gesture began.
  double? _scaleStart; // Scale value at start of scaling gesture.
  double? _rotationStart = 0.0; // Rotation at start of rotation gesture.
  double _currentRotation = 0.0; // Rotation of _transformationController.value.
  _GestureType? _gestureType;

  RawTransformScrollbarController? scrollbarController;

  Size? _realChildSize;

  void _calculatedTableSize(Size size) {
    _realChildSize = size;
    if (widget.allowNonCoveringScreenZoom) {
      if (widget.zoomToWidth) {
        Future.delayed(Duration.zero, () {
          _transformationController!.value = _matrixScale(
              _transformationController!.value,
              _viewport.width /
                  (size.width *
                      _transformationController!.value.getScaleOnZAxis()));
        });
      } else {
        Future.delayed(Duration.zero, _updateTransform);
      }
    } else {
      Future.delayed(Duration.zero, () {
        _transformationController!.value = _matrixScale(
            _transformationController!.value,
            widget.zoomToWidth
                ? _boundaryRect.width /
                    (size.width *
                        _transformationController!.value.getScaleOnZAxis())
                : 0.000001);
      });
    }
  }

  bool _nonCoveringZoom = false;

  void _afterNonCoveringZoom() {
    Matrix4 oldValue = _transformationController!.value.clone();
    Vector3 oldTranslation = oldValue.getTranslation();
    oldTranslation.x = 0;
    oldValue.setTranslation(oldTranslation);
    _transformationController!.value = oldValue;
  }

  Matrix4 get _transformForRender {
    if (!widget.allowNonCoveringScreenZoom || _realChildSize == null) {
      _nonCoveringZoom = false;
      return _transformationController!.value;
    }
    Matrix4 transform = _transformationController!.value;
    Rect boundaryRect = _boundaryRect;
    Rect viewport = _viewport;
    if (boundaryRect.width * transform.getScaleOnZAxis() < viewport.width) {
      transform = transform.clone(); //dont change the transformation controller
      double scale = transform.getScaleOnZAxis();
      transform.scale(1 / scale);
      double translation = (viewport.width - (boundaryRect.width * scale)) / 2;
      transform.translate(translation);
      transform.scale(scale);
      _nonCoveringZoom = true;
    } else {
      _nonCoveringZoom = false;
    }
    return transform;
  }

  void _updateTransform() {
    _childKey.currentState?.transform = _transformForRender;
  }

  // TODO(justinmc): Add rotateEnabled parameter to the widget and remove this
  // hardcoded value when the rotation feature is implemented.
  // https://github.com/flutter/flutter/issues/57698
  final bool _rotateEnabled = false;

  // The _boundaryRect is calculated by adding the boundaryMargin to the size of
  // the child.
  Rect get _boundaryRect {
    assert(_childKey.currentContext != null);

    Size childSize;
    if (_realChildSize != null) {
      childSize = _realChildSize!;
    } else {
      final RenderBox childRenderBox =
          _childKey.currentContext!.findRenderObject()! as RenderBox;
      childSize = childRenderBox.size;
    }
    Offset offset = Offset.zero;

    return offset & childSize;
  }

  // The Rect representing the child's parent.
  Rect get _viewport {
    assert(_parentKey.currentContext != null);
    final RenderBox parentRenderBox =
        _parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    late final Offset alignedTranslation;

    if (_currentAxis != null) {
      switch (widget.panAxis) {
        case PanAxis.horizontal:
          alignedTranslation = _alignAxis(translation, Axis.horizontal);
        case PanAxis.vertical:
          alignedTranslation = _alignAxis(translation, Axis.vertical);
        case PanAxis.aligned:
          alignedTranslation = _alignAxis(translation, _currentAxis!);
        case PanAxis.free:
          alignedTranslation = translation;
      }
    } else {
      alignedTranslation = translation;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translate(
        alignedTranslation.dx,
        alignedTranslation.dy,
      );

    // Transform the viewport to determine where its four corners will be after
    // the child has been transformed.
    final Quad nextViewport = _transformViewport(nextMatrix, _viewport);

    // If the boundaries are infinite, then no need to check if the translation
    // fits within them.
    if (_boundaryRect.isInfinite) {
      return nextMatrix;
    }

    // Expand the boundaries with rotation. This prevents the problem where a
    // mismatch in orientation between the viewport and boundaries effectively
    // limits translation. With this approach, all points that are visible with
    // no rotation are visible after rotation.
    final Quad boundariesAabbQuad = _getAxisAlignedBoundingBoxWithRotation(
      _boundaryRect,
      _currentRotation,
    );

    // If the given translation fits completely within the boundaries, allow it.
    final Offset offendingDistance =
        _exceedsBy(boundariesAabbQuad, nextViewport);
    if (offendingDistance == Offset.zero) {
      return nextMatrix;
    }

    // Desired translation goes out of bounds, so translate to the nearest
    // in-bounds point instead.
    final Offset nextTotalTranslation = _getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getScaleOnZAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );
    // TODO(justinmc): This needs some work to handle rotation properly. The
    // idea is that the boundaries are axis aligned (boundariesAabbQuad), but
    // calculating the translation to put the viewport inside that Quad is more
    // complicated than this when rotated.
    // https://github.com/flutter/flutter/issues/57698
    final Matrix4 correctedMatrix = matrix.clone()
      ..setTranslation(Vector3(
        correctedTotalTranslation.dx,
        correctedTotalTranslation.dy,
        0.0,
      ));

    // Double check that the corrected translation fits.
    final Quad correctedViewport =
        _transformViewport(correctedMatrix, _viewport);
    final Offset offendingCorrectedDistance =
        _exceedsBy(boundariesAabbQuad, correctedViewport);
    if (offendingCorrectedDistance == Offset.zero) {
      return correctedMatrix;
    }

    // If the corrected translation doesn't fit in either direction, don't allow
    // any translation at all. This happens when the viewport is larger than the
    // entire boundary.
    if (offendingCorrectedDistance.dx != 0.0 &&
        offendingCorrectedDistance.dy != 0.0) {
      return matrix.clone();
    }

    // Otherwise, allow translation in only the direction that fits. This
    // happens when the viewport is larger than the boundary in one direction.
    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    return matrix.clone()
      ..setTranslation(Vector3(
        unidirectionalCorrectedTotalTranslation.dx,
        unidirectionalCorrectedTotalTranslation.dy,
        0.0,
      ));
  }

  // Return a new matrix representing the given matrix after applying the given
  // scale.
  Matrix4 _matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale =
        _transformationController!.value.getScaleOnZAxis();
    final double totalScale = math.max(
      currentScale * scale,
      // Ensure that the scale cannot make the child so **small** that it can't fit //Korrigiert von der originalversion
      // inside the boundaries (in either direction).
      math.max(
        widget.allowNonCoveringScreenZoom
            ? widget.minScale
            : (_viewport.width / _boundaryRect.width),
        widget.allowNonCoveringScreenZoom
            ? widget.minScale
            : (_viewport.height / _boundaryRect.height),
      ),
    );
    final double clampedTotalScale = clampDouble(
      totalScale,
      widget.minScale,
      widget.maxScale,
    );
    Vector3 translation = matrix.getTranslation();
    // If smaller than the viewport, set translation to 0
    if (clampedTotalScale < (_viewport.height / _boundaryRect.height)) {
      translation.y = 0;
    }
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()
      ..setTranslation(translation)
      ..scale(clampedScale);
  }

  // Return a new matrix representing the given matrix after applying the given
  // rotation.
  Matrix4 _matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = _transformationController!.toScene(
      focalPoint,
    );
    return matrix.clone()
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // Returns true iff the given _GestureType is enabled.
  bool _gestureIsSupported(_GestureType? gestureType) {
    switch (gestureType) {
      case _GestureType.rotate:
        return _rotateEnabled;

      case _GestureType.scale:
        return widget.scaleEnabled;

      case _GestureType.pan:
      case null:
        return widget.panEnabled;
    }
  }

  // Decide which type of gesture this is by comparing the amount of scale
  // and rotation in the gesture, if any. Scale starts at 1 and rotation
  // starts at 0. Pan will have no scale and no rotation because it uses only one
  // finger.
  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final double scale = !widget.scaleEnabled ? 1.0 : details.scale;
    final double rotation = !_rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return _GestureType.scale;
    } else if (rotation != 0.0) {
      return _GestureType.rotate;
    } else {
      return _GestureType.pan;
    }
  }

  void resetAnimation() {
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_onAnimate);
      _animation = null;
    }
    if (_scaleController.isAnimating) {
      _scaleController.stop();
      _scaleController.reset();
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
    }
    _afterAnimate();
  }

  // Handle the start of a gesture. All of pan, scale, and rotate are handled
  // with GestureDetector's scale gesture.
  void _onScaleStart(ScaleStartDetails details) {
    resetAnimation();

    _gestureType = null;
    _currentAxis = null;
    _scaleStart = _transformationController!.value.getScaleOnZAxis();
    _referenceFocalPoint = _transformationController!.toScene(
      details.localFocalPoint,
    );
    _rotationStart = _currentRotation;
  }

  // Handle an update to an ongoing gesture. All of pan, scale, and rotate are
  // handled with GestureDetector's scale gesture.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController!.value.getScaleOnZAxis();
    _scaleAnimationFocalPoint = details.localFocalPoint;
    final Offset focalPointScene = _transformationController!.toScene(
      details.localFocalPoint,
    );

    if (_gestureType == _GestureType.pan) {
      // When a gesture first starts, it sometimes has no change in scale and
      // rotation despite being a two-finger gesture. Here the gesture is
      // allowed to be reinterpreted as its correct type after originally
      // being marked as a pan.
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }
    if (!_gestureIsSupported(_gestureType)) {
      return;
    }

    switch (_gestureType!) {
      case _GestureType.scale:
        assert(_scaleStart != null);
        scrollbarController?.onScrollStart();
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformationController!.value = _matrixScale(
          _transformationController!.value,
          scaleChange,
        );

        // While scaling, translate such that the user's two fingers stay on
        // the same places in the scene. That means that the focal point of
        // the scale should be on the same place in the scene before and after
        // the scale.
        // BUT when the user zooms out of his controllable area, the focal
        // point should always be in the middle of the screen so that the
        // child stays centered.
        final Offset focalPointSceneScaled = _transformationController!.toScene(
          details.localFocalPoint,
        );
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          focalPointSceneScaled - _referenceFocalPoint!,
        );

        // details.localFocalPoint should now be at the same location as the
        // original _referenceFocalPoint point. If it's not, that's because
        // the translate came in contact with a boundary. In that case, update
        // _referenceFocalPoint so subsequent updates happen in relation to
        // the new effective focal point.
        final Offset focalPointSceneCheck = _transformationController!.toScene(
          details.localFocalPoint,
        );
        if (_round(_referenceFocalPoint!) != _round(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }
        if (_nonCoveringZoom) {
          _afterNonCoveringZoom();
        }

      case _GestureType.rotate:
        if (details.rotation == 0.0) {
          return;
        }
        scrollbarController?.onScrollStart();
        final double desiredRotation = _rotationStart! + details.rotation;
        _transformationController!.value = _matrixRotate(
          _transformationController!.value,
          _currentRotation - desiredRotation,
          details.localFocalPoint,
        );
        _currentRotation = desiredRotation;

      case _GestureType.pan:
        assert(_referenceFocalPoint != null);
        _currentAxis ??= _getPanAxis(_referenceFocalPoint!, focalPointScene);

        if (widget.panAxis == PanAxis.horizontal) {
          scrollbarController?.onScrollStartHorizontal();
        } else if (widget.panAxis == PanAxis.vertical) {
          scrollbarController?.onScrollStartVertical();
        } else if (widget.panAxis == PanAxis.free) {
          scrollbarController?.onScrollStart();
        } else if (widget.panAxis == PanAxis.aligned) {
          if (_currentAxis == Axis.horizontal) {
            scrollbarController?.onScrollStartHorizontal();
          } else {
            scrollbarController?.onScrollStartVertical();
          }
        }
        // details may have a change in scale here when scaleEnabled is false.
        // In an effort to keep the behavior similar whether or not scaleEnabled
        // is true, these gestures are thrown away.
        if (details.scale != 1.0) {
          return;
        }
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange =
            focalPointScene - _referenceFocalPoint!;
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          translationChange,
        );
        _referenceFocalPoint = _transformationController!.toScene(
          details.localFocalPoint,
        );
    }
  }

  // Handle the end of a gesture of _GestureType. All of pan, scale, and rotate
  // are handled with GestureDetector's scale gesture.
  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _rotationStart = null;
    _referenceFocalPoint = null;

    _animation?.removeListener(_onAnimate);
    _scaleAnimation?.removeListener(_onScaleAnimate);
    _controller.reset();
    _scaleController.reset();

    if (!_gestureIsSupported(_gestureType)) {
      _currentAxis = null;
      scrollbarController?.onScrollEnd();
      return;
    }

    if (_gestureType == _GestureType.pan) {
      if (details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
        _currentAxis = null;
        scrollbarController?.onScrollEnd();
        return;
      }
      final Vector3 translationVector =
          _transformationController!.value.getTranslation();
      final Offset translation =
          Offset(translationVector.x, translationVector.y);
      final FrictionSimulation frictionSimulationX = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dx,
        details.velocity.pixelsPerSecond.dx,
      );
      final FrictionSimulation frictionSimulationY = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dy,
        details.velocity.pixelsPerSecond.dy,
      );
      final double tFinal = _getFinalTime(
        details.velocity.pixelsPerSecond.distance,
        widget.interactionEndFrictionCoefficient,
      );
      _animation = Tween<Offset>(
        begin: translation,
        end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ));
      _controller.duration = Duration(milliseconds: (tFinal * 1000).round());
      _animation!.addListener(_onAnimate);
      _controller.forward();
    } else if (_gestureType == _GestureType.scale) {
      if (details.scaleVelocity.abs() < 0.1) {
        _currentAxis = null;
        scrollbarController?.onScrollEnd();
        return;
      }
      final double scale = _transformationController!.value.getScaleOnZAxis();
      final FrictionSimulation frictionSimulation = FrictionSimulation(
          widget.interactionEndFrictionCoefficient * widget.scaleFactor,
          scale,
          details.scaleVelocity / 10);
      final double tFinal = _getFinalTime(
          details.scaleVelocity.abs(), widget.interactionEndFrictionCoefficient,
          effectivelyMotionless: 0.1);
      _scaleAnimation =
          Tween<double>(begin: scale, end: frictionSimulation.x(tFinal))
              .animate(CurvedAnimation(
                  parent: _scaleController, curve: Curves.decelerate));
      _scaleController.duration =
          Duration(milliseconds: (tFinal * 1000).round());
      _scaleAnimation!.addListener(_onScaleAnimate);
      _scaleController.forward();
    } else {
      scrollbarController?.onScrollEnd();
    }
  }

  //Used to check if ctrl or shift for scrolling is pressed
  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _ctrlPressed = true;
      } else if (event is KeyUpEvent) {
        _ctrlPressed = false;
      }
    }

    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _shiftPressed = true;
      } else if (event is KeyUpEvent) {
        _shiftPressed = false;
      }
    }

    return false;
  }

  bool _ctrlPressed = false;
  bool _shiftPressed = false;

  // Handle mousewheel and web trackpad scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (!_ctrlPressed) {
        // Normal scroll, so treat it as a pan.
        if (!_gestureIsSupported(_GestureType.pan)) {
          return;
        }

        Offset scrollDelta = event.scrollDelta;
        //Shift pressed, so scroll horizontally with the mousewheel
        if (event.kind != PointerDeviceKind.trackpad && _shiftPressed) {
          scrollDelta = Offset(scrollDelta.dy, scrollDelta.dx);
          scrollbarController?.onScrollStartHorizontal();
        } else {
          scrollbarController?.onScrollStartVertical();
        }

        final Offset localDelta = PointerEvent.transformDeltaViaPositions(
          untransformedEndPosition: event.position + scrollDelta,
          untransformedDelta: scrollDelta,
          transform: event.transform,
        );

        final Offset focalPointScene = _transformationController!.toScene(
          event.localPosition,
        );

        final Offset newFocalPointScene = _transformationController!.toScene(
          event.localPosition - localDelta,
        );

        _transformationController!.value = _matrixTranslate(
            _transformationController!.value,
            newFocalPointScene - focalPointScene);
        scrollbarController?.onScrollEnd();
        return;
      }
      // Ignore left and right mouse wheel scroll.
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }

    if (!_gestureIsSupported(_GestureType.scale)) {
      return;
    }
    scrollbarController?.onScrollStart();

    final Offset focalPointScene = _transformationController!.toScene(
      event.localPosition,
    );

    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scaleChange,
    );

    // After scaling, translate such that the event's position is at the
    // same scene point before and after the scale.
    final Offset focalPointSceneScaled = _transformationController!.toScene(
      event.localPosition,
    );
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      focalPointSceneScaled - focalPointScene,
    );

    if (_nonCoveringZoom) {
      _afterNonCoveringZoom();
    }
    scrollbarController?.onScrollEnd();
  }

  // Used for getting position of double tap for zoom in and out
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) {
      return;
    }
    final double currentScale =
        _transformationController!.value.getScaleOnZAxis();
    final double pos1Scale = _viewport.width / _boundaryRect.width;
    const double pos2Scale = 1;
    final position = _doubleTapDetails!.localPosition;

    //Zoom to no zoom when a) the user is already zoomed out or b)
    //the user is zoomed in and the table is bigger than standard size

    //Because we cant compare doubles, we have to check if the difference is smaller than 0.01 (no noticeable difference for the user)
    final bool zoomToNormal =
        ((currentScale - pos1Scale).abs() < 0.01) || currentScale > pos2Scale;

    final double scaleChange =
        (zoomToNormal ? pos2Scale : pos1Scale) / currentScale;

    Matrix4 newM = _getScaled(scale: scaleChange);
    _animateTo(newM, noTranslation: true, focalPoint: position);
  }

  /// Please dont include any focal point tracking in this function, because it is calculated automatically
  /// If you do not include translation or zoom, please disable it by setting noTranslation or noZoom to true
  /// Please set focalPoint to the position of the zoom if you want to zoom, otherwise set noZoom to true
  void _animateTo(Matrix4 newMatrix,
      {Duration duration = const Duration(milliseconds: 150),
      Curve curve = Curves.linear,
      bool noTranslation = false,
      noZoom = false,
      Offset? focalPoint}) {
    assert(!(noTranslation && noZoom),
        "Please dont disable both translation and zoom, because then the animation would be useless");
    assert(noZoom || focalPoint != null,
        "Please provide a focal point for zooming");
    resetAnimation();
    if (!noZoom) {
      _scaleAnimationFocalPoint = focalPoint!;
    }
    _scaleStart = null;
    _rotationStart = null;
    _referenceFocalPoint = null;

    _animation?.removeListener(_onAnimate);
    _scaleAnimation?.removeListener(_onScaleAnimate);
    _controller.reset();
    _scaleController.reset();

    if (!noTranslation) {
      Offset translation = _getMatrixTranslation(newMatrix);
      Offset oldTranslation =
          _getMatrixTranslation(_transformationController!.value);
      _animation = Tween<Offset>(
        begin: oldTranslation,
        end: translation,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: curve,
      ));
      _controller.duration = duration;
    }

    if (!noZoom) {
      double scale = newMatrix.getScaleOnZAxis();
      double oldScale = _transformationController!.value.getScaleOnZAxis();

      _scaleAnimation = Tween<double>(begin: oldScale, end: scale)
          .animate(CurvedAnimation(parent: _scaleController, curve: curve));
      _scaleController.duration = duration;
    }

    _setToAfterAnimate = _getScaled(
        position: focalPoint,
        matrixZoomedNeedToApplyFocalPointTracking: newMatrix);

    scrollbarController?.onScrollStart();
    if (!noTranslation) {
      _animation!.addListener(_onAnimate);
      _controller.forward();
    }
    if (!noZoom) {
      _scaleAnimation!.addListener(_onScaleAnimate);
      _scaleController.forward();
    }
  }

  Matrix4? _setToAfterAnimate;

  void _afterAnimate() {
    if (_setToAfterAnimate != null) {
      _transformationController!.value = _setToAfterAnimate!;
      _setToAfterAnimate = null;
    }
    scrollbarController?.onScrollEnd();
  }

  Matrix4 _getScaled(
      {double? scale,
      Offset? position,
      Matrix4? matrixZoomedNeedToApplyFocalPointTracking}) {
    Matrix4 newM;
    if (scale != null) {
      newM = _matrixScale(
        _transformationController!.value,
        scale,
      );
    } else {
      newM = matrixZoomedNeedToApplyFocalPointTracking!;
    }

    if (position != null) {
      Offset referenceFocalPoint = _transformationController!.toScene(
        position,
      );

      // While scaling, translate such that the user's two fingers stay on
      // the same places in the scene. That means that the focal point of
      // the scale should be on the same place in the scene before and after
      // the scale.
      // BUT when the user zooms out of his controllable area, the focal
      // point should always be in the middle of the screen so that the
      // child stays centered.
      final Offset focalPointSceneScaled = newM.toScene(
        position,
      );

      newM = _matrixTranslate(
        newM,
        focalPointSceneScaled - referenceFocalPoint,
      );
    }
    return newM;
  }

  // Handle inertia drag animation.
  void _onAnimate() {
    if (!_controller.isAnimating) {
      _currentAxis = null;
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _controller.reset();
      _afterAnimate();
      return;
    }
    // Translate such that the resulting translation is _animation.value.
    final Vector3 translationVector =
        _transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = _transformationController!.toScene(
      translation,
    );
    final Offset animationScene = _transformationController!.toScene(
      _animation!.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      translationChangeScene,
    );
  }

  // Handle inertia scale animation.
  void _onScaleAnimate() {
    if (!_scaleController.isAnimating) {
      _currentAxis = null;
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
      _scaleController.reset();
      _afterAnimate();
      return;
    }
    final double desiredScale = _scaleAnimation!.value;
    final double scaleChange =
        desiredScale / _transformationController!.value.getScaleOnZAxis();
    final Offset referenceFocalPoint = _transformationController!.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scaleChange,
    );

    // While scaling, translate such that the user's two fingers stay on
    // the same places in the scene. That means that the focal point of
    // the scale should be on the same place in the scene before and after
    // the scale.
    final Offset focalPointSceneScaled = _transformationController!.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      focalPointSceneScaled - referenceFocalPoint,
    );
  }

  void _onTransformationControllerChange() {
    //// A change to the TransformationController's value is a change to the
    //// state.
    //setState(() {});
    _updateTransform();
  }

  @override
  void initState() {
    super.initState();

    _transformationController =
        widget.transformationController ?? TransformationController();
    _transformationController!.addListener(_onTransformationControllerChange);
    _controller = AnimationController(vsync: this);
    _scaleController = AnimationController(vsync: this);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  void setScrollbarControllers() {
    if (!widget.showScrollbars) {
      scrollbarController = null;
      return;
    }
    scrollbarController ??= getPlatformScrollbarController(
      vsync: this,
      controlInterface: CustomTransformScrollbarWidgetInterface(
        fgetTransform: () => _transformationController!.value,
        fgetViewport: () => _viewport.size,
        fgetContent: () => _boundaryRect.size,
        fcontext: () => context,
        fjumpVertical: (v) {
          _transformationController!.value = _matrixTranslate(
              _transformationController!.value,
              Offset(
                  0, v / _transformationController!.value.getScaleOnZAxis()));
        },
        fjumpHorizontal: (h) {
          _transformationController!.value = _matrixTranslate(
              _transformationController!.value,
              Offset(
                  h / _transformationController!.value.getScaleOnZAxis(), 0));
        },
        fanimateVertical: (v, d, c) {
          Matrix4 newTransform = _matrixTranslate(
              _transformationController!.value,
              Offset(
                  0, -v / _transformationController!.value.getScaleOnZAxis()));
          _animateTo(newTransform, duration: d, curve: c, noZoom: true);
        },
        fanimateHorizontal: (h, d, c) {
          Matrix4 newTransform = _matrixTranslate(
              _transformationController!.value,
              Offset(
                  -h / _transformationController!.value.getScaleOnZAxis(), 0));
          _animateTo(newTransform, duration: d, curve: c, noZoom: true);
        },
      ),
    );
  }

  @override
  void didUpdateWidget(InteractiveDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle all cases of needing to dispose and initialize
    // transformationControllers.
    if (oldWidget.transformationController == null) {
      if (widget.transformationController != null) {
        _transformationController!
            .removeListener(_onTransformationControllerChange);
        _transformationController!.dispose();
        _transformationController = widget.transformationController;
        _transformationController!
            .addListener(_onTransformationControllerChange);
      }
    } else {
      if (widget.transformationController == null) {
        _transformationController!
            .removeListener(_onTransformationControllerChange);
        _transformationController = TransformationController();
        _transformationController!
            .addListener(_onTransformationControllerChange);
      } else if (widget.transformationController !=
          oldWidget.transformationController) {
        _transformationController!
            .removeListener(_onTransformationControllerChange);
        _transformationController = widget.transformationController;
        _transformationController!
            .addListener(_onTransformationControllerChange);
      }
    }

    if (oldWidget.showScrollbars != widget.showScrollbars) {
      setScrollbarControllers();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setScrollbarControllers();
    scrollbarController?.onDidChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    _transformationController!
        .removeListener(_onTransformationControllerChange);
    if (widget.transformationController == null) {
      _transformationController!.dispose();
    }
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    ExtendedTransformScrollbarController? scrollbarController =
        this.scrollbarController;
    scrollbarController?.updateScrollbarPainters();
    child = widget.transformedDataTableBuilder.buildTable(
      key: _childKey,
      transform: _transformForRender,
      onLayoutComplete: _calculatedTableSize,
      scrollbarController: scrollbarController,
    );

    if (scrollbarController != null) {
      child = RawGestureDetector(
        gestures: scrollbarController.getGesturesVertical(context),
        child: MouseRegion(
          onExit: (PointerExitEvent event) {
            switch (event.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.trackpad:
                if (scrollbarController.enableGestures) {
                  scrollbarController.handleHoverExit(event);
                }
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
              case PointerDeviceKind.unknown:
              case PointerDeviceKind.touch:
                break;
            }
          },
          onHover: (PointerHoverEvent event) {
            switch (event.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.trackpad:
                if (scrollbarController.enableGestures) {
                  scrollbarController.handleHover(event);
                }
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
              case PointerDeviceKind.unknown:
              case PointerDeviceKind.touch:
                break;
            }
          },
          child: child,
        ),
      );
      child = RawGestureDetector(
        gestures: scrollbarController.getGesturesHorizontal(context),
        child: child,
      );
    }

    return Listener(
      key: _parentKey,
      onPointerSignal: _receivedPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Necessary when panning off screen.
        onScaleEnd: _onScaleEnd,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTapDown:
            widget.doubleTapToZoom ? ((d) => _doubleTapDetails = d) : null,
        onDoubleTap: widget.doubleTapToZoom ? _handleDoubleTap : null,
        child: child,
      ),
    );
  }
}

// A classification of relevant user gestures. Each contiguous user gesture is
// represented by exactly one _GestureType.
enum _GestureType {
  pan,
  scale,
  rotate,
}

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double _getFinalTime(double velocity, double drag,
    {double effectivelyMotionless = 10}) {
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

// Return the translation from the given Matrix4 as an Offset.
Offset _getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

// Transform the four corners of the viewport by the inverse of the given
// matrix. This gives the viewport after the child has been transformed by the
// given matrix. The viewport transforms as the inverse of the child (i.e.
// moving the child left is equivalent to moving the viewport right).
Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

// Find the axis aligned bounding box for the rect rotated about its center by
// the given amount.
Quad _getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translate(rect.size.width / 2, rect.size.height / 2)
    ..rotateZ(rotation)
    ..translate(-rect.size.width / 2, -rect.size.height / 2);
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return InteractiveDataTable.getAxisAlignedBoundingBox(boundariesRotated);
}

// Return the amount that viewport lies outside of boundary. If the viewport
// is completely contained within the boundary (inclusively), then returns
// Offset.zero.
Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside =
        InteractiveDataTable.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

// Align the given offset to the given axis by allowing movement only in the
// axis direction.
Offset _alignAxis(Offset offset, Axis axis) {
  switch (axis) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
}

// Given two points, return the axis where the distance between the points is
// greatest. If they are equal, return null.
Axis? _getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}

extension on Matrix4 {
  Offset toScene(Offset viewportPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(this);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }
}
