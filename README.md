# stream_taker
dart Stream.take分多次取数据，

## Features

针对Stream.take无法分多次取数据的问题，单独封装一个类确保只listen一次，take几个就只消费几个，

## Getting started

```dart
dart pub add stream_taker
```

## Usage

[stream_taker_test.dart](./test/stream_taker_test.dart)  
```dart
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
```
