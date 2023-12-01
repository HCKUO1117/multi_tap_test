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
        channel = FlutterMethodChannel(name: "multi_touch", binaryMessenger: messenger!)
        _view = NativeView(methodChannel: channel)
        super.init()
        // iOS views can be created here
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView){
        _view.backgroundColor = UIColor.blue.withAlphaComponent(0)
    }
}

class NativeView: UIView {
    private let channel: FlutterMethodChannel
    private let maxX : CGFloat
    private let maxY : CGFloat
    

    init(methodChannel: FlutterMethodChannel) {
        self.channel = methodChannel
        let screenBounds = UIScreen.main.bounds
        // 最大 x 坐标
        self.maxX = screenBounds.maxX

        // 最大 y 坐标
        self.maxY = screenBounds.maxY
    
        super.init(frame: .zero)
        
        self.isMultipleTouchEnabled = true
        
    }

    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendTouchResult(touches: touches,type: "began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendTouchResult(touches: touches,type: "moved")
    }
    
    func sendTouchResult(touches: Set<UITouch>,type: String){
        
        var touchData: [[String: CGFloat]] = []

        for touch in touches {
            let location = touch.location(in: self)
            let touchInfo: [String: CGFloat] = ["x": location.x, "y": location.y]
            touchData.append(touchInfo)
        }

        channel.invokeMethod("sendTouchData", arguments: [ "points": touchData,"size":["x":maxX,"y":maxY],"type":type])
    }

}

