library interactive_table;

import 'package:flutter/material.dart';

import 'interactive_data_table.dart';

/// A build configuration for a Table used in [InteractiveDataTable].
abstract class TransformedTableBuilder<T extends TransformStatefulWidget> {
  T buildTable({Key? key, required Matrix4 transform});
}

abstract class TransformStatefulWidget extends StatefulWidget {
  const TransformStatefulWidget({super.key, required this.initialTransform});

  /// The transform to apply to apply to the body of the table.
  /// The resulting transform for the header is calculated automatically.
  final Matrix4 initialTransform;

  @override
  TransformStatefulWidgetState createState();
}

abstract class TransformStatefulWidgetState<T extends TransformStatefulWidget>
    extends State<T> {
  late Matrix4 _transform;

  /// The transform to apply to apply to the table.
  Matrix4 get transform => _transform;

  /// The transform to apply to apply to the table.
  /// If set, the table will be rebuilt with the new transform.
  set transform(Matrix4 transform) {
    if (transform == _transform) {
      return;
    }
    _transform = transform;
    afterTransformChanged();
  }

  /// The same as [transform], more conventional name.
  void setTransform(Matrix4 transform) {
    this.transform = transform;
  }

  /// Override this method to be notified when the transform changed.
  /// The default implementation calls setState().
  void afterTransformChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _transform = widget.initialTransform;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _transform = widget.initialTransform;
  }
}
