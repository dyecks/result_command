import 'dart:async';

import 'package:flutter/foundation.dart';

extension ValueListenableToStream on ValueListenable {
  Stream toStream() {
    late final StreamController controller;

    listener() {
      controller.add(value);
    }

    controller = StreamController(
        onListen: () {
          controller.add(value);
          addListener(listener);
        },
        onCancel: () {
          removeListener(listener);
          controller.close();
        },
        sync: true);

    return controller.stream;
  }
}
