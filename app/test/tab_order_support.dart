// A tab order held in memory, for tests that draw the shell without a settings store behind it.

import 'package:kikuyomi/src/app_shell.dart';

class FixedTabOrder extends TabOrder {
  FixedTabOrder([this.tabs = AppTab.values]);

  final List<AppTab> tabs;

  @override
  List<AppTab> build() => tabs;

  @override
  Future<void> reorder(List<AppTab> moved) async => state = List.of(moved);

  @override
  Future<void> reset() async => state = AppTab.values;
}
