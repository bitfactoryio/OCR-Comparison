//
//  TestPerformance.swift
//  Tests
//
//  Created by Erik Großkopf on 22.06.21.
//

import XCTest
import MLKit
import Vision

class TestPerformance: XCTestCase {
    let imageNames = ["500", "50", "degree_10", "degree_45", "testimage_0", "testimage_1", "testimage_2", "testimage_3"]
    let repetitions = 4
    
    func testPerformanceMLKit() throws {
        let recognizerMLkit = TextRecognizer.textRecognizer()
        let images = [[String]](repeating: imageNames, count: repetitions)
            .flatMap {$0}
            .compactMap { UIImage(named: $0) }
            .compactMap { VisionImage(image: $0) }
        
        let expectation = XCTestExpectation(description: "MLKit OCR")
        let dispatchGroup = DispatchGroup()
        
        print("### Results MLKit ###")
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, image) in images.enumerated() {
                dispatchGroup.wait()
                dispatchGroup.enter()
                
                let start = DispatchTime.now()
                
                recognizerMLkit.process(image) { result, error in
                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                    let timeInterval = Double(nanoTime) / 1_000_000_000
                    print(timeInterval)
                    
                    if index == images.count - 1 {
                        expectation.fulfill()
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        wait(for: [expectation], timeout: 100.0)
    }
    
    func testPerformanceAppleVision() throws {
        let images = [[String]](repeating: imageNames, count: repetitions)
            .flatMap {$0}
            .compactMap { UIImage(named: $0)?.cgImage }
        
        let expectation = XCTestExpectation(description: "Vision OCR")
        
        let dispatchGroup = DispatchGroup()
        
        print("### Results Apple Vision ###")
        for (index, image) in images.enumerated() {
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            let requestHandler = VNImageRequestHandler(cgImage: image)
            
            let start = DispatchTime.now()
            let request = VNRecognizeTextRequest { request, error in
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print(timeInterval)
                
                if index == images.count - 1 {
                    expectation.fulfill()
                }
                
                dispatchGroup.leave()
            }

            _ = try? requestHandler.perform([request])
        }
        
        wait(for: [expectation], timeout: 100.0)
    }
}
