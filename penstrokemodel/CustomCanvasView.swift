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
    private var dataManager: DataManagerProtocol
    private var annotation: String
    var modelHandler: StrokeModelHandler!
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
        modelHandler = StrokeModelHandler(modelName: "pen_stroke_modelratio")
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        cancelTimer()
        startTime = 0
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            if startTime == 0 {
                startTime = timestamp // set the start time to the timestamp of the first touch
            }
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            
            
            let pressure = touch.force
            let maximumPossibleForce = touch.maximumPossibleForce
            
            
            if self.traitCollection.forceTouchCapability == .available {
                let normalizedPressure = pressure / maximumPossibleForce
            }
        
            
            //print("tag: \(self.tag)")
            //print("Touch began at: \(location), timestamp: \(relativeTimestamp) ms")
            
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
            //get the stroke length
            var dis = calculateTraveledDistance()
            if let last = Float(dataManager.traveled_distances.last ?? ""){
                dis -= CGFloat(last)
            }
            dataManager.traveled_distances.append("\(dis)")
            
            startTimer()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
        }
    }
    
    func startTimer() {
            prediction_timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    }
    
    @objc func timerFired() {
        print("Timer fired!")
        handleTimer(prex: dataManager.x_coordinates, prey: dataManager.y_coordinates, pretime: dataManager.timeStamps, event: dataManager.events, td: dataManager.traveled_distances)
    }
    
    func calculateTraveledDistance() -> CGFloat {
    // Ensure coordinates arrays are not empty and have the same length
    guard dataManager.x_coordinates.count > 1, dataManager.x_coordinates.count == dataManager.y_coordinates.count else {
            return 0.0
        }
        
        var totalDistance: CGFloat = 0.0
        
        for i in 1..<dataManager.x_coordinates.count {
            if let x1 = Float(dataManager.x_coordinates[i - 1]),
               let y1 = Float(dataManager.y_coordinates[i - 1]),
               let x2 = Float(dataManager.x_coordinates[i]),
               let y2 = Float(dataManager.y_coordinates[i]), dataManager.timeStamps[i] != "0.0" {
                    let dx = CGFloat(x2 - x1)
                    let dy = CGFloat(y2 - y1)
                    let distance = sqrt(dx * dx + dy * dy)
                    totalDistance += distance
                }
        }
        
        return totalDistance
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
        copy.traveled_distances = self.dataManager.traveled_distances
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
        dataManager.traveled_distances.removeAll()
    }
    
    private func handleTimer(prex: [String], prey: [String], pretime:[String], event:[String],td:[String]) {
        performPrediction(pre_x: prex.compactMap{Float($0)}, pre_y: prey.compactMap{Float($0)}, pre_time: pretime.compactMap{Float($0)}, pre_td: td.compactMap{Float($0)})
        self.deleteData()
    }
    
    private func cancelTimer() {
        prediction_timer?.invalidate()
        prediction_timer = nil
        print("timer canceled")
    }
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float], pre_td:[Float]) {
        
        if let (label,value) = modelHandler.performPrediction(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, pre_td: pre_td, maxLength: 34) {
            if value > 0.87{
                //products.removeLast()
                products.append(label)
                print("Predicted label: \(label)")
                print("Predicted value: \(value)")
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label: \(label)")
                print("NG Predicted value: \(value)")
            }

        } else {
            print("Prediction failed")
            DataManagerRepository.shared.removeAllDataManager()
        }
        DataManagerRepository.shared.removeAllDataManager()
    }
}
