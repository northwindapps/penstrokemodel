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
    

    // Dependency Injection through initializer
    init(dataManager: DataManagerProtocol,annotation: String = "") {
        self.dataManager = dataManager
        self.annotation = annotation
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            
            //addData
            DataManagerRepository.shared.addDataManager(self.copyDataManager() as! SharedDataManager)
            
            //sumAllData
            let aggregatedData = DataManagerRepository.shared.sumAllData()
            // Print aggregated data
            print("Data Count: \(aggregatedData.count)")
            self.deleteData()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            //print("Touch cancelled at: \(location)")
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
    
}
