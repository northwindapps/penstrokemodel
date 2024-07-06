import UIKit
import TensorFlowLite
import PencilKit

class ViewController: BaseController, PKCanvasViewDelegate,PKToolPickerObserver , UIGestureRecognizerDelegate, UITextViewDelegate {

    var canvasView: CustomCanvasView!
    var toolPicker: PKToolPicker!
    var interpreter: Interpreter?
    let labels =  ["a", "b", "c", "d", "e", "f", "h", "i", "j", "k", "m", "n", "o", "p", "q", "r", "t", "u", "v", "w"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create PKCanvasView
        canvasView = CustomCanvasView(dataManager: SharedDataManager())
               
        // Set the frame for canvasView
        canvasView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        self.view.addSubview(canvasView)
        
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = true
        configureCanvas()
       
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(self)
        canvasView.becomeFirstResponder()

        
    }
    
    func configureCanvas() {
        let penTool = PKInkingTool(.pen, color: .black, width: 1) // Adjust width as needed
        canvasView.tool = penTool
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        
        // Set other canvas configurations
        if #available(iOS 14.0, *) {
            canvasView.drawingPolicy = .anyInput
        }
        canvasView.allowsFingerDrawing = true
        canvasView.addObserver(self, forKeyPath: "tool", options: .new, context: nil)
    }
    
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "tool" {
            // Handle tool change
            if let newTool = change?[.newKey] as? PKTool {
                print("Tool changed to:", newTool)
                // Do something with the new tool
            }
        }
    }
    
    
    func performPrediction(pre_x:[Float],pre_y:[Float],pre_time:[Float]){
        let xCoordinates: [Float] = pre_x.compactMap { Float($0) }
        let yCoordinates: [Float] = pre_y.compactMap { Float($0) }
        let timeStamps: [Float] = pre_time.compactMap { Float($0) }
        
        let inputData = preprocessInputData(xCoordinates: xCoordinates, yCoordinates: yCoordinates, timeStamps: timeStamps)
        if let predictions = predict(inputData: inputData, maxLength: 92) {
            print("Predictions: \(predictions)")
            
            if let maxIndex = indexOfMax(predictions) {
                print("Index of maximum value:", maxIndex)
                print(labels[maxIndex])
            }
            
        }
    }
    
    func indexOfMax(_ array: [Float32]) -> Int? {
        return array.enumerated().max(by: { $0.element < $1.element })?.offset
    }
    
    func minMaxScale(input: [Float]) -> [Float] {
        let minVal = input.min()!
        let maxVal = input.max()!
        let scaledInput = input.map { (val) -> Float in
            return (val - minVal) / (maxVal - minVal)
        }
        return scaledInput
    }

    
    func preprocessInputData(xCoordinates: [Float], yCoordinates: [Float], timeStamps: [Float]) -> [Float32] {
        // Ensure all arrays have the same length
        guard xCoordinates.count == yCoordinates.count && yCoordinates.count == timeStamps.count else {
            fatalError("Input arrays must have the same length")
        }
        
        // Example of scaling xCoordinates using minMaxScale function
        let normalizedXCoordinates = minMaxScale(input: xCoordinates)
        let normalizedYCoordinates = minMaxScale(input: yCoordinates)
        let normalizedTimeStamps = minMaxScale(input: timeStamps)

       
        // Combine the data into a single array
        var inputData: [Float32] = []
        for i in 0..<xCoordinates.count {
            inputData.append(contentsOf: [Float32(normalizedXCoordinates[i]), Float32(normalizedYCoordinates[i]), Float32(normalizedTimeStamps[i])])
        }

        return inputData
    }
    
    func predict(inputData: [Float32], maxLength: Int) -> [Float32]? {
        guard let modelPath = Bundle.main.path(forResource: "pen_stroke_model", ofType: "tflite") else {
            fatalError("Failed to load model file.")
        }
        
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            
            // Ensure input data shape matches model's expected shape
            let paddedInputData = padInputData(inputData, toLength: maxLength)
            let expectedInputShape = Tensor.Shape([1, maxLength, 3])  // Example shape, adjust as per your model
            
            try interpreter.resizeInput(at: 0, to: [1, maxLength, 3]) // In array form
            
            // Allocate tensors
            try interpreter.allocateTensors()
            
            // Convert input data to Data
            let inputDataBytes = paddedInputData.withUnsafeBufferPointer { Data(buffer: $0) }
            
            // Copy input data to input tensor
            try interpreter.copy(inputDataBytes, toInputAt: 0)
            
            // Run inference
            try interpreter.invoke()
            
            // Get output tensor
            let outputTensor = try interpreter.output(at: 0)
            
            // Copy the output data
            let outputData: [Float32] = [Float32](unsafeData: outputTensor.data) ?? []

            return outputData
            
        } catch {
            print("Error during inference: \(error)")
            return nil
        }
    }
    
    func padInputData(_ inputData: [Float32], toLength length: Int) -> [Float32] {
        let paddingValue: Float32 = 0.0
        let currentLength = inputData.count / 3
        let requiredPadding = length - currentLength
        
        var paddedData = inputData
        for _ in 0..<requiredPadding {
            paddedData.append(contentsOf: [paddingValue, paddingValue, paddingValue])
        }
        return paddedData
    }
}
extension Array where Element == Float32 {
    init?(unsafeData: Data) {
        let count = unsafeData.count / MemoryLayout<Float32>.size
        self = unsafeData.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float32>(start: $0.baseAddress!.assumingMemoryBound(to: Float32.self), count: count))
        }
    }
}


