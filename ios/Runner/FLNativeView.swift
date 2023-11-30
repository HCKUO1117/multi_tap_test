import Flutter
import UIKit

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel:FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "multi_touch", binaryMessenger: messenger!)
        super.init()
        // iOS views can be created here
        createNativeView(view: _view)
        
        
        // 添加单指和多指触摸识别器
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                _view.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
                _view.addGestureRecognizer(pinchGestureRecognizer)
        
        
        
    }
    
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            // 处理单指触摸事件
            let location = gestureRecognizer.location(in: _view)
            sendTouchEvent(pointCount: 1, points: [location])
        }
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
            // 处理多指捏合事件
            let pointCount = gestureRecognizer.numberOfTouches
            var points: [CGPoint] = []
            
            for i in 0..<pointCount {
                let location = gestureRecognizer.location(ofTouch: i, in: _view)
                points.append(location)
            }
            
            sendTouchEvent(pointCount: pointCount, points: points)
        }
    
    func sendTouchEvent(pointCount: Int, points: [CGPoint]) {
        let screenBounds = UIScreen.main.bounds

                // 最大 x 坐标
                let maxX = screenBounds.maxX
                print("Max X: \(maxX)")

                // 最大 y 坐标
                let maxY = screenBounds.maxY
                print("Max Y: \(maxY)")
            var touchData: [[String: CGFloat]] = []

            for point in points {
                let touchInfo: [String: CGFloat] = ["x": point.x, "y": point.y]
                touchData.append(touchInfo)
            }

            // 在这里使用 MethodChannel 发送触摸数据给 Flutter
            
        channel.invokeMethod("sendTouchData", arguments: ["pointCount": pointCount, "points": touchData,"size":["x":maxX,"y":maxY],])
        }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView){
        _view.backgroundColor = UIColor.blue.withAlphaComponent(0)
    }
}
