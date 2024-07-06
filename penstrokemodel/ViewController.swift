import TensorFlowLite

class ViewController: UIViewController {

    var interpreter: Interpreter?
    let labels =  ["a", "b", "c", "d", "e", "f", "h", "i", "j", "k", "m", "n", "o", "p", "q", "r", "t", "u", "v", "w"]

    override func viewDidLoad() {
        super.viewDidLoad()

        let pre_x = [
            "32.5",
            "36.5",
            "37.0",
            "37.5",
            "38.0",
            "39.0",
            "40.5",
            "41.5",
            "42.5",
            "45.0",
            "47.5",
            "48.0",
            "49.0",
            "50.0",
            "51.0",
            "51.5",
            "52.5",
            "53.0",
            "53.5",
            "54.0",
            "54.0",
            "54.0",
            "54.0",
            "54.0",
            "54.0",
            "54.0",
            "54.0",
            "55.0",
            "56.5",
            "58.0",
            "60.0",
            "62.5",
            "67.0",
            "70.5",
            "72.0",
            "74.0",
            "75.0",
            "76.5",
            "77.5",
            "79.5",
            "80.0",
            "81.5",
            "82.5",
            "84.0",
            "86.5",
            "87.0",
            "88.5"
          ]
        
        let pre_y = [
            "55.0",
            "107.0",
            "104.0",
            "100.0",
            "94.0",
            "87.5",
            "80.5",
            "76.0",
            "70.5",
            "62.5",
            "59.5",
            "59.5",
            "59.5",
            "59.5",
            "62.5",
            "67.0",
            "71.5",
            "78.5",
            "82.5",
            "87.5",
            "92.0",
            "95.0",
            "97.5",
            "98.5",
            "99.5",
            "99.0",
            "95.0",
            "84.5",
            "78.0",
            "73.5",
            "68.0",
            "63.5",
            "57.5",
            "55.5",
            "55.5",
            "55.5",
            "56.5",
            "61.0",
            "67.0",
            "72.5",
            "78.0",
            "83.0",
            "88.5",
            "93.0",
            "98.0",
            "100.5",
            "103.0"
            ]
            
        let pre_time = [
            "0.0",
            "149.82637501088902",
            "174.92779166786931",
            "183.14624999766238",
            "191.61845833878033",
            "199.87441669218242",
            "208.35745835211128",
            "216.5300000051502",
            "224.91275001084432",
            "241.3687500229571",
            "258.04237500415184",
            "266.33016669075005",
            "274.6772500104271",
            "282.92050000163727",
            "291.49262502323836",
            "299.55683334264904",
            "307.95700001181103",
            "316.2057083391119",
            "324.5872916886583",
            "332.91912500862963",
            "341.1394583526999",
            "349.505833350122",
            "357.8045416797977",
            "366.12808334757574",
            "374.74175001261756",
            "399.4196249986999",
            "407.7642500051297",
            "424.3907083582599",
            "432.76887500542216",
            "441.28641666611657",
            "449.7490833455231",
            "458.1472083518747",
            "474.5755000039935",
            "491.18191667366773",
            "499.6485416777432",
            "507.89354168227874",
            "516.1154583329335",
            "524.4711666891817",
            "532.6558333472349",
            "541.0804166749585",
            "549.3080416927114",
            "557.5771250005346",
            "565.8927083422896",
            "574.2321250145324",
            "590.8865833480377",
            "599.2378333467059",
            "607.5467083428521"
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


