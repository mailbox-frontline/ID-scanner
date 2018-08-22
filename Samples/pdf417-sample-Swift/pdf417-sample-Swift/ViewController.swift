//
//  ViewController.swift
//  pdf417-sample-Swift
//
//  Created by Dino on 17/12/15.
//  Copyright © 2015 Dino. All rights reserved.
//

import UIKit
import MicroBlink

class ViewController: UIViewController {
    
    var pdf417Recognizer : MBPdf417Recognizer?
    var barcodeRecognizer : MBBarcodeRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Valid until: 2018-09-27
        MBMicroblinkSDK.sharedInstance().setLicenseResource("pdf417-license", withExtension: "mblic", inSubdirectory: "License", for: Bundle.main)
        
        print("loaded...")
    }
    
    @IBAction func didTapCustomUI(_ sender: Any) {
        
        /** Create barcode recognizer */
        self.barcodeRecognizer = MBBarcodeRecognizer()
        self.barcodeRecognizer?.scanQrCode = true
        
        self.pdf417Recognizer = MBPdf417Recognizer()
        
        /** Crate recognizer collection */
        let recognizerList = [self.barcodeRecognizer!, self.pdf417Recognizer!]
        let recognizerCollection : MBRecognizerCollection = MBRecognizerCollection(recognizers: recognizerList)
        
        /** Create your overlay view controller */
        let customOverlayViewController : CustomOverlay = CustomOverlay.initFromStoryboardWith()
        
        /** This has to be called for custom controller */
        customOverlayViewController.reconfigureRecognizers(recognizerCollection)
        
        /** Create recognizer view controller with wanted overlay view controller */
        let recognizerRunneViewController : UIViewController = MBViewControllerFactory.recognizerRunnerViewController(withOverlayViewController: customOverlayViewController)
        
        /** Present the recognizer runner view controller. You can use other presentation methods as well (instead of presentViewController) */
        self.present(recognizerRunneViewController, animated: true, completion: nil)
    }
    @IBAction func didTapScan(_ sender: AnyObject) {
        
        /** Create barcode recognizer */
        self.barcodeRecognizer = MBBarcodeRecognizer()
        self.barcodeRecognizer?.scanQrCode = true
        
        self.pdf417Recognizer = MBPdf417Recognizer()
        
        /** Create barcode settings */
        let settings : MBBarcodeOverlaySettings = MBBarcodeOverlaySettings()
        
        /** Crate recognizer collection */
        let recognizerList = [self.barcodeRecognizer!, self.pdf417Recognizer!]
        let recognizerCollection : MBRecognizerCollection = MBRecognizerCollection(recognizers: recognizerList)
        
        /** Create your overlay view controller */
        let barcodeOverlayViewController : MBBarcodeOverlayViewController = MBBarcodeOverlayViewController(settings: settings, recognizerCollection: recognizerCollection, delegate: self)
        
        /** Create recognizer view controller with wanted overlay view controller */
        let recognizerRunneViewController : UIViewController = MBViewControllerFactory.recognizerRunnerViewController(withOverlayViewController: barcodeOverlayViewController)
        
        /** Present the recognizer runner view controller. You can use other presentation methods as well (instead of presentViewController) */
        self.present(recognizerRunneViewController, animated: true, completion: nil)
    }
}

extension ViewController: MBBarcodeOverlayViewControllerDelegate {
    
    func barcodeOverlayViewControllerDidFinishScanning(_ barcodeOverlayViewController: MBBarcodeOverlayViewController, state: MBRecognizerResultState) {
        /** This is done on background thread */
        barcodeOverlayViewController.recognizerRunnerViewController?.pauseScanning()
        
        var message: String = ""
        var title: String = ""
        
        if (self.barcodeRecognizer!.result.resultState == MBRecognizerResultState.valid) {
            title = "QR Code"
            
            // Save the string representation of the code
            message = self.barcodeRecognizer!.result.stringData!
        }
        else if (self.pdf417Recognizer!.result.resultState == MBRecognizerResultState.valid) {
            title = "PDF417"
            
            // Save the string representation of the code
            message = self.pdf417Recognizer!.result.stringData!
        }
        
        /** Needs to be called on main thread beacuse everything prior is on background thread */
        DispatchQueue.main.async {
            // present the alert view with scanned results
            
            let alertController: UIAlertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default,
                                                             handler: { (action) -> Void in
                                                                self.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(okAction)
            alertController.addAction(UIAlertAction(title: "View in web app", style: .default, handler: { (action) in
                print("send has been pressed... \(message)")
                let post = Post(id: message)
                self.submitPost(post: post) { (error) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open ( URL(string: "https://mysterious-coast-54797.herokuapp.com/id")!)
                } else {
                    print("cannot load url")
                }
                
            }))
            barcodeOverlayViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func barcodeOverlayViewControllerDidTapClose(_ barcodeOverlayViewController: MBBarcodeOverlayViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func submitPost(post: Post, completion:((Error?) -> Void)?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "mysterious-coast-54797.herokuapp.com"
        urlComponents.path = "/id"
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        
        // Specify this request as being a POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Make sure that we include headers specifying that our request's HTTP body
        // will be JSON encoded
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(post)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            completion?(error)
        }
        
        // Create and run a URLSession data task with our JSON encoded POST request
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                completion?(responseError!)
                return
            }
            
            // APIs usually respond with the data you just sent in your POST request
            if let data = responseData, let utf8Representation = String(data: data, encoding: .utf8) {
                print("response: ", utf8Representation)
            } else {
                print("no readable data received in response")
            }
        }
        task.resume()
    }
}

struct Post: Encodable {
    let id: String
}

