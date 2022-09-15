# UTF8Decoder-HW

A hardware UTF-8 decoder written in [Dart](https://dart.dev/) using the [ROHD](https://github.com/intel/rohd) framework. The implementation relies on the [WHATWG: Encoding - "UTF-8 decoder"](https://encoding.spec.whatwg.org/#utf-8-decoder) specification.

## Installation

### Requirements

* [Dart SDK](https://dart.dev/get-dart)

### Steps

1. TODO

## Usage

An example of usage is available in the `example` directory.

## Contributing

Tests are available in the `test` directory.

Before publishing a package:

* Add version info in `CHANGELOG.md`
* Do `dart analyze`
* Do `dart format .`
* Do `dart pub outdated`
* Do `dart pub publish --dry-run`
* Use [pana](https://pub.dev/help/scoring#calculating-pub-points-prior-to-publishing)

## Also were used

For tests were used:

* [UTF-8 encoded sample plain-text file](https://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-demo.txt)
* [UTF-8 decoder capability and stress test](https://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt)

## License

[SPDX: MIT No Attribution](https://spdx.org/licenses/MIT-0.html)

---

[Make a README](https://www.makeareadme.com/)
