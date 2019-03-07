import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    //here is where we put the platform channel thing
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let rustyChannel = FlutterMethodChannel(name: "rust",
                                              binaryMessenger: controller)
    rustyChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: FlutterResult) -> Void in
        //this may need to be converted to swift strings first
        //as they autoconvert once given to the function
        let call_method = String(call.method)
        /*
         https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html
         search 'any'
        */
        //we have to go over this with a switch and append each converted type to a new array
        var call_arguments = "None"
        if let arguments = call.arguments {
            switch arguments {
            case let SomeString as String:
                call_arguments = SomeString
            default:
                call_arguments = "Err"
            }
        } else {
            call_arguments = "None"
        }
        
        let output = transfer_to_rust(call_method: call_method , call_arguments: call_arguments)
        result(output)
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

