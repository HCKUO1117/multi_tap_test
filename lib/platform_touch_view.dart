import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String viewType = 'multi_touch';

///從Y軸每行有幾個點位
const List<int> yFormat = [2];

///從X軸每列有幾個點位
const List<int> xFormat = [1, 1];

///精確度
const double accuracy = 0.01;

///有幾個點
const int totalPoints = 2;

class PlatformTouchView extends StatefulWidget {
  const PlatformTouchView({Key? key}) : super(key: key);

  @override
  State<PlatformTouchView> createState() => _PlatformTouchViewState();
}

class _PlatformTouchViewState extends State<PlatformTouchView> {
  static const platform = MethodChannel(viewType);

  bool verified = false;

  @override
  void initState() {
    platform.setMethodCallHandler((call) async {
      print(call.arguments);
      verify(call.arguments);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // const Icon(Icons.ac_unit),
        Builder(builder: (c) {
          if (verified) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    verified = false;
                  });
                },
                child: const Text('重新驗證'),
              ),
            );
          }
          if (Platform.isAndroid) {
            return const AndroidView(viewType: viewType);
          } else {
            return const UiKitView(viewType: viewType);
          }
        })
      ],
    );
  }

  void verify(dynamic arguments) {
    if (verified) return;
    List<OffsetModel> offsetList = [];
    OffsetModel size = OffsetModel(x: 0, y: 0);

    ///資料轉換
    if (Platform.isAndroid) {
      try {
        Map<Object?, Object?> raw = arguments;
        size = OffsetModel.fromMap(arguments['size']);
        raw.forEach((key, value) {
          if (key != 'size') {
            offsetList.add(OffsetModel.fromMap(value));
          }
        });
      } catch (e) {
        print(e);
        return;
      }
    } else {
      try {
        List<dynamic> raw = arguments['points'];
        size = OffsetModel.fromMap(arguments['size']);
        for (var element in raw) {
          offsetList.add(OffsetModel.fromMap(element));
        }
      } catch (e) {
        print(e);
        return;
      }
    }

    if (offsetList.length != totalPoints) return;

    //從y軸驗證
    bool yCheck = checkDataFit(
      sample: yFormat,
      value: offsetList.map((e) => e.y).toList(),
      maxSize: size.y,
      accuracy: accuracy,
    );
    //從x軸驗證
    bool xCheck = checkDataFit(
      sample: xFormat,
      value: offsetList.map((e) => e.x).toList(),
      maxSize: size.x,
      accuracy: accuracy,
    );
    print('x: $xCheck,y:$yCheck');

    if (yCheck && xCheck) {
      setState(() {
        verified = true;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('驗證成功')));
    }
  }

  bool checkDataFit({
    required List<int> sample,
    required List<double> value,
    required double maxSize,
    required double accuracy,
  }) {
    List<int> distribution = [];
    int process = 0;
    value.sort((a, b) => a.compareTo(b));

    ///誤差
    double deviation = maxSize * accuracy;

    for (int i = 0; i < totalPoints; i++) {
      if (i == process) {
        distribution.add(1);
        process++;
        for (int j = i + 1; j < totalPoints; j++) {
          if (checkSameGroup(
              main: value[i], compare: value[j], deviation: deviation)) {
            distribution.last++;
            process = j + 1;
          }
        }
      }
    }

    if (sample.length == distribution.length) {}
    return listEquals(sample, distribution);
  }

  bool checkSameGroup({
    required double main,
    required double compare,
    required double deviation,
  }) {
    return compare >= main - deviation && compare <= main + deviation;
  }
}

class OffsetModel {
  double x;
  double y;

  OffsetModel({
    required this.x,
    required this.y,
  });

  factory OffsetModel.fromMap(dynamic map) {
    return OffsetModel(
        x: double.parse(map['x'].toString()),
        y: double.parse(map['y'].toString()));
  }
}
