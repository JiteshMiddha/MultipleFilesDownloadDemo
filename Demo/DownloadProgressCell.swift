//
//  DownloadProgressCell.swift
//  Demo
//
//  Created by Jitesh Middha on 28/03/18.
//  Copyright © 2018 Jitesh Middha. All rights reserved.
//

import UIKit
import CoreData

class DownloadProgressCell: UITableViewCell {

    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    
    var taskInfo = DownLoadTaskInfoModel()
    
    var session: URLSession?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func playPauseButton(_ sender: UIButton) {
        
        // start/resume and pause button action
        if taskInfo.taskStatus == .downloading {
            
            sender.setBackgroundImage(#imageLiteral(resourceName: "ic_play_arrow"), for: .normal)
            
            pause()
        }
        else {
            sender.setBackgroundImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            
            resumeDownloading()
        }
    }
    
    func pause() {
        
        if taskInfo.downloadTask != nil {
            
            taskInfo.downloadTask?.cancel(byProducingResumeData: { (resumeData) in
                
                self.taskInfo.taskData = resumeData
                // saving resume data to resume download later
                self.writeCacheFile(cacheData: self.taskInfo.taskData, fileName: (self.taskInfo.url?.hashValue.description)!)
                
            })
            taskInfo.taskStatus = .paused
        }
    }
    
    func resumeDownloading() {
        
        if taskInfo.downloadTask != nil {
            
            // when download is paused
            taskInfo.taskData = self.readCacheFile(fileName: (taskInfo.url?.hashValue.description)!)
            
            if(taskInfo.taskData != nil) {
                // if resume data is available - continue download
                taskInfo.downloadTask = session?.downloadTask(withResumeData: taskInfo.taskData!)
            } else {
                // else start from begining
                taskInfo.downloadTask = self.session?.downloadTask(with: taskInfo.url!)
            }
            
            
            DispatchQueue.global(qos: .background).async {
                
                self.taskInfo.downloadTask?.resume()
            }
            
            taskInfo.taskStatus = .downloading
        }
        else {
           // first time - starting download
            if let url = taskInfo.url {
                
                let config = URLSessionConfiguration.default
                self.session = URLSession.init(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
                
                let request = URLRequest(url: url)
                
                self.taskInfo.downloadTask = self.session?.downloadTask(with: request)
                
                self.resumeDownloading()
                
            }
        }
    }
    
    
    
    func readCacheFile(fileName: String) -> Data? {
        
        var cacheFileURL:URL? = self.getCacheFolderURL();
        
        cacheFileURL = cacheFileURL?.appendingPathComponent(fileName, isDirectory: false)
        
        if(cacheFileURL != nil) {
            
            do {
                let data = try Data.init(contentsOf: cacheFileURL!)
                return data
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        return nil
    }

    
    func writeCacheFile(cacheData:Data?, fileName: String) {
        
        var cacheFileURL = self.getCacheFolderURL();
        
        cacheFileURL = cacheFileURL?.appendingPathComponent(fileName, isDirectory: false)
        
        if(cacheFileURL != nil && cacheData != nil) {
            do {
                try cacheData!.write(to: cacheFileURL!, options: .atomic)
                
                // saving details in core data
                self.saveDownloadData(localURL: cacheFileURL!, downloadURL: taskInfo.url!, downloadCompleted: false)
            }
            catch {
                
            }
        }
    }

    func getCacheFolderURL() -> URL? {
        
        if(taskInfo.cachedFileURL != nil) {
            
            return taskInfo.cachedFileURL
        }
        
        let nsDocumentDirectory:FileManager.SearchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
        
        let nsUserDomainMask:FileManager.SearchPathDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        
        let paths:[String] = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true);
        
        if (paths.count > 0) {
            
            let folderPath:String = String(paths[0]);
            
            taskInfo.cachedFileURL = URL.init(fileURLWithPath: folderPath)
            
            return taskInfo.cachedFileURL
        }
        return nil
    }

    
    
    
    
    func saveDownloadData(localURL: URL, downloadURL: URL, downloadCompleted: Bool) {
        
        // saving in core data
        let fetchRequest: NSFetchRequest<Downloads> = Downloads.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "downloadURL== %@", downloadURL as CVarArg)
        
        if let result = try? CoreDataManager.shared.managedObjectContext.fetch(fetchRequest) {
            for object in result {
                CoreDataManager.shared.managedObjectContext.delete(object)
            }
        }
        
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: "Downloads", in: CoreDataManager.shared.managedObjectContext) {
            
            let download = NSManagedObject(entity: entityDescription, insertInto: CoreDataManager.shared.managedObjectContext) as! Downloads
            
            download.localURL = localURL
            download.downloadURL = downloadURL
            download.downloadCompleted = downloadCompleted
            download.percentDownloaded = taskInfo.percentDownloaded!
            
            guard CoreDataManager.shared.managedObjectContext.hasChanges else { return }
            
            do {
                try CoreDataManager.shared.managedObjectContext.save()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension DownloadProgressCell: URLSessionDelegate, URLSessionDownloadDelegate {
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        self.playPauseButton.setBackgroundImage(nil, for: .normal)
        self.playPauseButton.titleLabel?.text = "Download Complete"
        self.playPauseButton.isEnabled = false
        
        // saving downloaded file in Library directory
        
        let nsDocumentDirectory:FileManager.SearchPathDirectory = FileManager.SearchPathDirectory.libraryDirectory
        
        let nsUserDomainMask:FileManager.SearchPathDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        
        let paths:[String] = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true);
        
        if (paths.count > 0) {
            
            let folderPath:String = String(paths[0]);
            
            var destinationURL = URL.init(fileURLWithPath: folderPath);
            
            do {
                let manager = FileManager.default
                
                let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? taskInfo.url?.lastPathComponent
                destinationURL = destinationURL.appendingPathComponent(fileName!)
                if manager.fileExists(atPath: (destinationURL.path)) {
                    try manager.removeItem(at: destinationURL)
                }
                try manager.moveItem(at: location, to: destinationURL)
                
                // saving completed status in core data
                self.saveDownloadData(localURL: destinationURL, downloadURL: taskInfo.url!, downloadCompleted: true)
            } catch {
                print("\(error)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        // updating download progress
        let progress = totalBytesWritten*100/totalBytesExpectedToWrite
        progressSlider.value = Float(progress)
        self.progressLabel.text = "\(progress)%"
        taskInfo.percentDownloaded = progress
    }
    
    
}
