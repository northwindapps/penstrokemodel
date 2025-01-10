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
                var labelStr = labels[maxIndex]
                var curveCounter = 0
                if labelStr == "1" || labelStr == "(" || labelStr == ")"{
//                if labelStr == "1" || labelStr == ")"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }

                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    //max and min
                    let min_x = xCoordinatesDouble.min() ?? 0.0
                    let max_x = xCoordinatesDouble.max() ?? 0.0
                    let min_y = yCoordinatesDouble.min() ?? 0.0
                    let max_y = yCoordinatesDouble.max() ?? 0.0
                    
                    var min20 = [Float]()
                    var max20 = [Float]()
                    for i in 0..<(xCoordinatesDouble.count) {
                        if (xCoordinatesDouble[i] - min_x) < 10{
                            min20.append(Float(xCoordinatesDouble[i]))
                        }
                        
                        if (max_x - xCoordinatesDouble[i]) < 10{
                            max20.append(Float(xCoordinatesDouble[i]))
                        }
                    }
                    
                    if xCoordinates.count > 1{
                        if max_x - min_x > 20.0 && xCoordinates.first! > Float(min_x) && xCoordinates.last! > Float(min_x){
                            return ("(", maxValue)
                        }
                        
                        if max_x - min_x > 20.0 && xCoordinates.first! < Float(max_x) && xCoordinates.last! < Float(max_x){
                            return (")", maxValue)
                        }
                        
                        let minIdx = xCoordinates.firstIndex(of: Float(min_x))
                        if max_x - min_x > 20.0 && minIdx! > xCoordinates.count/2{
                            return ("j", maxValue)
                        }
                        
                        if Double(min20.count) / Double(xCoordinatesDouble.count) > 0.4 && max_x - min_x > 20.0{
                            
                            if Double(max_y - min_y) / Double(max_x - min_x) < 2.0{
                                return ("C", maxValue)
                            }
                            return ("(", maxValue)
                        }
                        
                        return ("1", maxValue)
                    }
                }
                
                if labelStr == "C"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }

                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    //max and min
                    let min_x = xCoordinatesDouble.min() ?? 0.0
                    let max_x = xCoordinatesDouble.max() ?? 0.0
                    let min_y = yCoordinatesDouble.min() ?? 0.0
                    let max_y = yCoordinatesDouble.max() ?? 0.0
                    
                    var min20 = [Float]()
                    var max20 = [Float]()
                    for i in 0..<(xCoordinatesDouble.count) {
                        if (xCoordinatesDouble[i] - min_x) < 10{
                            min20.append(Float(xCoordinatesDouble[i]))
                        }
                        
                        if (max_x - xCoordinatesDouble[i]) < 10{
                            max20.append(Float(xCoordinatesDouble[i]))
                        }
                    }
                    
                    if xCoordinates.count > 1{
                        if Double(min20.count) / Double(xCoordinatesDouble.count) > 0.4 && max_x - min_x > 20.0{
                            
                            if Double(max_y - min_y) / Double(max_x - min_x) < 2.0{
                                return ("C", maxValue)
                            }
                            return ("(", maxValue)
                        }
                        return ("C", maxValue)
                    }
                }
                
                if labelStr == "7"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }
                    
                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    if xCoordinates.count > 1{
                        //max and min
                        let min_x = xCoordinatesDouble.min() ?? 0.0
                        let max_x = xCoordinatesDouble.max() ?? 0.0
                        let min_y = yCoordinatesDouble.min() ?? 0.0
                        let max_y = yCoordinatesDouble.max() ?? 0.0
                        
                        if max_x - min_x < 20.0 { //25.0{
                            return ("1", maxValue)
                        }
                        
                        if xCoordinates.first! - xCoordinates.last! > 10.0{
                            return (")", maxValue)
                        }
                        
                        if Double(max_y - min_y)/Double(max_x - min_x) > 3{
                            return (")", maxValue)
                        }
                        
                        
                        return ("7", maxValue)
                    }
                }
                
                if labelStr == "L"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }
                    
                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    if yCoordinates.count > 1{
                        //max and min
                        let min_y = yCoordinatesDouble.min() ?? 0.0
                        let max_y = yCoordinatesDouble.max() ?? 0.0
                        var max20 = [Float]()
                        for i in 0..<(yCoordinatesDouble.count) {
                            if max_y - Double(yCoordinates[i]) < 15.0{
                                max20.append(yCoordinates[i])
                            }
                        }
                        if (Double(max20.count) / Double(yCoordinatesDouble.count)) < 0.6 { //25.0{
                            return ("V", maxValue)
                        }
                        
                        return ("L", maxValue)
                    }
                }
                
                if labelStr == "S"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }
                    
                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    if xCoordinates.count > 1{
                        //max and min
                        let min_x = xCoordinatesDouble.min() ?? 0.0
                        let max_x = xCoordinatesDouble.max() ?? 0.0
                        let min_y = yCoordinatesDouble.min() ?? 0.0
                        let max_y = yCoordinatesDouble.max() ?? 0.0
                        
                        
                        if abs(xCoordinates.first! - xCoordinates.last!) < 20.0{
                            return ("(", maxValue)
                        }
                        
                        if Double(max_y - min_y)/Double(max_x - min_x) > 3.0{
                            return ("6", maxValue)
                        }
                        
                        if max_x - min_x < 15.0{
                            return ("6", maxValue)
                        }
                        
                        return ("S", maxValue)
                    }
                }
                if labelStr == "3"{
                    // Convert to Double
                    let xCoordinatesDouble = xCoordinates.compactMap { Double($0) }
                    let yCoordinatesDouble = yCoordinates.compactMap { Double($0) }
                    
                    // Calculate curvature for each set of 3 consecutive points
                    var curvatures: [Double] = []
                    for i in 0..<(xCoordinatesDouble.count - 2) {
                        let curvature = calculateCurvature(
                            x1: xCoordinatesDouble[i], y1: yCoordinatesDouble[i],
                            x2: xCoordinatesDouble[i + 1], y2: yCoordinatesDouble[i + 1],
                            x3: xCoordinatesDouble[i + 2], y3: yCoordinatesDouble[i + 2]
                        )
                        curvatures.append(curvature)
                    }
                    
                    if xCoordinates.count > 1{
                        //max and min
                        let min_x = xCoordinatesDouble.min() ?? 0.0
                        let max_x = xCoordinatesDouble.max() ?? 0.0
                        
                        
                        
                        if xCoordinates.first! - xCoordinates.last! > 25.0{
                            return ("S", maxValue)
                        }
                        return ("3", maxValue)
                    }
                }
                return (labelStr, maxValue)
            }
        }
        return nil
    }
    
    func calculateCurvature(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) -> Double {
        // Calculate the distances between points
        let d1 = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2)) // Distance between P1 and P2
        let d2 = sqrt(pow(x3 - x2, 2) + pow(y3 - y2, 2)) // Distance between P2 and P3
        let d3 = sqrt(pow(x3 - x1, 2) + pow(y3 - y1, 2)) // Distance between P1 and P3

        // Calculate the curvature using the determinant-based formula
        let numerator = 2 * abs((x1 - x2) * (y2 - y3) - (x2 - x3) * (y1 - y2))
        let denominator = d1 * d2 * d3

        // Return curvature
        return denominator != 0 ? numerator / denominator : 0
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
