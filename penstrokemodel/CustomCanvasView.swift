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
    var products2: [String]
    var products: [String] {
        didSet {
            //print("Products changed to: \(products)")
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
    private var thirdButton: UIButton?
    private var fourthButton: UIButton?
    private var localTimeStamps: [Float] = []
    private var localXCoordinates: [Float] = []
    private var localYCoordinates: [Float] = []
    //for seconds stroke data
    private var bk_localTimeStamps: [Float] = []
    private var bk_localXCoordinates: [Float] = []
    private var bk_localYCoordinates: [Float] = []


    // Dependency Injection through initializer
    init(dataManager: DataManagerProtocol, annotation: String = "", products: [String] = []) {
        self.dataManager = dataManager
        self.annotation = annotation
        self.products = products
        self.products2 = products
       
        
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
        thirdButton?.removeFromSuperview()
        fourthButton?.removeFromSuperview()

        // Create the first button
        let newFirstButton = UIButton(type: .system)
        newFirstButton.frame = CGRect(x: 0.0, y: location.y + 180, width: 80, height: 25) // Adjust frame as needed
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
        newSecondButton.frame = CGRect(x: 80.0, y: location.y + 180, width: 80, height: 25) // Position 100 points to the right of the first button
        newSecondButton.setTitle("del", for: .normal)
        newSecondButton.backgroundColor = .systemGreen
        newSecondButton.setTitleColor(.white, for: .normal)
        newSecondButton.layer.cornerRadius = 10
        newSecondButton.addTarget(self, action: #selector(buttonTapped2), for: .touchUpInside)

        // Add the second button to the view
        superview?.addSubview(newSecondButton)
        secondButton = newSecondButton
        
        // Create and configure the third button next to the first one
        let newThirdButton = UIButton(type: .system)
        newThirdButton.frame = CGRect(x: 160.0, y: location.y + 180, width: 80, height: 25) // Adjust frame as needed
        newThirdButton.setTitle("?", for: .normal)
        newThirdButton.backgroundColor = .systemYellow
        newThirdButton.setTitleColor(.white, for: .normal)
        newThirdButton.layer.cornerRadius = 10
        newThirdButton.addTarget(self, action: #selector(buttonTapped3), for: .touchUpInside)

        // Add the third button to the view
        superview?.addSubview(newThirdButton)
        thirdButton = newThirdButton
        
        // Create and configure the fourth button
        let newFourthButton = UIButton(type: .system)
        newFourthButton.frame = CGRect(x: 240.0, y: location.y + 180, width: 80, height: 25) // Adjust frame as needed
        newFourthButton.setTitle(":", for: .normal)
        newFourthButton.backgroundColor = .systemRed
        newFourthButton.setTitleColor(.white, for: .normal)
        newFourthButton.layer.cornerRadius = 10
        newFourthButton.addTarget(self, action: #selector(buttonTapped4), for: .touchUpInside)

        // Add the fourth button to the view
        superview?.addSubview(newFourthButton)
        fourthButton = newFourthButton
        }

    @objc func buttonTapped() {
        print("Button was tapped")
        if products.last == " "{
            products.removeLast()
        }
        products.append(".")
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped2() {
        print("Button was tapped")
        if products.count > 0{
            products.removeLast()
        }
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped3() {
        print("Button was tapped")
        products.append("?")
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped4() {
        print("Button was tapped")
        products.append(":")
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startTime = 0
        deleteLocalData()
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            if startTime == 0 {
                startTime = timestamp // set the start time to the timestamp of the first touch
            }
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            
            //store data
//            dataManager.timeStamps.append(Float(relativeTimestamp))
//            dataManager.x_coordinates.append(Float(location.x))
//            dataManager.y_coordinates.append(Float(location.y))
            localTimeStamps.append(Float(relativeTimestamp))
            localXCoordinates.append(Float(location.x))
            localYCoordinates.append(Float(location.y))
        }
    }
    
    

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds
            //print("Touch moved to: \(location), timestamp: \(relativeTimestamp) ms")
            
            localTimeStamps.append(Float(relativeTimestamp))
            localXCoordinates.append(Float(location.x))
            localYCoordinates.append(Float(location.y))
            
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let timestamp = touch.timestamp
            let relativeTimestamp = (timestamp - startTime) * 1000 // convert to milliseconds

            // Store data
            localTimeStamps.append(Float(relativeTimestamp))
            localXCoordinates.append(Float(location.x))
            localYCoordinates.append(Float(location.y))
            gcd()
            // Check for space
//            if abs(end_y_coordinate - location.y) > 100 {
//                if end_x_coordinate != 0.0 {
//                    if products.count > 0 {
//                        let last = products.last!
//                        products.removeLast()
//                        products.append(last + " ")
//                    }
//                }
//            }

            // Perform predictions asynchronously
//            if strokeCounter == 1 {
//                    let rlt = self.performPrediction1stroke(pre_x: self.localXCoordinates, pre_y: self.localYCoordinates, pre_time: self.localTimeStamps)
//                        if (rlt != nil) {
//                            self.deleteLocalData()
//                            self.strokeCounter = 0
//                            //self.drawing = PKDrawing()
//
//                            // Check if the touch is within any button's frame
//                            if let button1 = self.firstButton, button1.frame.contains(location) {
//                                return
//                            }
//                            if let button2 = self.secondButton, button2.frame.contains(location) {
//                                return
//                            }
//                            
//                            products.append(rlt!)
//                            end_x_coordinate = location.x
//                            end_y_coordinate = location.y
//                            showButton(at: location)
//                        }
//                    
//                
//                
//            }
//
//            if strokeCounter == 2 {
//                self.strokeCounter = 0
//                let rlt = self.performPrediction(pre_x: self.localXCoordinates, pre_y: self.localYCoordinates, pre_time: self.localTimeStamps)
//         
//                    self.deleteLocalData()
//                    // Check if the touch is within any button's frame
//                    if let button1 = self.firstButton, button1.frame.contains(location) {
//                        return
//                    }
//                    if let button2 = self.secondButton, button2.frame.contains(location) {
//                        return
//                    }
//                
//                if (rlt != nil){
//                    products.append(rlt!)
//                    end_x_coordinate = location.x
//                    end_y_coordinate = location.y
//                    showButton(at: location)
//                }
//                    
//                
//            }

            
        }
    }
    
    func addToManager() -> [DataEntry]{
        DataManagerRepository.shared.addDataManager(self.copyDataManager() as! SharedDataManager)
        let aggregatedData = DataManagerRepository.shared.sumAllData()
        // Print aggregated data
        print("Data Count: \(aggregatedData.count)")
        return aggregatedData
    }
    
    func gcd(){
        DispatchQueue.global(qos: .background).async {
            print("This is run on a background thread")
            self.dataManager.timeStamps = self.localTimeStamps
            self.dataManager.x_coordinates = self.localXCoordinates
            self.dataManager.y_coordinates = self.localYCoordinates
            let dataRepo = self.addToManager()
            var rlt0:String?
            var v0:Float?
            var rlt:String?
            var v:Float?
            var rlt2:String?
            var v2:Float?
            if dataRepo.count == 1 {
                // Perform predictions asynchronously
                (rlt,v) = self.performPrediction1stroke(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                if rlt != nil{
                    if rlt != "sla" && rlt != "vl" && rlt != "j" && rlt != "hl" && rlt != "bksla" && rlt != "vl3" && rlt != "opb" {
                        self.products2.append(rlt!)
                    }
                    //DataManagerRepository.shared.removeAllDataManager()
                }
            }
            
            if dataRepo.count > 1 {
                // Perform predictions asynchronously
                (rlt0,v0) = self.performPrediction1stroke(pre_x: dataRepo[dataRepo.count-2].xCoordinates, pre_y:dataRepo[dataRepo.count-2].yCoordinates , pre_time: dataRepo[dataRepo.count-2].timeStamps)
                
                (rlt,v) = self.performPrediction1stroke(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                
                if rlt0 == "sla" || rlt0 == "vl" || rlt0 == "j" || rlt0 == "hl" || rlt0 == "bksla" || rlt0 == "vl3" || rlt0 == "opb"{
                    (rlt2,v2) = self.performPrediction(pre_x: dataRepo[dataRepo.count-2].xCoordinates + dataRepo.last!.xCoordinates, pre_y:dataRepo[dataRepo.count-2].yCoordinates + dataRepo.last!.yCoordinates , pre_time: dataRepo[dataRepo.count-2].timeStamps + dataRepo.last!.timeStamps)
                }
                
                if v2 ?? 0 > v ?? 0{
                    self.products2.append(rlt2!)
                }
                
                if v2 ?? 0 < v ?? 0{
                    if rlt != "sla" && rlt != "vl" && rlt != "j" && rlt != "hl" && rlt != "bksla" && rlt != "vl3"{
                        if rlt == "opb"{
                            rlt = "k"
                        }
                        self.products2.append(rlt!)
                    }
                }
                
                
            }
            print("product2", self.products2)

//NG            DispatchQueue.main.async {
//                print("This is run on the main thread")
//                self.products = self.products2
//                
//            }
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
    
    func deleteLocalData(){
        //store data
        localTimeStamps.removeAll()
        localXCoordinates.removeAll()
        localYCoordinates.removeAll()
    }
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> (String?,Float?) {
        if let (label,value) = modelHandler.performPrediction2(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 57) {
            if value > 0.87{
                print("Predicted label: \(label)")
                print("Predicted value: \(value)")
                return (label,value)
                
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label: \(label)")
                print("NG Predicted value: \(value)")
            }
        }else {
            print("Prediction failed")
        }
        return (nil,nil)
    }
    
    func performPrediction1stroke(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> (String?,Float?) {
        if let (label,value) = modelHandler_1stroke.performPrediction1stroke(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 77) {
            if value > 0.87 {
                
                print("Predicted label: \(label)")
                print("Predicted value: \(value)")
                return (label,value)
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
        return (nil,nil)
    }
}
