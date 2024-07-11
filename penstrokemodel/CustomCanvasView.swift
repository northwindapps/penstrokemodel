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
        modelHandler = StrokeModelHandler(modelName: "pen_stroke_model_small")
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
            print("touched",timestamp)
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
            dataManager.pressures.append("\(pressure)")

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
            
            
            
            // Set timer
            prediction_timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] timer in
                
                //addData
                //DataManagerRepository.shared.addDataManager(self!.copyDataManager() as! SharedDataManager)
                
//                //sumAllData
//                let aggregatedData = DataManagerRepository.shared.sumAllData()
//                // Print aggregated data
//                print("Data Count: \(aggregatedData.count)")
//                
//                var prex = [String]()
//                var prey = [String]()
//                var pretime = [String]()
//                var pevent = [String]()
//                for sumed in aggregatedData {
//                    prex += sumed.xCoordinates
//                    prey += sumed.yCoordinates
//                    pretime += sumed.timeStamps
//                    pevent += sumed.events
//                }
                self?.handleTimer(prex: self!.dataManager.x_coordinates, prey: self!.dataManager.y_coordinates, pretime: self!.dataManager.timeStamps, event: self!.dataManager.timeStamps)
            }
            
            
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
        }
    }
    
    func addStroke(at points: [CGPoint], with color: UIColor = .black, width: CGFloat = 5.0) {
            let newStroke = createStroke(at: points, with: color, width: width)
            var currentDrawing = self.drawing
            currentDrawing.strokes.append(newStroke)
            self.drawing = currentDrawing
    }
    
    func createStroke(at points: [CGPoint], with color: UIColor = .black, width: CGFloat = 5.0) -> PKStroke {
        let ink = PKInk(.pen, color: color)
        var controlPoints = [PKStrokePoint]()

        for point in points {
            let strokePoint = PKStrokePoint(location: point, timeOffset: 0, size: CGSize(width: width, height: width), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0)
            controlPoints.append(strokePoint)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        let stroke = PKStroke(ink: ink, path: path, transform: .identity, mask: nil)

        return stroke
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
        performPrediction(pre_x: prex.compactMap{Float($0)}, pre_y: prey.compactMap{Float($0)}, pre_time: pretime.compactMap{Float($0)})
        self.deleteData()
    }
    
    private func cancelTimer() {
        prediction_timer?.invalidate()
        prediction_timer = nil
        print("timer canceled")
    }
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float]) {
        let aggregatedData = DataManagerRepository.shared.sumAllData()
//            var x = [Float]()
//            var y = [Float]()
//            var time = [Float]()
//            var r_label = ""
//            var r_value = 0.0 as Float
//            x = aggregatedData[0].xCoordinates.compactMap({ Float($0) })
//            y = aggregatedData[0].yCoordinates.compactMap({ Float($0) })
//            time = aggregatedData[0].timeStamps.compactMap({ Float($0) })
            if let (label,value) = modelHandler.performPrediction(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 38) {
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
