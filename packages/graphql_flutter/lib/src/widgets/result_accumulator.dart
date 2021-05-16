import 'package:flutter/widgets.dart';

/// Same as a fold combine for lists
///
/// Return `null` to avoid setting state.
typedef Accumulator<Element> = List<Element>? Function(
  List<Element> previousValue,
  Element element,
);

List<T>? _append<T>(List<T> results, T latest) => [...results, latest];

List<T>? _appendUnique<T>(List<T> results, T latest) {
  if (!results.contains(latest)) {
    return [...results, latest];
  }
  return null;
}

/// Accumulate stream results into a [List].
///
/// Useful for handling [Subscription] results.
class ResultAccumulator<T> extends StatefulWidget {
  const ResultAccumulator({
    required this.latest,
    required this.builder,
    Accumulator<T>? accumulator,
  }) : accumulator = accumulator ?? _append;

  const ResultAccumulator.appendUniqueEntries({
    required this.latest,
    required this.builder,
  }) : accumulator = _appendUnique;

  /// The latest entry in the stream
  final T latest;

  /// The strategy for merging entries. Can return `null`
  /// to prevent a call to `setState`.
  ///
  /// Defaults to `(results, latest) => [...results, latest]`
  final Accumulator<T> accumulator;

  /// Builds the resulting widget with all accumulated results.
  final Widget Function(BuildContext, {required List<T>? results}) builder;

  @override
  _ResultAccumulatorState createState() => _ResultAccumulatorState<T>();
}

class _ResultAccumulatorState<T> extends State<ResultAccumulator<T>> {
  List<T> results = [];

  @override
  void initState() {
    results = widget.latest != null ? [widget.latest] : [];
    super.initState();
  }

  @override
  void didUpdateWidget(ResultAccumulator<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newResults = widget.accumulator(results, widget.latest);
    if (newResults != null) {
      setState(() {
        results = newResults;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, results: results);
}
