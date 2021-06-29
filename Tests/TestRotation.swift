//
//  TestRotation.swift
//  Tests
//
//  Created by Erik Großkopf on 22.06.21.
//

import XCTest
import MLKit
import Vision

class TestRotation: XCTestCase {
    
    let expectedText = """
Optical character recognition
or optical character reader
(OCR) is the electronic or
mechanical conversion of
images of typed, handwritten
or printed text into machine-
encoded text, whether from a
scanned document, a photo
of a document, a scene-photo
(for example the text on signs
and billboards in a landscape
photo) or from subtitle text
"""
    
    let imageNames = ["degree_0", "degree_5", "degree_10", "degree_15", "degree_20",
                      "degree_25", "degree_30", "degree_35", "degree_40", "degree_45",
                      "degree_50", "degree_55", "degree_60", "degree_65", "degree_70",
                      "degree_75", "degree_80", "degree_85", "degree_90"]
    
    func testRotationMLKit() throws {
        let recognizerMLkit = TextRecognizer.textRecognizer()
        
        let images = imageNames.compactMap { UIImage(named: $0) }.compactMap { VisionImage(image: $0) }
        XCTAssertEqual(imageNames.count, images.count)
        
        let expectation = XCTestExpectation(description: "MLKit OCR")
        
        let dispatchGroup = DispatchGroup()
        
        print("### Results MLKit ###")
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, image) in images.enumerated() {
                dispatchGroup.wait()
                dispatchGroup.enter()
                
                recognizerMLkit.process(image) { result, error in
                    print("Rotation: \(self.imageNames[index])")
                    print("Levenshtein distance: \(self.expectedText.levenshtein(result!.text))\n")
                    
                    if index == images.count - 1 {
                        expectation.fulfill()
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        wait(for: [expectation], timeout: 100.0)
    }

    func testRotationAppleVision() throws {
        let images = imageNames.compactMap { UIImage(named: $0)?.cgImage }
        XCTAssertEqual(imageNames.count, images.count)

        let expectation = XCTestExpectation(description: "Vision OCR")
        
        let dispatchGroup = DispatchGroup()
        
        print("### Results Apple Vision ###")
        for (index, image) in images.enumerated() {
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            let requestHandler = VNImageRequestHandler(cgImage: image)
            
            let request = VNRecognizeTextRequest { request, error in
                let str = request.results!.compactMap { arr -> String? in
                    return (arr as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                print("Rotation: \(self.imageNames[index])")
                print("Levenshtein distance: \(self.expectedText.replacingOccurrences(of: "\n", with: " ").levenshtein(str))\n")
                
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
