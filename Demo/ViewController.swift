//
//  ViewController.swift
//  Demo
//
//  Created by Jitesh Middha on 28/03/18.
//  Copyright © 2018 Jitesh Middha. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var taskList = [DownLoadTaskInfoModel]()
    let coreDataManager = CoreDataManager.shared
    var downloads: [Downloads]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        taskList = [DownLoadTaskInfoModel(withURL: "http://hd1.djring.com/320/489689/Ae%20Jo%20Silli%20SilliNarazgi%20-%20Hans%20Raj%20Hans%20Navraj%20Hans%20(DJJOhAL.Com).mp3"),
                    DownLoadTaskInfoModel(withURL: "http://hd1.djring.com/320/489688/3%20PegLabel%20Black%20-%20Sharry%20Mann%20Gupz%20Sehra%20(DJJOhAL.Com).mp3"),
                    DownLoadTaskInfoModel(withURL: "http://hd1.djring.com/320/490230/High%20End%20-%20Diljit%20Dosanjh%20(DJJOhAL.Com).mp3")]
        
        fetchSavedDownloads()
    }
    
    func fetchSavedDownloads() {
        // from core data
        let fetchRequest: NSFetchRequest<Downloads> = Downloads.fetchRequest()
        coreDataManager.managedObjectContext.performAndWait {
            
            do {
                let downloads = try fetchRequest.execute()
                self.downloads = downloads
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }


}


extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return taskList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadProgressCell", for: indexPath) as! DownloadProgressCell
        
        if let downloadedDataList = downloads?.filter({$0.downloadURL == taskList[indexPath.row].url}) {
            // downloadedDataList - list of object for which the download was paused or completed
            
            let downloadedData = downloadedDataList.first
            
            cell.progressSlider.setValue(Float(downloadedData?.percentDownloaded ?? 0), animated: true)
            cell.progressLabel.text = "\(downloadedData?.percentDownloaded ?? 0)%"

            if downloadedData?.downloadCompleted == true {
                cell.playPauseButton.setBackgroundImage(nil, for: .normal)
                cell.playPauseButton.isEnabled = false
                cell.playPauseButton.setTitle("Download Completed", for: .normal)
                
            }
            else {
                // if download was never started/saved
                cell.playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "ic_play_arrow"), for: .normal)
                cell.playPauseButton.isEnabled = true
                if cell.taskInfo.url == downloadedData?.downloadURL {
                    cell.taskInfo.cachedFileURL = downloadedData?.localURL
                }
            }
        }
        
        cell.taskInfo = taskList[indexPath.row]
        return cell
    }
}
