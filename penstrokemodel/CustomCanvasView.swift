//
//  CustomCanvasView.swift
//  penstrokemodel
//
//  Created by yano on 2024/07/06.
//

import UIKit
import PencilKit


class CustomCanvasView: PKCanvasView {
    var startTime: TimeInterval = 0
    private var strokeCounter : Int = 0
    private var dataManager: DataManagerProtocol
    private var annotation: String
    private var prediction_history:[Float] = []
    var modelHandler: StrokeModelHandler!
    var modelHandler_1stroke: StrokeModelHandler!
    var products: [String] {
        didSet {
            print("Products changed to: \(products)")
            if let viewController = window?.rootViewController as? ViewController {
                viewController.updateProductsLabel()
            }
        }
    }
    private var timer: Timer?
    private var prediction_timer: Timer?


    // Dependency Injection through initializer
    init(dataManager: DataManagerProtocol, annotation: String = "", products: [String] = []) {
        self.dataManager = dataManager
        self.annotation = annotation
        self.products = products
       
        
        // Initialize model handler
        modelHandler = StrokeModelHandler(modelName: "pen_stroke_model2strokes")
        modelHandler_1stroke = StrokeModelHandler(modelName: "pen_stroke_model1stroke")
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startTime = 0
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            if startTime == 0 {
                startTime = timestamp // set the start time to the timestamp of the first touch
            }
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            
            //store data
            dataManager.timeStamps.append(String(relativeTimestamp))
            dataManager.events.append("start")
            dataManager.annotations.append(annotation)
            dataManager.sample_tags.append(String(self.tag))
            dataManager.x_coordinates.append("\(location.x)")
            dataManager.y_coordinates.append("\(location.y)")
            dataManager.frame_widths.append("\(self.frame.width)")
            dataManager.frame_heights.append("\(self.frame.height)")

        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            //print("Touch moved to: \(location), timestamp: \(relativeTimestamp) ms")
            
            //store data
            dataManager.timeStamps.append(String(relativeTimestamp))
            dataManager.events.append("move")
            dataManager.annotations.append(annotation)
            dataManager.sample_tags.append(String(self.tag))
            dataManager.x_coordinates.append("\(location.x)")
            dataManager.y_coordinates.append("\(location.y)")
            dataManager.frame_widths.append("\(self.frame.width)")
            dataManager.frame_heights.append("\(self.frame.height)")
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let touch = touches.first {
            strokeCounter += 1
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            //print("Touch ended at: \(location), timestamp: \(relativeTimestamp) ms")
            
            //store data
            dataManager.timeStamps.append(String(relativeTimestamp))
            dataManager.events.append("end")
            dataManager.annotations.append(annotation)
            dataManager.sample_tags.append(String(self.tag))
            dataManager.x_coordinates.append("\(location.x)")
            dataManager.y_coordinates.append("\(location.y)")
            dataManager.frame_widths.append("\(self.frame.width)")
            dataManager.frame_heights.append("\(self.frame.height)")
            
            
            if strokeCounter == 1{
                // Set timer
                let rlt = performPrediction1stroke(pre_x: dataManager.x_coordinates.compactMap{Float($0)}, pre_y: dataManager.y_coordinates.compactMap{Float($0)}, pre_time: dataManager.timeStamps.compactMap{Float($0)})
                if rlt{
                    self.deleteData()
                    strokeCounter = 0
                }
            }
            
            if strokeCounter == 2{
                // Set timer
                performPrediction(pre_x: dataManager.x_coordinates.compactMap{Float($0)}, pre_y: dataManager.y_coordinates.compactMap{Float($0)}, pre_time: dataManager.timeStamps.compactMap{Float($0)})
                self.deleteData()
                strokeCounter = 0
            }
            
            
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
        }
    }
    
    // Configure method to set annotation
    func configure(withAnnotation annotation: String) {
        self.annotation = annotation
    }
    
    func copyDataManager() -> DataManagerProtocol {
        let copy = SharedDataManager()
        copy.timeStamps = self.dataManager.timeStamps
        copy.events = self.dataManager.events
        copy.x_coordinates = self.dataManager.x_coordinates
        copy.y_coordinates = self.dataManager.y_coordinates
        copy.annotations = self.dataManager.annotations
        copy.sample_tags = self.dataManager.sample_tags
        copy.frame_widths = self.dataManager.frame_widths
        copy.frame_heights = self.dataManager.frame_heights
        return copy
    }
    
    func deleteData(){
        //store data
        dataManager.timeStamps.removeAll()
        dataManager.events.removeAll()
        dataManager.annotations.removeAll()
        dataManager.sample_tags.removeAll()
        dataManager.x_coordinates.removeAll()
        dataManager.y_coordinates.removeAll()
        dataManager.frame_widths.removeAll()
        dataManager.frame_heights.removeAll()
    }
    
    private func handleTimer(prex: [String], prey: [String], pretime:[String], event:[String]) {
        
    }
    
    private func cancelTimer() {
        prediction_timer?.invalidate()
        prediction_timer = nil
        print("timer canceled")
    }
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float]) {
        if let (label,value) = modelHandler.performPrediction2(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 57) {
            if value > 0.87{
                products.append(label)
                print("Predicted label: \(label)")
                print("Predicted value: \(value)")
                return
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label: \(label)")
                print("NG Predicted value: \(value)")
            }
        }else {
            print("Prediction failed")
            //DataManagerRepository.shared.removeAllDataManager()
        }
        //DataManagerRepository.shared.removeAllDataManager()
    }
    
    func performPrediction1stroke(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> Bool {
        if let (label,value) = modelHandler_1stroke.performPrediction1stroke(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 55) {
            if value > 0.87 && label != "-" && label != "＼" && label != "|2" && label != "|"{
                products.append(label)
                print("Predicted label: \(label)")
                print("Predicted value: \(value)")
                return true
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label: \(label)")
                print("NG Predicted value: \(value)")
            }
        }else {
            print("Prediction failed")
            //DataManagerRepository.shared.removeAllDataManager()
        }
        return false
    }
}
