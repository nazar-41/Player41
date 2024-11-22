//
//  AssetPersistenceManager.swift
//  Dinle
//
//  Created by Nazar Velkakayev on 22.11.2024.
//

import Foundation
import AVFoundation

/// - Tag: AssetPersistenceManager
class AssetPersistenceManager: NSObject {
    // MARK: Properties

    /// Singleton for AssetPersistenceManager.
    static let sharedManager = AssetPersistenceManager()

    /// Internal Bool used to track if the AssetPersistenceManager finished restoring its state.
    private var didRestorePersistenceManager = false

    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!

    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAggregateAssetDownloadTask: Asset]()

    /// Internal map of AVAggregateAssetDownloadTask to download URL.
    fileprivate var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()
    
    private var downloadQueue = [DownloadTask]()
    private var isDownloading = false
    private var downloadedAssetsMap = [String: Asset]()
    
    private let backgroundQueue = DispatchQueue(label: "com.player41.media.downloadQueue", qos: .background)



    // MARK: Intialization

    override private init() {

        super.init()

        // Create the configuration for the AVAssetDownloadURLSession.
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "AAPL-Identifier")

        // Create the AVAssetDownloadURLSession using the configuration.
        assetDownloadURLSession =
            AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
//        self.restorePersistenceManager()
    }
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    func restorePersistenceManager() {
         guard !didRestorePersistenceManager else { return }

         didRestorePersistenceManager = true

         // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            
            do{
                for task in tasksArray {
                    guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { continue }
                    
                    let urlAsset = assetDownloadTask.urlAsset
                    
                    let asset = Asset(urlAsset: urlAsset, id: task.description)
                    
                    self.activeDownloadsMap[assetDownloadTask] = asset
                }
                DispatchQueue.main.async{
                    NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
                }
            }catch{
                print(error)
            }
        }
    }




    func downloadStream(for asset: Asset) {
        let task = DownloadTask(asset: asset)
        downloadQueue.append(task)
        startNextDownload()
        
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.id] = asset.id
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        }
    }

    private func startNextDownload() {
        guard !isDownloading, let task = downloadQueue.first else { return }
        isDownloading = true
        
        backgroundQueue.async { [weak self] in
            self?.initiateDownload(for: task.asset)
        }
    }


    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    func initiateDownload(for asset: Asset) {
        
        // Get the default media selections for the asset's media selection groups.
        let preferredMediaSelection = asset.urlAsset.preferredMediaSelection
        
        /*
         Creates and initializes an AVAggregateAssetDownloadTask to download multiple AVMediaSelections
         on an AVURLAsset.
         
         For the initial download, we ask the URLSession for an AVAssetDownloadTask with a minimum bitrate
         corresponding with one of the lower bitrate variants in the asset.
         */
        guard let task =
                assetDownloadURLSession.aggregateAssetDownloadTask(with: asset.urlAsset,
                                                                   mediaSelections: [preferredMediaSelection],
                                                                   assetTitle: asset.id,
                                                                   assetArtworkData: nil,
                                                                   options:
                                                                    [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }
        
        // To better track the AVAssetDownloadTask, set the taskDescription to something unique for the sample.
        task.taskDescription = asset.id
        
        activeDownloadsMap[task] = asset
        
        task.resume()
        
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.id] = asset.id
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        userInfo[Asset.Keys.downloadSelectionDisplayName] = displayNamesForSelectedMediaOptions(preferredMediaSelection)
        
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        }
    }

    /// Returns an Asset given a specific name if that Asset is associated with an active download.
    func assetForStream(withName name: String) -> Asset? {
        var asset: Asset?

        for (_, assetValue) in activeDownloadsMap where name == assetValue.id {
            asset = assetValue
            break
        }

        return asset
    }
    
    /// Returns an Asset pointing to a file on disk if it exists.
    func localAssetForStream(with id: String) -> Asset? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: id) as? Data else { return nil }
        
        var asset: Asset?
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                                    bookmarkDataIsStale: &bookmarkDataIsStale)

            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            
            let urlAsset = AVURLAsset(url: url)
            
            asset = Asset(urlAsset: urlAsset, id: id)
            
            return asset
        } catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }


    /// Returns the current download state for a given Asset.
    func downloadState(for asset: Asset) -> Asset.DownloadState {
        // Check if there is a file URL stored for this asset.
        if let localFileLocation = localAssetForStream(with: asset.id)?.urlAsset.url {
            // Check if the file exists on disk
            if FileManager.default.fileExists(atPath: localFileLocation.path) {
                return .downloaded
            }
        }

        // Check if there are any active downloads in flight.
        for (_, assetValue) in activeDownloadsMap where asset.id == assetValue.id {
            return .downloading
        }

        return .notDownloaded
    }

    /// Deletes an Asset on disk if possible.
    /// - Tag: RemoveDownload
    func deleteAsset(_ asset: Asset) {
        let userDefaults = UserDefaults.standard

        do {
            if let localFileLocation = localAssetForStream(with: asset.id)?.urlAsset.url {
                try FileManager.default.removeItem(at: localFileLocation)

                userDefaults.removeObject(forKey: asset.id)

                var userInfo = [String: Any]()
                userInfo[Asset.Keys.id] = asset.id
                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue
                DispatchQueue.main.async{
                    NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil,
                                                    userInfo: userInfo)
                }
            }
        } catch {
            print("An error occured deleting the file: \(error)")
        }
    }

    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    func cancelDownload(for asset: Asset) {
        var task: AVAggregateAssetDownloadTask?

        for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
            task = taskKey
            break
        }

        task?.cancel()
        
        downloadQueue.removeAll(where: {$0.asset == asset})
    }
}

/// Return the display names for the media selection options that are currently selected in the specified group
func displayNamesForSelectedMediaOptions(_ mediaSelection: AVMediaSelection) -> String {

    var displayNames = ""

    guard let asset = mediaSelection.asset else {
        return displayNames
    }

    // Iterate over every media characteristic in the asset in which a media selection option is available.
    for mediaCharacteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
        /*
         Obtain the AVMediaSelectionGroup object that contains one or more options with the
         specified media characteristic, then get the media selection option that's currently
         selected in the specified group.
         */
        guard let mediaSelectionGroup =
            asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
            let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }

        // Obtain the display string for the media selection option.
        if displayNames.isEmpty {
            displayNames += " " + option.displayName
        } else {
            displayNames += ", " + option.displayName
        }
    }

    return displayNames
}

/**
 Extend `AssetPersistenceManager` to conform to the `AVAssetDownloadDelegate` protocol.
 */
extension AssetPersistenceManager: AVAssetDownloadDelegate {

    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let userDefaults = UserDefaults.standard

        guard let task = task as? AVAggregateAssetDownloadTask,
              let asset = activeDownloadsMap.removeValue(forKey: task) else { return }

        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }

        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        backgroundQueue.async { [weak self] in
            self?.handleCompletion(for: task, with: asset, at: downloadURL, error: error)
        }
    }
    
    private func handleCompletion(for task: AVAggregateAssetDownloadTask, with asset: Asset, at downloadURL: URL, error: Error?) {
         let userDefaults = UserDefaults.standard
         var userInfo = [String: Any]()
         userInfo[Asset.Keys.id] = asset.id

         if let error = error as NSError? {
             switch (error.domain, error.code) {
             case (NSURLErrorDomain, NSURLErrorCancelled):
                 handleCancellation(for: asset, userDefaults: userDefaults)
             case (NSURLErrorDomain, NSURLErrorUnknown):
                 print("Downloading HLS streams is not supported in the simulator.")
             default:
                 print("An unexpected error occurred \(error.domain)")
             }
         } else {
             do {
                 let bookmark = try downloadURL.bookmarkData()
                 userDefaults.set(bookmark, forKey: asset.id)
                 downloadedAssetsMap[asset.id] = asset
             } catch {
                 print("Failed to create bookmarkData for download URL.")
             }

             userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloaded.rawValue
             userInfo[Asset.Keys.downloadSelectionDisplayName] = ""
         }

         DispatchQueue.main.async {
             NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
             if !self.downloadQueue.isEmpty {
                 self.downloadQueue.removeFirst()
             }
             self.isDownloading = false
             self.startNextDownload()
         }
     }
    
    private func handleCancellation(for asset: Asset, userDefaults: UserDefaults) {
         guard let localFileLocation = localAssetForStream(with: asset.id)?.urlAsset.url else { return }

         do {
             try FileManager.default.removeItem(at: localFileLocation)
             userDefaults.removeObject(forKey: asset.id)
         } catch {
             print("An error occurred trying to delete the contents on disk for \(asset.id): \(error)")
         }

         var userInfo = [String: Any]()
         userInfo[Asset.Keys.id] = asset.id
         userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue

        DispatchQueue.main.async {
                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
            }
     }
    
    func downloadedAssets() -> [Asset] {
          return Array(downloadedAssetsMap.values)
      }


    /// Method called when the an aggregate download task determines the location this asset will be downloaded to.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    willDownloadTo location: URL) {

        /*
         This delegate callback should only be used to save the location URL
         somewhere in your application. Any additional work should be done in
         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
         */

        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }

    /// Method called when a child AVAssetDownloadTask completes.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didCompleteFor mediaSelection: AVMediaSelection) {
        /*
         This delegate callback provides an AVMediaSelection object which is now fully available for
         offline use. You can perform any additional processing with the object here.
         */
        
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.id] = asset.id
        
        aggregateAssetDownloadTask.taskDescription = asset.id
        
        aggregateAssetDownloadTask.resume()
        
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        userInfo[Asset.Keys.downloadSelectionDisplayName] = displayNamesForSelectedMediaOptions(mediaSelection)
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        }
    }

    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {

        // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }

        var userInfo = [String: Any]()
        userInfo[Asset.Keys.id] = asset.id
        userInfo[Asset.Keys.percentDownloaded] = percentComplete

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)

            }
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    static let AssetDownloadProgress = Notification.Name(rawValue: "AssetDownloadProgressNotification")
    
    /// Notification for when the download state of an Asset has changed.
    static let AssetDownloadStateChanged = Notification.Name(rawValue: "AssetDownloadStateChangedNotification")
    
    /// Notification for when AssetPersistenceManager has completely restored its state.
    static let AssetPersistenceManagerDidRestoreState = Notification.Name(rawValue: "AssetPersistenceManagerDidRestoreStateNotification")
}
