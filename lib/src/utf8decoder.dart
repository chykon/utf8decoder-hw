import 'package:rohd/rohd.dart';
import 'package:utf8decoder_hw/src/explicit_logic.dart';

/// A module for converting UTF-8 to Unicode code points.
class UTF8Decoder extends Module {
  /// Create a new module instance.
  UTF8Decoder(
    InputLogic1 clock,
    InputLogic1 reset,
    InputLogic1 enable,
    InputLogic8 byte,
    OutputLogic3 status,
    OutputLogic21 codepoint,
    {super.name = 'utf8decoder',}
  ) {
    clock.logic = addInput('clock', clock.logic);
    reset.logic = addInput('reset', reset.logic);
    enable.logic = addInput('enable', enable.logic);
    byte.logic = addInput('byte', byte.logic, width: 8);
    status.logic = addOutput('status', width: 3);
    codepoint.logic = addOutput('codepoint', width: 21);

    final bytesSeen = Logic(name: 'bytes_seen', width: 2);
    final bytesNeeded = Logic(name: 'bytes_needed', width: 2);
    final lowerBoundary = Logic(name: 'lower_boundary', width: 8);
    final upperBoundary = Logic(name: 'upper_boundary', width: 8);

    Sequential(clock.logic, [
      If(
        reset.logic,
        then: [
          codepoint.logic < 0,
          bytesSeen < 0,
          bytesNeeded < 0,
          lowerBoundary < 0x80,
          upperBoundary < 0xBF,
          status.logic < UTF8Decoder.statusInitial
        ],
        orElse: [
          If(
            enable.logic,
            then: [
              If(
                bytesNeeded.eq(0),
                then: [
                  If(
                    byte.logic.lte(0x7F),
                    then: [
                      If(
                        byte.logic >= 0x00,
                        then: [
                          codepoint.logic < byte.logic.zeroExtend(21),
                          status.logic < UTF8Decoder.statusSuccess
                        ],
                        orElse: [status.logic < UTF8Decoder.statusFailure],
                      )
                    ],
                    orElse: [
                      If(
                        byte.logic.lte(0xDF),
                        then: [
                          If(
                            byte.logic >= 0xC2,
                            then: [
                              bytesNeeded < 1,
                              codepoint.logic <
                                  (byte.logic &
                                          Const(
                                            0x1F,
                                            width: 8,
                                          ))
                                      .zeroExtend(21),
                              status.logic < UTF8Decoder.statusInprocess
                            ],
                            orElse: [status.logic < UTF8Decoder.statusFailure],
                          )
                        ],
                        orElse: [
                          If(
                            byte.logic.lte(0xEF),
                            then: [
                              If(
                                byte.logic >= 0xE0,
                                then: [
                                  If(
                                    byte.logic.eq(0xE0),
                                    then: [lowerBoundary < 0xA0],
                                    orElse: [
                                      If(
                                        byte.logic.eq(0xED),
                                        then: [upperBoundary < 0x9F],
                                      )
                                    ],
                                  ),
                                  bytesNeeded < 2,
                                  codepoint.logic <
                                      (byte.logic &
                                              Const(
                                                0xF,
                                                width: 8,
                                              ))
                                          .zeroExtend(21),
                                  status.logic < UTF8Decoder.statusInprocess
                                ],
                                orElse: [
                                  status.logic < UTF8Decoder.statusFailure
                                ],
                              )
                            ],
                            orElse: [
                              If(
                                byte.logic.lte(0xF4),
                                then: [
                                  If(
                                    byte.logic >= 0xF0,
                                    then: [
                                      If(
                                        byte.logic.eq(0xF0),
                                        then: [lowerBoundary < 0x90],
                                        orElse: [
                                          If(
                                            byte.logic.eq(0xF4),
                                            then: [upperBoundary < 0x8F],
                                          )
                                        ],
                                      ),
                                      bytesNeeded < 3,
                                      codepoint.logic <
                                          (byte.logic &
                                                  Const(
                                                    0x7,
                                                    width: 8,
                                                  ))
                                              .zeroExtend(21),
                                      status.logic < UTF8Decoder.statusInprocess
                                    ],
                                    orElse: [
                                      status.logic < UTF8Decoder.statusFailure
                                    ],
                                  )
                                ],
                                orElse: [
                                  status.logic < UTF8Decoder.statusFailure
                                ],
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  )
                ],
                orElse: [
                  If(
                    ~bytesNeeded.eq(0),
                    then: [
                      If(
                        byte.logic.lte(upperBoundary),
                        then: [
                          If(
                            byte.logic >= lowerBoundary,
                            then: [
                              lowerBoundary < 0x80,
                              upperBoundary < 0xBF,
                              codepoint.logic <
                                  (codepoint.logic << Const(6, width: 3)) |
                                      (byte.logic & Const(0x3F, width: 8))
                                          .zeroExtend(21),
                              If(
                                (bytesSeen + 1).eq(bytesNeeded),
                                then: [
                                  bytesNeeded < 0,
                                  bytesSeen < 0,
                                  status.logic < UTF8Decoder.statusSuccess
                                ],
                                orElse: [bytesSeen < bytesSeen + 1],
                              )
                            ],
                            orElse: [
                              codepoint.logic < 0,
                              bytesNeeded < 0,
                              bytesSeen < 0,
                              lowerBoundary < 0x80,
                              upperBoundary < 0xBF,
                              status.logic < UTF8Decoder.statusFailureRepeat
                            ],
                          )
                        ],
                        orElse: [
                          codepoint.logic < 0,
                          bytesNeeded < 0,
                          bytesSeen < 0,
                          lowerBoundary < 0x80,
                          upperBoundary < 0xBF,
                          status.logic < UTF8Decoder.statusFailureRepeat
                        ],
                      )
                    ],
                  )
                ],
              )
            ],
          )
        ],
      )
    ]);
  }

  /// Status after reset.
  static const statusInitial = 0;
  /// The code point is not ready.
  static const statusInprocess = 1;
  /// The code point is ready.
  static const statusSuccess = 2;
  /// Bad byte received.
  static const statusFailure = 3;
  /// Bad byte received. It is necessary to repeat the transmission
  /// of the last byte.
  static const statusFailureRepeat = 4;
}
