import TensorFlowLite
import Foundation

class StrokeModelHandler {
    private var interpreter: Interpreter?
    let labels =   ["0","1","V","U","L","W","6","(",")","S","N","M","2","3","6","7","8","9","C","O"]
    
    //["a", "b", "c", "d", "e", "f", "h", "i", "j", "k", "m", "n", "o", "p", "q", "r", "t", "u", "v", "w"]

    init(modelName: String) {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            fatalError("Failed to load model file.")
        }
        
        do {
            self.interpreter = try Interpreter(modelPath: modelPath)
            try self.interpreter!.allocateTensors()
            
        } catch {
            print("Error initializing interpreter: \(error)")
        }
    }
    
    func performPrediction(pre_x: [Float], pre_y: [Float], maxLength: Int) -> (String, Float)? {
        let xCoordinates: [Float] = pre_x
        let yCoordinates: [Float] = pre_y

        let inputData = preprocessInputData(xCoordinates: xCoordinates, yCoordinates: yCoordinates)
        if let predictions = predict(inputData: inputData, maxLength: maxLength) {
            if let maxIndex = indexOfMax(predictions), let maxValue = maxValue(predictions) {
                print("maxIndex",maxIndex)
                return (labels[maxIndex], maxValue)
            }
        }
        return nil
    }

    private func indexOfMax(_ array: [Float32]) -> Int? {
        return array.enumerated().max(by: { $0.element < $1.element })?.offset
    }

    private func maxValue(_ array: [Float32]) -> Float32? {
        return array.max()
    }

    private func minMaxScale(input: [Float]) -> [Float] {
        let minVal = input.min()!
        let maxVal = input.max()!
        return input.map { ($0 - minVal) / (maxVal - minVal) }
    }

    private func preprocessInputData(xCoordinates: [Float], yCoordinates: [Float]) -> [Float32] {
        guard xCoordinates.count == yCoordinates.count else {
            fatalError("Input arrays must have the same length")
        }
        
        let normalizedXCoordinates = minMaxScale(input: xCoordinates)
        let normalizedYCoordinates = minMaxScale(input: yCoordinates)
        //let normalizedTimeStamps = minMaxScale(input: timeStamps)
        
        //var (vx_ary, vy_ary) = calculateVelocity2(x: normalizedXCoordinates, y: normalizedYCoordinates, timestamps: normalizedTimeStamps)
        

        var inputData: [Float32] = []
        for i in 0..<xCoordinates.count {
            inputData.append(contentsOf: [Float32(normalizedXCoordinates[i]), Float32(normalizedYCoordinates[i])])
        }
        return inputData
    }

    func predict(inputData: [Float32], maxLength: Int) -> [Float32]? {
        guard let interpreter = self.interpreter else {
            fatalError("Interpreter is not initialized.")
        }
        
        do {
            let inputTensor = try interpreter.input(at: 0)
                let shape = inputTensor.shape
                print("Expected input shape: \(shape)")
            
            // Step 1: Padding the input data to match the expected model input shape
//            var dummyData = createDummyData(maxLength: maxLength)
            let paddedInputData = padInputData(inputData, toLength: maxLength)
            
            // Step 2: Resizing the input tensor to match the required shape (e.g., [1, maxLength, 2])
            try interpreter.resizeInput(at: 0, to: [1, maxLength, 2])  // Adjust for your model's expected shape
            
            // Step 3: Allocate tensors (make sure this is called after input resize)
            try interpreter.allocateTensors()
            
            // Debugging input data
//            print("Input data shape: \(paddedInputData!.count)")  // Check size
//            print("Padded input data: \(paddedInputData)")  // Print padded data for verification

            // Ensure that paddedInputData is of the correct size
            let inputDataBytes = paddedInputData!.withUnsafeBufferPointer { Data(buffer: $0) }
//            print("Input Data Bytes: \(inputDataBytes)")  // Check if data is being correctly passed

            
            // Step 5: Copy the input data into the model's input tensor
            try interpreter.copy(inputDataBytes, toInputAt: 0)
            
            try interpreter.allocateTensors()
            
            // Step 6: Run inference
            try interpreter.invoke()
            
            // Step 7: Retrieve the output tensor
            let outputTensor = try interpreter.output(at: 0)
            
            // Step 8: Copy the output data to a buffer
            let outputSize = outputTensor.shape.dimensions.reduce(1, { x, y in x * y })
            let outputData = UnsafeMutableBufferPointer<Float32>.allocate(capacity: outputSize)
            
            // Step 9: Copy the output tensor data to the buffer
            outputTensor.data.copyBytes(to: outputData)
            
            // Step 10: Convert the output data into a usable format (if needed)
            let resultData = Array(outputData)
            
            return resultData
            
        } catch {
            print("Error during inference: \(error)")
            return nil
        }
    }
    
    // Create dummy data with random values (2 features per time step)
    func createDummyData(maxLength: Int) -> [Float32] {
        // Generate dummy data with random values between 0 and 1
        var dummyData: [Float32] = []
        
        for _ in 0..<maxLength {
            let x = Float32.random(in: 0...1)
            let y = Float32.random(in: 0...1)
            dummyData.append(x)
            dummyData.append(y)
        }
        
        return dummyData
    }


    private func padInputData(_ inputData: [Float32], toLength length: Int) -> [Float32]? {
        let paddingValue: Float32 = 0.0
        let currentLength = inputData.count / 2 // Assuming each entry has x, y
        let requiredPadding = length - currentLength
        
        var paddedData = inputData
        
        // Check if padding is needed
        guard requiredPadding > 0 else {
            print("No padding required or invalid length specified.")
            return paddedData
        }
        
        // Pad the data
        for _ in 0..<requiredPadding {
            paddedData.append(contentsOf: [paddingValue, paddingValue]) // Assuming four values per entry x,y,time,velocity
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
