import 'dart:convert';
import 'dart:io';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';
import 'package:utf8decoder_hw/utf8decoder_hw.dart';

Future<void> main() async {
  final clock = SimpleClockGenerator(10).clk;
  final reset = Logic()..inject(1);
  final enable = Logic()..inject(0);
  final byte = Logic(width: 8);
  final status = OutputLogic3();
  final codepoint = OutputLogic21();
  final utf8decoder = UTF8Decoder(
    InputLogic1(clock),
    InputLogic1(reset),
    InputLogic1(enable),
    InputLogic8(byte),
    status,
    codepoint,
  );
  await utf8decoder.build();

  test('Reset should restore the initial state', () async {
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    reset.inject(0);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    expect(status.logic.value.toInt(), UTF8Decoder.statusInitial);
    expect(codepoint.logic.value.toInt(), 0);
  });

  test('"hello_world.dart" example should work', () async {
    const string = 'Hello, Мир 👋';
    final runes = string.runes;
    final splittedUtf8Bytes = <List<int>>[];
    for (final rune in runes) {
      final utf8Bytes = utf8.encode(String.fromCharCode(rune));
      splittedUtf8Bytes.add(utf8Bytes);
    }
    final codepoints = <int>[];
    enable.inject(1);
    for (var i = 0; i < splittedUtf8Bytes.length; ++i) {
      for (var j = 0; j < splittedUtf8Bytes[i].length; ++j) {
        if ((i == 0) && (j == 0)) {
          expect(status.logic.value.toInt(), UTF8Decoder.statusInitial);
        }
        byte.inject(splittedUtf8Bytes[i][j]);
        await Simulator.tick();
        await Simulator.tick();
        await Simulator.tick();
        if (j == (splittedUtf8Bytes[i].length - 1)) {
          expect(status.logic.value.toInt(), UTF8Decoder.statusSuccess);
          codepoints.add(codepoint.logic.value.toInt());
        } else {
          expect(status.logic.value.toInt(), UTF8Decoder.statusInprocess);
        }
      }
    }
    expect(String.fromCharCodes(codepoints), string);
  });

  test('"utf8demo.txt" should decode without error', () async {
    final string = File('test/text/utf8demo.txt').readAsStringSync();
    final runes = string.runes;
    final splittedUtf8Bytes = <List<int>>[];
    for (final rune in runes) {
      final utf8Bytes = utf8.encode(String.fromCharCode(rune));
      splittedUtf8Bytes.add(utf8Bytes);
    }
    final codepoints = <int>[];
    enable.inject(1);
    for (var i = 0; i < splittedUtf8Bytes.length; ++i) {
      for (var j = 0; j < splittedUtf8Bytes[i].length; ++j) {
        byte.inject(splittedUtf8Bytes[i][j]);
        await Simulator.tick();
        await Simulator.tick();
        await Simulator.tick();
        if (j == (splittedUtf8Bytes[i].length - 1)) {
          expect(status.logic.value.toInt(), UTF8Decoder.statusSuccess);
          codepoints.add(codepoint.logic.value.toInt());
        } else {
          expect(status.logic.value.toInt(), UTF8Decoder.statusInprocess);
        }
      }
    }
    expect(String.fromCharCodes(codepoints), string);
  });

  test('Bad bytes in "utf8test.txt" should be correctly detected', () async {
    final file = File('test/text/utf8test.txt').readAsBytesSync();
    final codepoints = <int>[];
    enable.inject(1);
    for (var i = 0, byteCount = 0; i < file.length; ++i) {
      byte.inject(file[i]);
      ++byteCount;
      await Simulator.tick();
      await Simulator.tick();
      await Simulator.tick();
      if (status.logic.value.toInt() == UTF8Decoder.statusSuccess) {
        codepoints.add(codepoint.logic.value.toInt());
        byteCount = 0;
      } else if (status.logic.value.toInt() == UTF8Decoder.statusFailure) {
        codepoints.add(0xFFFD);
        byteCount = 0;
      } else if (status.logic.value.toInt() ==
          UTF8Decoder.statusFailureRepeat) {
        for (var j = 0; j < byteCount - 1; ++j) {
          codepoints.add(0xFFFD);
        }
        --i;
        byteCount = 0;
      }
    }
    final outputString = String.fromCharCodes(codepoints);
    var dartString = utf8.decode(file, allowMalformed: true);
    // NOTE(https://github.com/dart-lang/sdk/issues/49967): Dart doesn't insert
    // enough replacement characters.
    dartString =
        '${dartString.substring(0, 11230)}\uFFFD${dartString.substring(11230)}';
    dartString =
        '${dartString.substring(0, 12011)}\uFFFD${dartString.substring(12011)}';
    expect(
      outputString,
      dartString,
    );
  });

  test('"enable" and "reset" inputs should work correctly', () async {
    final previousCodepoint = codepoint.logic.value.toInt();
    enable.inject(0);
    byte.inject(0xFF);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    expect(status.logic.value.toInt(), UTF8Decoder.statusSuccess);
    expect(codepoint.logic.value.toInt(), previousCodepoint);
    reset.inject(1);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    expect(status.logic.value.toInt(), UTF8Decoder.statusInitial);
    expect(codepoint.logic.value.toInt(), 0);
  });
}
