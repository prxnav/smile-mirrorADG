//
//  ViewController.swift
//  Smile Mirror
//
//  Created by Raj Vishal on 18/06/22.
//

import UIKit
import AVKit
import Vision
import CoreML


func makeGETrequestOn(){
    guard let url = URL(string: "http://192.168.62.156/relay/on") else{
        print("Failed")
        return
    }
    
    print("Making api call...")
    
    var request = URLRequest(url:url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            print("Smile Detected")
        } else if let error = error {
            print("HTTP Request Failed \(error)")
        }
    }

    task.resume()

}


func makeGETrequestOff(){
    guard let url = URL(string: "http://192.168.62.156/relay/off") else{
        print("Failed")
        return
    }
    
    print("Making api call...")
    
    var request = URLRequest(url:url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            print("Smile NOT Detected")
        } else if let error = error {
            print("HTTP Request Failed \(error)")
        }
    }

    task.resume()

}


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        //camera startup
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice =
                AVCaptureDevice.default(for: .video) else {return }
        guard let input = try? AVCaptureDeviceInput(device:captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
     
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        //VNImageRequestHandler(cgImage: CGImage, options : [:]).perform(<#T##requests: [VNRequest]##[VNRequest]#>)
    }
    
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)  {


        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }


        guard let model = try? VNCoreMLModel(for: smile_detection().model)
        else {
            print("Failed")
            return}
        let request = VNCoreMLRequest(model: model)
        {
            (finished, err) in
    
            guard let results = try? finished.results as?
            [VNCoreMLFeatureValueObservation] else {
                return
            }
            
            guard let firstObservation = results.first else
            {return}
            
            let array = firstObservation.featureValue.multiArrayValue!
            
            let threshold = 0.900000
            
            if (Double(array[0]) >= threshold){
                print("Smiling")
                sleep(3)
                makeGETrequestOn()
            }
            else{
                print("Not Smiling")
                sleep(3)
                makeGETrequestOff()
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                              options: [:]).perform([request])

        
    
    
    }
    
    
}


