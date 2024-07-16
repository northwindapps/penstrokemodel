import TensorFlowLite
import Foundation

class StrokeModelHandler {
    private var interpreter: Interpreter?
    let labels = ["f", "i", "j", "k", "p", "t", "x", "y"]
    let labels_1stroke = ["a", "b", "bksla", "c", "d", "e", "g", "h", "hl", "j", "l", "m", "n", "o", "opb", "q", "r", "s", "sla", "u", "v","vl",  "vl3","w", "z"]

    init(modelName: String) {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            fatalError("Failed to load model file.")
        }
        
        do {
            self.interpreter = try Interpreter(modelPath: modelPath)
        } catch {
            print("Error initializing interpreter: \(error)")
        }
    }
    
    func performPrediction2(pre_x: [Float], pre_y: [Float], pre_time: [Float], maxLength: Int) -> (String, Float)? {

        let inputData = preprocessInputData(xCoordinates: pre_x, yCoordinates: pre_y, timeStamps: pre_time)
        
        if let predictions = predict(inputData: inputData, maxLength: maxLength) {
            if let maxIndex = indexOfMax(predictions), let maxValue = maxValue(predictions) {
                return (labels[maxIndex], maxValue)
            }
        }
        return nil
    }
    
    func performPrediction1stroke(pre_x: [Float], pre_y: [Float], pre_time: [Float], maxLength: Int) -> (String, Float)? {

        let inputData = preprocessInputData(xCoordinates: pre_x, yCoordinates: pre_y, timeStamps: pre_time)
        
        if let predictions = predict(inputData: inputData, maxLength: maxLength) {
            if let maxIndex = indexOfMax(predictions), let maxValue = maxValue(predictions) {
                return (labels_1stroke[maxIndex], maxValue)
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
    
    private func calculateVelocity(x: [Float], y: [Float], timestamps: [Float]) -> [Float] {
        guard x.count > 1 && y.count > 1 && timestamps.count > 1 else {
            print("Insufficient data to calculate velocity. Each input array must have at least 2 elements.")
            return []
        }
        
        var velocity = [Float]()
        
        for i in 0..<(x.count - 1) {
            let delta_x = x[i + 1] - x[i]
            let delta_y = y[i + 1] - y[i]
            let delta_t = timestamps[i + 1] - timestamps[i]
            
            // Avoid division by zero in delta_t
            let delta_t_safe = delta_t == 0 ? 1e-10 : delta_t
            
            let vel = sqrt(pow(delta_x, 2) + pow(delta_y, 2)) / delta_t_safe
            velocity.append(vel)
        }
        
        // Add velocity for the last element as a simple approach
        if x.count == y.count && y.count == timestamps.count {
            velocity.append(0.0) // Or handle this case based on your specific requirements
        }
        
        return velocity
    }
    
    private func calculateVelocity2(x: [Float], y: [Float], timestamps: [Float]) -> (x_vel: [Float], y_vel: [Float]) {
        guard x.count > 1 && y.count > 1 && timestamps.count > 1 else {
            print("Insufficient data to calculate velocity. Each input array must have at least 2 elements.")
            return ([], [])
        }
        
        var x_vel = [Float]()
        var y_vel = [Float]()
        
        for i in 0..<(x.count - 1) {
            let delta_x = x[i + 1] - x[i]
            let delta_y = y[i + 1] - y[i]
            let delta_t = timestamps[i + 1] - timestamps[i]
            
            // Avoid division by zero in delta_t
            let delta_t_safe = delta_t == 0 ? 1e-10 : delta_t
            
            let vel_x = delta_x / delta_t_safe
            let vel_y = delta_y / delta_t_safe
            
            x_vel.append(vel_x)
            y_vel.append(vel_y)
        }
        
        x_vel.append(0.0)
        y_vel.append(0.0)
        
        return (x_vel, y_vel)
    }

    private func preprocessInputData(xCoordinates: [Float], yCoordinates: [Float], timeStamps: [Float]) -> [Float32] {
        guard xCoordinates.count == yCoordinates.count && yCoordinates.count == timeStamps.count else {
            fatalError("Input arrays must have the same length")
        }
        
        let normalizedXCoordinates = minMaxScale(input: xCoordinates)
        let normalizedYCoordinates = minMaxScale(input: yCoordinates)
        let normalizedTimeStamps = minMaxScale(input: timeStamps)
        
        var (vx_ary, vy_ary) = calculateVelocity2(x: normalizedXCoordinates, y: normalizedYCoordinates, timestamps: normalizedTimeStamps)
        
        //get indices
        var zeroIndices = normalizedTimeStamps.indices.filter { normalizedTimeStamps[$0] == 0.0 }
        zeroIndices.removeFirst()
        
        for i in zeroIndices{
            vx_ary[i-1]=0.0
            vy_ary[i-1]=0.0
        }
        

        var inputData: [Float32] = []
        for i in 0..<xCoordinates.count {
            inputData.append(contentsOf: [Float32(normalizedXCoordinates[i]), Float32(normalizedYCoordinates[i]), Float32(normalizedTimeStamps[i]), Float32(vx_ary[i]), Float32(vy_ary[i])])
        }
        return inputData
    }

    private func predict(inputData: [Float32], maxLength: Int) -> [Float32]? {
        guard let interpreter = self.interpreter else {
            fatalError("Interpreter is not initialized.")
        }
        
        do {
            let paddedInputData = padInputData(inputData, toLength: maxLength)
            try interpreter.resizeInput(at: 0, to: [1, maxLength, 5])
            try interpreter.allocateTensors()
            
          
            
            let inputDataBytes = paddedInputData?.withUnsafeBufferPointer { Data(buffer: $0) }
            if inputDataBytes == nil{
                return nil
            }
            try interpreter.copy(inputDataBytes!, toInputAt: 0)
            try interpreter.invoke()
            
            let outputTensor = try interpreter.output(at: 0)
            let outputData: [Float32] = [Float32](unsafeData: outputTensor.data) ?? []
            
            return outputData
            
        } catch {
            print("Error during inference: \(error)")
            return nil
        }
    }

    private func padInputData(_ inputData: [Float32], toLength length: Int) -> [Float32]? {
        let paddingValue: Float32 = 0.0
        let currentLength = inputData.count / 5 // Assuming each entry has x, y, timestamp, and velocity x and y
        let requiredPadding = length - currentLength
        
        var paddedData = inputData
        
        // Check if padding is needed
        guard requiredPadding > 0 else {
            print("No padding required or invalid length specified.")
            return nil
        }
        
        // Pad the data
        for _ in 0..<requiredPadding {
            paddedData.append(contentsOf: [paddingValue, paddingValue, paddingValue, paddingValue, paddingValue]) // Assuming four values per entry x,y,time,velocity
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
