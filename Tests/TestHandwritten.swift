//
//  TestHandwritten.swift
//  Tests
//
//  Created by Erik Großkopf on 22.06.21.
//

import XCTest
import MLKit
import Vision

struct TestImage {
    let imageName: String
    let expectedText: String
}

class TestHandwritten: XCTestCase {
    let testArray: [TestImage] = [TestImage(imageName: "handwritten_0", expectedText: "An apple a day, keeps the doctor away."),
                                  TestImage(imageName: "handwritten_1", expectedText: "Wer keine Lösung hat, braucht auch keine Probleme."),
                                  TestImage(imageName: "handwritten_2", expectedText: "Detecting handwritten text is hard!"),
                                  TestImage(imageName: "handwritten_3", expectedText: "Testing OCR in 2021")]
    
    func testHandwrittenMLKit() throws {
        let recognizerMLkit = TextRecognizer.textRecognizer()
        let images = testArray.compactMap { UIImage(named: $0.imageName) }.compactMap { VisionImage(image: $0) }
        let expectation = XCTestExpectation(description: "MLKit OCR")
        var distanceCounter = 0
        
        let dispatchGroup = DispatchGroup()

        print("### Results MLKit ###")
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, image) in images.enumerated() {
                dispatchGroup.wait()
                dispatchGroup.enter()
                
                recognizerMLkit.process(image) { result, error in
                    guard let text = result?.text else {
                        dispatchGroup.leave()
                        return
                    }

                    print("Detected Text: '\(text)'\n Expected Text: '\(self.testArray[index].expectedText)'")
                    
                    let levenshteinDistance = self.testArray[index].expectedText.levenshtein(text)
                    print("Levenshtein distance: \(levenshteinDistance)\n")
                    distanceCounter += levenshteinDistance
                    
                    if index == images.count - 1 {
                        expectation.fulfill()
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        wait(for: [expectation], timeout: 100.0)
        print("Average Levenshtein distance: \(Float(distanceCounter) / Float(testArray.count))\n")
    }
    
    func testHandwrittenAppleVision() throws {
        let images = testArray.compactMap { UIImage(named: $0.imageName)?.cgImage }
    
        let expectation = XCTestExpectation(description: "Vision OCR")
        
        let dispatchGroup = DispatchGroup()
        
        var distanceCounter = 0
        
        print("### Results Apple Vision ###")
        for (index, image) in images.enumerated() {
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            let requestHandler = VNImageRequestHandler(cgImage: image)
            
            let request = VNRecognizeTextRequest { request, error in
                guard
                    let text = request.results?.reduce("", { result, current in
                        guard let observation = current as? VNRecognizedTextObservation else { return result }
                        
                        return (result ?? "") + (observation.topCandidates(1).first?.string ?? "")
                    })
                else {
                    dispatchGroup.leave()
                    return
                }
                
                print("Detected Text: '\(text)'\n Expected Text: '\(self.testArray[index].expectedText)'")
                let levenshteinDistance = self.testArray[index].expectedText.levenshtein(text)
                distanceCounter += levenshteinDistance
                print("Levenshtein distance: \(levenshteinDistance)\n")
                
                if index == images.count - 1 {
                    expectation.fulfill()
                }
                
                dispatchGroup.leave()
            }
            
            _ = try? requestHandler.perform([request])
        }
        
        wait(for: [expectation], timeout: 100.0)
        print("Average Levenshtein distance: \(Float(distanceCounter) / Float(testArray.count))\n")
    }
}
