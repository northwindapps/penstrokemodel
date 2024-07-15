//
//  DataInjection.swift
//  penstroke
//
//  Created by yano on 2024/06/30.
//

import Foundation

protocol DataManagerProtocol {
    var timeStamps: [Float] { get set }
    var events: [String] { get set }
    var x_coordinates: [Float] { get set }
    var y_coordinates: [Float] { get set }
    var annotations: [String] { get set }
    var sample_tags: [String] { get set }
    var frame_widths: [String] { get set }
    var frame_heights: [String] { get set }
    var pressures: [String] { get set }
    var maxPressures: [String] { get set }
}

class SharedDataManager: DataManagerProtocol {
    var timeStamps: [Float] = []
    var events: [String] = [] // start, move, end
    var x_coordinates: [Float] = []
    var y_coordinates: [Float] = []
    var annotations: [String] = []
    var sample_tags: [String] = []
    var frame_widths: [String] = []
    var frame_heights: [String] = []
    var pressures: [String] = []
    var maxPressures: [String] = []
}

struct DataEntry: Codable {
    var timeStamps: [Float]
    var events: [String]
    var xCoordinates: [Float]
    var yCoordinates: [Float]
    var pressures: [String]
    var maxPressure: String
    var annotation: String
    var sampleTag: String
    var frameWidth: String
    var frameHeight: String
}

class DataManagerRepository {
    static let shared = DataManagerRepository()
    private var dataManagers: [SharedDataManager] = []
    
    private init() {}
    
    func addDataManager(_ manager: SharedDataManager) {
        dataManagers.append(manager)
    }
    
    func removeDataManager() {
        if !dataManagers.isEmpty {
            dataManagers.removeFirst()
        }
    }
    
    func removeAllDataManager() {
        if !dataManagers.isEmpty {
            dataManagers.removeAll()
        }
    }
    
    func sumAllData() -> [DataEntry] {
        var dataArray: [DataEntry] = []
        
        for manager in dataManagers {
            //no annotations in prediction
            if manager.x_coordinates != [] && manager.y_coordinates != []{
                let entry = DataEntry(
                    timeStamps: manager.timeStamps,
                    events: manager.events,
                    xCoordinates: manager.x_coordinates,
                    yCoordinates: manager.y_coordinates,
                    pressures: manager.pressures,
                    maxPressure: manager.maxPressures.first ?? "",
                    annotation: manager.annotations.first ?? "",
                    sampleTag: manager.sample_tags.first ?? "",
                    frameWidth: manager.frame_widths.first ?? "",
                    frameHeight: manager.frame_heights.first ?? ""
                )
                dataArray.append(entry)
            }
        }
        
        return dataArray
    }
}


//output json format
//{
//  "penStrokes": [
//    {
//      "strokeID": 1,
//      "timeStamps": ["2024-06-30T12:00:00.000Z", "2024-06-30T12:00:00.100Z", "2024-06-30T12:00:00.200Z"],
//      "x_coordinates": [100, 102, 105],
//      "y_coordinates": [200, 202, 205],
//      "pressure": [0.5, 0.6, 0.4],
//      "annotations": "Example stroke 1",
//      "sample_tags": ["tag1", "tag2"],
//      "frame_width": 800,
//      "frame_height": 600
//    },
//    {
//      "strokeID": 2,
//      "timeStamps": ["2024-06-30T12:01:00.000Z", "2024-06-30T12:01:00.100Z", "2024-06-30T12:01:00.200Z"],
//      "x_coordinates": [150, 152, 155],
//      "y_coordinates": [250, 252, 255],
//      "pressure": [0.7, 0.5, 0.3],
//      "annotations": "Example stroke 2",
//      "sample_tags": ["tag3"],
//      "frame_width": 800,
//      "frame_height": 600
//    }
//  ]
//}
//
