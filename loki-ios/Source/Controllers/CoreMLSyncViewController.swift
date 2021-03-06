//
//  CoreMLSyncViewController.swift
//  nwHacks2018
//
//  Created by Nathan Tannar on 1/14/18.
//  Copyright © 2018 Nathan Tannar. All rights reserved.
//

import UIKit
import CoreML

class CoreMLSyncViewController: UIViewController {
    
    weak var downloadWheel: DownloadWheel?
    
    // MARK: - Initialization
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        title = "CoreML Sync"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let url = URL(string: "http://nw-loki.tech:5001/model")!
        downloadWheel = DownloadWheel().downloadFile(from: url) { [weak self] (wheel, url, error) in
            guard let url = url else {
                Ping(text: error?.localizedDescription ?? "Error", style: .danger).show()
                return
            }
            self?.replaceEmotionModel(at: url)
        }
        downloadWheel?.present(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        downloadWheel?.dismiss(animated: false)
        downloadWheel = nil
    }
    
    func replaceEmotionModel(at url: URL) {
        
        guard let compiledUrl = try? MLModel.compileModel(at: url) else {
            print("invalid model file found at URL")
            return
        }
        //        let model = try! EmotionModel(contentsOf: compiledUrl)
        
        // find the app support directory
        let fileManager = FileManager.default
        let appSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: compiledUrl,
                                                       create: true)
        
        // create a permanent URL in the app support directory
        let permanentUrl = appSupportDirectory.appendingPathComponent("EmotionModel.mlmodel")
        
        do {
            // if the file exists, replace it. Otherwise, copy the file to the destination.
            if fileManager.fileExists(atPath: permanentUrl.path) {
                print("file exists, replacing model")
                _ = try fileManager.replaceItemAt(permanentUrl, withItemAt: compiledUrl)
            } else {
                print("file does not exist, creating model")
                try fileManager.copyItem(at: compiledUrl, to: permanentUrl)
            }
        } catch {
            DispatchQueue.main.async {
                Ping(text: "Error during copy: \(error.localizedDescription)", style: .danger).show()
            }
        } 
    }
}
