import TensorFlowLite

class ViewController: UIViewController {

    var interpreter: Interpreter?
    let labels =  ["a", "b", "c", "d", "e", "f", "h", "i", "j", "k", "m", "n", "o", "p", "q", "r", "t", "u", "v", "w"]
    let operationQueue = OperationQueue()
    




    override func viewDidLoad() {
        super.viewDidLoad()

        let pre_x = [
            "44.5",
            "44.0",
            "43.5",
            "43.0",
            "42.5",
            "42.0",
            "40.5",
            "39.0",
            "39.0"
          ]
        
        let pre_y = [
            "67.5",
            "118.0",
            "119.5",
            "119.5",
            "119.5",
            "118.5",
            "113.5",
            "32.0",
            "32.0"
            ]
            
        let pre_time = [
            "0.0",
            "149.80920834932476",
            "166.47162500885315",
            "183.2810000050813",
            "191.46224998985417",
            "199.95974999619648",
            "208.04374999715947",
            "0.0",
            "57.0758750254754"
          ]
        
        // Example usage
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
        
       
        // Start the infinite loop to add operations
        continuouslyAddOperations()

        // Keep the main thread alive to allow background operations to run indefinitely
        RunLoop.main.run()
    }
    
    func continuouslyAddOperations() {
        DispatchQueue.global().async { [self] in
            var operationCount = 1
            while true {
                for i in 1...5 {
                    let currentOperationCount = operationCount
                    operationQueue.addOperation {
                        print("Operation \(i) is running")
                        sleep(2) // Simulate a task taking some time
                        print("Operation \(i) is done")
                    }
                    operationCount += 1
                }
                sleep(1) // Prevent the loop from consuming too much CPU
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


