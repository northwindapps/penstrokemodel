//
//  DataInjection.swift
//  penstroke
//
//  Created by yano on 2024/06/30.
//

import Foundation

protocol DataManagerProtocol {
    var timeStamps: [String] { get set }
    var events: [String] { get set }
    var x_coordinates: [String] { get set }
    var y_coordinates: [String] { get set }
    var annotations: [String] { get set }
    var sample_tags: [String] { get set }
    var frame_widths: [String] { get set }
    var frame_heights: [String] { get set }
    var traveled_distances: [String] { get set }
}

class SharedDataManager: DataManagerProtocol {
    var timeStamps: [String] = []
    var events: [String] = [] // start, move, end
    var x_coordinates: [String] = []
    var y_coordinates: [String] = []
    var annotations: [String] = []
    var sample_tags: [String] = []
    var frame_widths: [String] = []
    var frame_heights: [String] = []
    var traveled_distances: [String] = []

}

struct DataEntry: Codable {
    var timeStamps: [String]
    var events: [String]
    var xCoordinates: [String]
    var yCoordinates: [String]
    var annotation: String
    var sampleTag: String
    var frameWidth: String
    var frameHeight: String
    var traveledDistances: [String]
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
                    annotation: manager.annotations.first ?? "",
                    sampleTag: manager.sample_tags.first ?? "",
                    frameWidth: manager.frame_widths.first ?? "",
                    frameHeight: manager.frame_heights.first ?? "",
                    traveledDistances: manager.traveled_distances
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
