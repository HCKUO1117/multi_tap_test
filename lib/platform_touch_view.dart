import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sized_context/sized_context.dart';

const String viewType = 'multi_touch';

///從Y軸每行有幾個點位
const List<int> yFormat = [2];

///從X軸每列有幾個點位
const List<int> xFormat = [1, 1];

///精確度
const double accuracy = 0.01;

///誤差
const double difference = 0.01;

///每隔寬度(cm)
const double columnSize = 0.5;

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

  double realHeight = 0;
  double realWidth = 0;

  @override
  void initState() {
    platform.setMethodCallHandler((call) async {
      print(call.arguments);
      verify(call.arguments);
    });

    super.initState();
  }

  void getScreenRealSize(BuildContext context) {
    // var mediaQuery = MediaQuery.of(context);
    // var devicePixelRatio = mediaQuery.devicePixelRatio;
    //
    // realHeight = mediaQuery.size.height * devicePixelRatio;
    // realWidth = mediaQuery.size.width * devicePixelRatio;

    Size sizeInches = context.sizeInches;

    realHeight = sizeInches.height * 2.54;
    realWidth = sizeInches.width * 2.54;

    print(realWidth);
    print(realHeight);
  }

  @override
  Widget build(BuildContext context) {
    getScreenRealSize(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('寬：$realWidth cm \n 高：$realHeight cm'),
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
      maxX: size.x,
      maxY: size.y,
      accuracy: accuracy,
    );
    //從x軸驗證
    bool xCheck = checkDataFit(
      sample: xFormat,
      value: offsetList.map((e) => e.x).toList(),
      maxX: size.x,
      maxY: size.y,
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
    required double maxX,
    required double maxY,
    required double accuracy,
  }) {
    List<int> distribution = [];
    int process = 0;
    value.sort((a, b) => a.compareTo(b));

    ///誤差值
    double deviation = maxX * accuracy;

    ///若要納入實際寬度
    // if (realWidth != 0) {
    //   deviation = columnSize * maxX / realWidth;
    // }

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
