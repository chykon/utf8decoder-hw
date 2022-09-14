import 'package:rohd/rohd.dart';

abstract class _ExplicitLogic {
  late Logic logic;
}

abstract class _InputLogic extends _ExplicitLogic {
  _InputLogic(Logic logic) {
    this.logic = logic;
  }
}

abstract class _OutputLogic extends _ExplicitLogic {}

/// Input logic with a bit width of 1.
class InputLogic1 extends _InputLogic {
  /// Put the standard logic in the explicit one.
  InputLogic1(super.logic);
}

/// Input logic with a bit width of 8.
class InputLogic8 extends _InputLogic {
  /// Put the standard logic in the explicit one.
  InputLogic8(super.logic);
}

/// Output logic with a bit width of 3.
class OutputLogic3 extends _OutputLogic {}

/// Output logic with a bit width of 21.
class OutputLogic21 extends _OutputLogic {}
