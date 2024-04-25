import 'dart:async';
import 'dart:collection';

class StreamTaker<T> {
  final Stream<T> stream;
  final Queue<Completer<void Function(T)>> _inputWaiters = Queue();
  final Queue<Completer<T>> _outputWaiters = Queue();
  var started = false;
  var isDone = false;

  StreamTaker(this.stream);

  Stream<T> take(int count) async* {
    if (!started) {
      startListen();
      started = true;
    }
    if (isDone) {
      return;
    }
    for (var i = 0; i < count; i++) {
      try {
        yield await takeOne();
      } on _NoMoreError {
        return;
      }
    }
  }

  void startListen() {
    asyncOperation(stream).listen((event) {}, onDone: done, onError: error);
  }

  void error(e, s) {
    isDone = true;
    for (var output in _outputWaiters) {
      output.completeError(e, s);
    }
  }

  Stream<void> asyncOperation(Stream<T> stream) async* {
    await for (var data in stream) {
      if (_outputWaiters.isNotEmpty) {
        _outputWaiters.removeFirst().complete(data);
        continue;
      }
      final completer = Completer<void Function(T)>();
      _inputWaiters.add(completer);
      final callback = await completer.future;
      callback.call(data);
      yield null;
    }
    done();
  }

  void done() {
    isDone = true;
    for (var output in _outputWaiters) {
      output.completeError(const _NoMoreError());
    }
    _outputWaiters.clear();
  }

  Future<T> takeOne() {
    if (!started) {
      startListen();
      started = true;
    }
    if (isDone) {
      throw const _NoMoreError();
    }
    final completer = Completer<T>();
    if (_inputWaiters.isNotEmpty) {
      _inputWaiters.removeFirst().complete((data) {
        _outputWaiters.remove(completer);
        completer.complete(data);
      });
    }
    _outputWaiters.add(completer);
    return completer.future;
  }
}

class _NoMoreError {
  const _NoMoreError();
}
