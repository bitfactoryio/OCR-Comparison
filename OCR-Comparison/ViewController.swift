//
//  ViewController.swift
//  OCR-Comparison
//
//  Created by Erik Großkopf on 22.06.21.
//

import UIKit
import MLKit
import Vision

class ViewController: UIViewController {
    let textViewMLKit = UITextView()
    
    let textViewVision = UITextView()
    
    let imageNames = ["500", "50", "degree_10", "degree_45", "testimage_0", "testimage_1", "testimage_2", "testimage_3"]
    
    let repitions = 1
    
    let gloablDispatchGroup = DispatchGroup()

    var mlkitTimes: [Double] = [] {
        didSet {
            DispatchQueue.main.async {
                self.textViewMLKit.text = "MLKit performance:\n"
                self.textViewMLKit.text += self.mlkitTimes.map { "\($0) seconds\n" }.joined()
            }
        }
    }
    
    var appleVisionTimes: [Double] = [] {
        didSet {
            DispatchQueue.main.async {
                self.textViewVision.text = "Apple Vision performance:\n"
                self.textViewVision.text += self.appleVisionTimes.map { "\($0) seconds\n" }.joined()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "MLKit vs. Apple Vision"
        
        self.view.addSubview(textViewMLKit)
        self.view.addSubview(textViewVision)

        textViewMLKit.translatesAutoresizingMaskIntoConstraints = false
        textViewVision.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textViewMLKit.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            textViewMLKit.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            textViewMLKit.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            textViewMLKit.leftAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            textViewVision.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            textViewVision.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            textViewVision.rightAnchor.constraint(equalTo: self.view.centerXAnchor),
            textViewVision.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.testAppleVision()
            self.testMLKit()
        }
    }
    
    private func testMLKit() {
        self.gloablDispatchGroup.wait()
        self.gloablDispatchGroup.enter()
        
        let dispatchGroup = DispatchGroup()
        let recognizerMLkit = TextRecognizer.textRecognizer()
        let images = [[String]](repeating: imageNames, count: repitions)
            .flatMap {$0}
            .compactMap { UIImage(named: $0) }
            .compactMap { VisionImage(image: $0) }
        
        for (index, image) in images.enumerated() {
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            let start = DispatchTime.now()
            
            recognizerMLkit.process(image) { result, error in
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000
                let rounded = Double(round(1000 * timeInterval) / 1000)
                self.mlkitTimes.append(rounded)
                dispatchGroup.leave()
                
                if index == images.count - 1 {
                    DispatchQueue.main.async {
                        self.textViewMLKit.text.append("Average: \(self.mlkitTimes.reduce(Double(0), +) / Double(self.mlkitTimes.count))")
                    }
                    self.gloablDispatchGroup.leave()
                }
            }
        }
    }
    
    private func testAppleVision() {
        gloablDispatchGroup.wait()
        gloablDispatchGroup.enter()
        
        let images = [[String]](repeating: imageNames, count: repitions)
            .flatMap {$0}
            .compactMap { UIImage(named: $0)?.cgImage }
        
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            let requestHandler = VNImageRequestHandler(cgImage: image)
            
            let start = DispatchTime.now()
            let request = VNRecognizeTextRequest { request, error in
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000
                let rounded = Double(round(1000 * timeInterval) / 1000)
                self.appleVisionTimes.append(rounded)
                
                if index == images.count - 1 {
                    DispatchQueue.main.async {
                        self.textViewVision.text.append("Average: \(self.appleVisionTimes.reduce(Double(0), +) / Double(self.appleVisionTimes.count))")
                    }
                    self.gloablDispatchGroup.leave()
                }
                
                dispatchGroup.leave()
            }
            
            _ = try? requestHandler.perform([request])
        }
    }
}

