import 'package:flutter/material.dart';

class CounterDisplay extends StatelessWidget {
  final int count;

  const CounterDisplay({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}
