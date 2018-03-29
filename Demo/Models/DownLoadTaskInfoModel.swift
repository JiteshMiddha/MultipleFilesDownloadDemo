//
//  DownLoadTaskInfoModel.swift
//  Demo
//
//  Created by Jitesh Middha on 28/03/18.
//  Copyright © 2018 Jitesh Middha. All rights reserved.
//

import UIKit

class DownLoadTaskInfoModel: NSObject {

    enum TaskStatus {
        case notStarted
        case paused
        case downloading
        case finished
    }
    
    var url: URL?
    var taskIndex: NSNumber?
    var taskData: Data?
    var taskStatus: TaskStatus? = .notStarted
    var downloadTask: URLSessionDownloadTask?
    var cachedFileURL: URL?
    
    var percentDownloaded: Int64?
    
    override init() {
        super.init()
    }
    init(withURL url: String) {
        self.url = URL.init(string: url)
    }
}
