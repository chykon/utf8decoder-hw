import 'dart:convert';
import 'dart:io';
import 'package:rohd/rohd.dart';
import 'package:utf8decoder_hw/utf8decoder_hw.dart';

Future<void> main() async {
  // Preparing inputs and outputs.
  final clock = SimpleClockGenerator(10).clk;
  final reset = Logic()..inject(1);
  final enable = Logic()..inject(0);
  final byte = Logic(width: 8);
  final status = OutputLogic3();
  final codepoint = OutputLogic21();

  // Create and build module instance.
  final utf8decoder = UTF8Decoder(
    InputLogic1(clock),
    InputLogic1(reset),
    InputLogic1(enable),
    InputLogic8(byte),
    status,
    codepoint,
  );
  await utf8decoder.build();

  // Generate SystemVerilog code.
  File('build/rohd/code.sv')
    ..createSync(recursive: true)
    ..writeAsStringSync(utf8decoder.generateSynth());

  // Prepare WaveDumper for simulation tracking.
  WaveDumper(utf8decoder, outputPath: 'build/rohd/waves.vcd');

  // Prepare input and output.
  final utf8Bytes = utf8.encode('Hello, Мир 👋');
  final codepoints = <int>[];

  // Run simulation.
  await Simulator.tick();
  await Simulator.tick();
  await Simulator.tick();
  reset.inject(0);
  enable.inject(1);
  for (final inputByte in utf8Bytes) {
    byte.inject(inputByte);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    if (status.logic.value.toInt() == UTF8Decoder.statusSuccess) {
      codepoints.add(codepoint.logic.value.toInt());
    }
  }
  await Simulator.tick();
  await Simulator.tick();

  // Print result.
  stdout.writeln(String.fromCharCodes(codepoints));
}
