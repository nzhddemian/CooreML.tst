
//  camRec
//
//  Created by Demian on 26/12/2019.
//  Copyright © 2019 Demian Production. All rights reserved.
//

import UIKit
import AVFoundation

import Vision

class ViewContent: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate {
let session = AVCaptureSession()
var label = UILabel()
    let imageView = UIImageView()
    override func viewDidLoad() {
        
        super.viewDidLoad()
       
        self.view.backgroundColor = .black
       //setup label
        label.frame = CGRect(x: 0, y: view.frame.height * 0.9, width: view.frame.width, height: view.frame.height * 0.1)
        label.backgroundColor = .white
        label.textColor = .black
        
        //setup camera capture session
        guard let capDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: capDevice) else {return}
        session.sessionPreset = .photo
        session.addInput(input)
        session.startRunning()
       // let previewCam = AVCaptureVideoPreviewLayer(session: session)
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(dataOutput)
      //  previewCam.frame = self.view.frame
       // self.view.layer.addSublayer(previewCam)
        imageView.frame  = self.view.frame
        self.view.addSubview(imageView)
        //add the label view
        self.view.addSubview(self.label)
        
        
       
        
        
        
    }

     var str = String()
    
    var timer = Timer()
    var orientation: AVCaptureVideoOrientation = .portrait
    
    var utterance = AVSpeechUtterance()
    let context = CIContext()
    //this function to get pixelbuffer from camera session
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        //Unwarp PixelBuffer
        guard let pixels: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        //IMPORTING Model
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        
        
        
        ///Vision ///
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let firstImage = CIImage(cvImageBuffer: pixelBuffer!)
        let cgImage = self.context.createCGImage(firstImage, from: firstImage.extent)
 
        let imgHand = VNImageRequestHandler(cgImage: cgImage!, options: [:])
        let req: VNImageBasedRequest = VNGenerateObjectnessBasedSaliencyImageRequest()   //VNGenerateAttentionBasedSaliencyImageRequest()
        req.revision = VNGenerateObjectnessBasedSaliencyImageRequestRevision1 //VNGenerateAttentionBasedSaliencyImageRequestRevision1
        
        try? imgHand.perform([req])
        guard let result = req.results?.first else {return}
        let observation = result as? VNSaliencyImageObservation
       // else { fatalError("FFF") }
        let pixelBuff = observation?.pixelBuffer
        let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuff!))
        DispatchQueue.main.async {
                let filteredImage = UIImage(cgImage: cgImage!)
                   
                   self.imageView.image = image //filteredImage
                   
               }
        
        
        //get the string from pixelbuffer
        let reqest = VNCoreMLRequest(model: model) { (finishRec, err) in
            guard let results = finishRec.results as? [VNClassificationObservation] else {return}
            guard let firsrtObs = results.first else {return}
            
            //set the string to label
            DispatchQueue.main.async {
                self.label.text = self.str
                }
            self.str = String(firsrtObs.identifier) + "  " + String( Int(firsrtObs.confidence * 100)) + "%"
        }
        //зачем эта штука уже не помню
        try? VNImageRequestHandler(cvPixelBuffer: pixels, options: [:]).perform([reqest])
        
        ///THE VOICE
       utterance = AVSpeechUtterance(string: str)
        let synthesizer = AVSpeechSynthesizer()
               utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = Float.random(in: 0.1...0.5)
    synthesizer.speak(utterance)
              
        
    }
    
    
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
                      
    }

      
}
       
