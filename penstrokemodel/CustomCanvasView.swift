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
    var modelHandler_19: StrokeModelHandler!
    var dnaProducts: [String]
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
    private var fifthButton: UIButton?
    private var localTimeStamps: [Float] = []
    private var localXCoordinates: [Float] = []
    private var localYCoordinates: [Float] = []
    //for seconds stroke data
    private var bk_localTimeStamps: [Float] = []
    private var bk_localXCoordinates: [Float] = []
    private var bk_localYCoordinates: [Float] = []
    
    // Define the UILabel
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Your Text Here"
        label.font = UIFont.systemFont(ofSize: 25)
        label.textColor = .black
        label.numberOfLines = 20
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Dependency Injection through initializer
    init(dataManager: DataManagerProtocol, annotation: String = "", products: [String] = []) {
        self.dataManager = dataManager
        self.annotation = annotation
        self.products = products
        self.products2 = products
        self.dnaProducts = products
       
        
        // Initialize model handler
        modelHandler = StrokeModelHandler(modelName: "pen_stroke_model2strokes")
        modelHandler_1stroke = StrokeModelHandler(modelName: "pen_stroke_model1stroke")
        modelHandler_19 = StrokeModelHandler(modelName: "pen_stroke_model19")
        super.init(frame: .zero)
        
        // Add label to the superview
        self.addSubview(label)
        
        // Set constraints for the label
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 16), // Add padding from the top if needed
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16), // Add padding from the left if needed
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16), // Add padding from the right if needed
            label.heightAnchor.constraint(equalToConstant: 600) // Set height to 100 points
        ])
}

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    }

    @objc func timerFired() {
        DispatchQueue.main.async {
            self.products = self.products2
        }
    }
    
    func updateProductsLabel() {
        let joinedString = products2.joined(separator: "")

        var modifiedString = joinedString.replacingOccurrences(of: ".", with: ".\n")
        modifiedString = modifiedString.replacingOccurrences(of: "?", with: "?\n")

        label.text = modifiedString
        //self.drawing = PKDrawing()
    }
    
    func showButton(at location: CGPoint) {
        // Remove existing buttons if any
        firstButton?.removeFromSuperview()
        secondButton?.removeFromSuperview()
        thirdButton?.removeFromSuperview()
        fourthButton?.removeFromSuperview()
        fifthButton?.removeFromSuperview()

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
        
        // Create and configure the fourth button
        let newFifthButton = UIButton(type: .system)
        newFifthButton.frame = CGRect(x: 320.0, y: location.y + 180, width: 80, height: 25) // Adjust frame as needed
        newFifthButton.setTitle("space", for: .normal)
        newFifthButton.backgroundColor = .systemGray
        newFifthButton.setTitleColor(.white, for: .normal)
        newFifthButton.layer.cornerRadius = 10
        newFifthButton.addTarget(self, action: #selector(buttonTapped5), for: .touchUpInside)

        // Add the fourth button to the view
        superview?.addSubview(newFifthButton)
        fifthButton = newFifthButton
        }

    @objc func buttonTapped() {
        print("Button was tapped")
        products2.append(".")
        self.updateProductsLabel()
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped2() {
        print("Button was tapped")
        if products2.count > 0{
            products2.removeLast()
        }
        self.updateProductsLabel()
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped3() {
        print("Button was tapped")
        products2.append("?")
        self.updateProductsLabel()
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped4() {
        print("Button was tapped")
        products2.append(":")
        self.updateProductsLabel()
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }
    
    @objc func buttonTapped5() {
        print("Button was tapped")
        products2.append(" ")
        self.updateProductsLabel()
        deleteLocalData()
        strokeCounter = 0
        self.drawing = PKDrawing()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startTime = 0
        deleteLocalData()
        timer?.invalidate()
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
            showButton(at: location)
            
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
            var rlt1:String?
            var v:Float?
            var rlt2:String?
            var v2:Float?
            
            print("xcount",dataRepo.last?.xCoordinates.count)
            if dataRepo.count == 1 {
                // Perform predictions asynchronously
                if dataRepo.last?.xCoordinates.count ?? 0 < 20{
                    (rlt1,v) = self.performPrediction19(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                }else{
                    (rlt1,v) = self.performPrediction1stroke(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                }
                if rlt1 != nil{
                    //store all outputs on dna
                    self.dnaProducts.append(rlt1!)
                    if rlt1 != "sla" && rlt1 != "vl" && rlt1 != "j" && rlt1 != "hl" && rlt1 != "bksla" && rlt1 != "vl3" && rlt1 != "opb" && rlt1 != "hlbksla" && rlt1 != "vlsla"  {
                        self.products2.append(rlt1!)
                    }
                    //j requires 2 strokes
                    //DataManagerRepository.shared.removeAllDataManager()
                }
            }
            
            if dataRepo.count > 1 {
                
                print("dataRepo[dataRepo.count-2].count",dataRepo[dataRepo.count-2].xCoordinates.count)
                // Perform predictions asynchronously
//                if dataRepo[dataRepo.count-2].xCoordinates.count < 20{
//                    (rlt0,v0) = self.performPrediction19(pre_x: dataRepo[dataRepo.count-2].xCoordinates, pre_y:dataRepo[dataRepo.count-2].yCoordinates , pre_time: dataRepo[dataRepo.count-2].timeStamps)
//                    
//                }
//                
//                if dataRepo[dataRepo.count-2].xCoordinates.count >= 20{
//                    (rlt0,v0) = self.performPrediction1stroke(pre_x: dataRepo[dataRepo.count-2].xCoordinates, pre_y:dataRepo[dataRepo.count-2].yCoordinates , pre_time: dataRepo[dataRepo.count-2].timeStamps)
//                }
                
                print("dataRepo.last?.count",dataRepo.last?.xCoordinates.count)
                
                if dataRepo.last?.xCoordinates.count ?? 0 < 20{
                    (rlt1,v) = self.performPrediction19(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                }
                
                if dataRepo.last?.xCoordinates.count ?? 0 >= 20{
                    (rlt1,v) = self.performPrediction1stroke(pre_x: dataRepo.last!.xCoordinates, pre_y:dataRepo.last!.yCoordinates , pre_time: dataRepo.last!.timeStamps)
                }
                
                
                
                if self.dnaProducts.last == "hlbksla" || self.dnaProducts.last == "vlsla" || self.dnaProducts.last == "j" {
                    (rlt2,v2) = self.performPrediction(pre_x: dataRepo[dataRepo.count-2].xCoordinates + dataRepo.last!.xCoordinates, pre_y:dataRepo[dataRepo.count-2].yCoordinates + dataRepo.last!.yCoordinates , pre_time: dataRepo[dataRepo.count-2].timeStamps + dataRepo.last!.timeStamps)
                    
                    if (rlt2 != nil) {
                        if rlt2 != "hlbksla" && rlt2 != "vlsla"{
                            self.products2.append(rlt2!)
                        }
                        self.dnaProducts.append(rlt2!)
                    }
                }
                
                
                
                
                
                if (rlt2 == nil && rlt1 != nil){
                    if rlt1 != "hlbksla" && rlt1 != "vlsla"{
                        self.products2.append(rlt1!)
                    }
                    self.dnaProducts.append(rlt1!)
                }
                
                
            }
            DispatchQueue.main.async {
                print("product2", self.products2)
                print("dna",self.dnaProducts)
                //self.startTimer()
                self.updateProductsLabel()
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
    
    func deleteLocalData(){
        //store data
        localTimeStamps.removeAll()
        localXCoordinates.removeAll()
        localYCoordinates.removeAll()
    }
    
    
    
    func performPrediction(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> (String?,Float?) {
        if let (label,value) = modelHandler.performPrediction2(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 57) {
            if value > 0.87{
                print("Predicted label2: \(label)")
                print("Predicted value2: \(value)")
                return (label,value)
                
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label2: \(label)")
                print("NG Predicted value2: \(value)")
            }
        }else {
            print("Prediction2 failed")
        }
        return (nil,nil)
    }
    
    func performPrediction1stroke(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> (String?,Float?) {
        if let (label,value) = modelHandler_1stroke.performPrediction1stroke(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 77) {
            if value > 0.87 {
                
                print("Predicted label1: \(label)")
                print("Predicted value1: \(value)")
                return (label,value)
            }
            if value <= 0.87{
                //y,i,j,x.. two-stroke group
                print("NG Predicted label1: \(label)")
                print("NG Predicted value1: \(value)")
            }
        }else {
            print("Prediction1 failed")
            //DataManagerRepository.shared.removeAllDataManager()
        }
        return (nil,nil)
    }
    
    func performPrediction19(pre_x: [Float], pre_y: [Float], pre_time: [Float]) -> (String?,Float?) {
        if let (label,value) = modelHandler_19.performPrediction19(pre_x: pre_x, pre_y: pre_y, pre_time: pre_time, maxLength: 19) {
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
