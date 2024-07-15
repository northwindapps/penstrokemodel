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
    private var end_x_coordinate: CGFloat = 0.0
    private var end_y_coordinate: CGFloat = 0.0
    private var firstButton: UIButton?
    private var secondButton: UIButton?


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
    
    func showButton(at location: CGPoint) {
        // Remove existing buttons if any
        firstButton?.removeFromSuperview()
        secondButton?.removeFromSuperview()

        // Create the first button
        let newFirstButton = UIButton(type: .system)
        newFirstButton.frame = CGRect(x: location.x - 50, y: location.y - 180, width: 50, height: 25) // Adjust frame as needed
        newFirstButton.setTitle(".", for: .normal)
        newFirstButton.backgroundColor = .systemBlue
        newFirstButton.setTitleColor(.white, for: .normal)
        newFirstButton.layer.cornerRadius = 10
        newFirstButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        // Add the first button to the view
        superview?.addSubview(newFirstButton)
        firstButton = newFirstButton

        // Create the second button next to the first one
        let newSecondButton = UIButton(type: .system)
        newSecondButton.frame = CGRect(x: location.x + 0, y: location.y - 180, width: 50, height: 25) // Position 100 points to the right of the first button
        newSecondButton.setTitle("del", for: .normal)
        newSecondButton.backgroundColor = .systemGreen
        newSecondButton.setTitleColor(.white, for: .normal)
        newSecondButton.layer.cornerRadius = 10
        newSecondButton.addTarget(self, action: #selector(buttonTapped2), for: .touchUpInside)

        // Add the second button to the view
        superview?.addSubview(newSecondButton)
        secondButton = newSecondButton
        }

    @objc func buttonTapped() {
        print("Button was tapped")
        if products.last == " "{
            products.removeLast()
        }
        products.append(".")
        // Add your button tap handling logic here
    }
    
    @objc func buttonTapped2() {
        print("Button was tapped")
        if products.last == " "{
            products.removeLast()
        }
        products.removeLast()
        // Add your button tap handling logic here
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
            dataManager.timeStamps.append(Float(relativeTimestamp))
            dataManager.x_coordinates.append(Float(location.x))
            dataManager.y_coordinates.append(Float(location.y))
            
        }
    }
    
    

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            //print("Touch moved to: \(location), timestamp: \(relativeTimestamp) ms")
            
            DispatchQueue.global(qos: .background).async {
                self.dataManager.timeStamps.append(Float(relativeTimestamp))
                self.dataManager.x_coordinates.append(Float(location.x))
                self.dataManager.y_coordinates.append(Float(location.y))
            }
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
            dataManager.timeStamps.append(Float(relativeTimestamp))
            dataManager.x_coordinates.append(Float(location.x))
            dataManager.y_coordinates.append(Float(location.y))
            
            if end_x_coordinate > 0.0 && (abs(end_x_coordinate - location.x) > 80) || (abs(end_y_coordinate) - location.y > 60){
                if products.last != " "{
                    products.append(" ")
                }
            }
            
            if strokeCounter == 1{
                let rlt = performPrediction1stroke(pre_x: dataManager.x_coordinates.compactMap{Float($0)}, pre_y: dataManager.y_coordinates.compactMap{Float($0)}, pre_time: dataManager.timeStamps.compactMap{Float($0)})
                if rlt{
                    self.deleteData()
                    strokeCounter = 0
                    self.drawing = PKDrawing()
                }
            }
            
            if strokeCounter == 2{
                let rlt = performPrediction(pre_x: dataManager.x_coordinates.compactMap{Float($0)}, pre_y: dataManager.y_coordinates.compactMap{Float($0)}, pre_time: dataManager.timeStamps.compactMap{Float($0)})
                self.deleteData()
                strokeCounter = 0
                self.drawing = PKDrawing()
                print(rlt)
            }
                
            // Check if the touch is within any button's frame
            if let button1 = firstButton, button1.frame.contains(location) {
                return
            }
            if let button2 = secondButton, button2.frame.contains(location) {
                return
            }
            
            end_x_coordinate = CGFloat(location.x)
            end_y_coordinate = CGFloat(location.y)
            showButton(at: location)
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
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> Bool {
        if let (label,value) = modelHandler.performPrediction2(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 57) {
            if value > 0.87{
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
        }
        return false
    }
    
    func performPrediction1stroke(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> Bool {
        if let (label,value) = modelHandler_1stroke.performPrediction1stroke(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 77) {
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
