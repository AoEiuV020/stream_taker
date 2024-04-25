// ignore_for_file: avoid_print

import 'dart:async';

import 'package:stream_taker/stream_taker.dart';
import 'package:test/test.dart';


void main() {
  test('stream take multi times', () async {
    List<int> list;
    Stream<int> intStream;

    intStream = createStream(10);
    list = await takeFromStream(intStream, 1);
    expect([0], list);
    await Future.delayed(Duration(seconds: 1));
    try {
      // 普通Stream无法重复监听，也就无法重复take,
      list = await takeFromStream(intStream, 2);
      throw Error();
    } on StateError catch (e) {
      expect('Stream has already been listened to.', e.message);
    }

    intStream = createStream(10).asBroadcastStream();
    list = await takeFromStream(intStream, 1);
    expect([0], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 2);
    // 数据已经跑完了，
    expect([], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 3);
    expect([], list);

    intStream = Stream<int>.fromIterable(List.generate(10, (index) => index));
    list = await takeFromStream(intStream, 1);
    expect([0], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 2);
    // 这种可以多次监听并且每次都是新的，
    expect([0, 1], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 3);
    expect([0, 1, 2], list);

    intStream = Stream<int>.fromIterable(List.generate(10, (index) => index))
        .asBroadcastStream();
    list = await takeFromStream(intStream, 1);
    expect([0], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 2);
    // 经过Broadcast就是统一的逻辑了，
    expect([], list);
    await Future.delayed(Duration(seconds: 1));
    list = await takeFromStream(intStream, 3);
    expect([], list);
  });
  test('stream split', () async {
    List<int> list;
    StreamTaker<int> streamSplit;

    streamSplit = StreamTaker(createStream(5));
    list = await streamSplit.take(1).toList();
    expect([0], list);
    await Future.delayed(Duration(seconds: 1));
    list = await streamSplit.take(2).toList();
    expect([1, 2], list);
    await Future.delayed(Duration(seconds: 1));
    list = await streamSplit.take(3).toList();
    // 只剩两个，就只得到两个，
    expect([3, 4], list);
  });
}

Stream<int> createStream(int count) async* {
  for (var i = 0; i < count; i++) {
    yield i;
  }
}

Future<List<T>> takeFromStream<T>(Stream<T> stream, int count) async {
  List<T> result = [];
  await stream.take(count).forEach((item) {
    result.add(item);
  });
  return result;
}
