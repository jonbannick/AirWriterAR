//
//  VideoController.swift
//  Air Writer
//
//  Created by Jonathan Bannick on 10/17/17.
//  Copyright © 2017 Jonathan Bannick. All rights reserved.
//

import UIKit
import AVKit
import Photos
import StoreKit
import FBSDKShareKit
import UnityAds

class VideoController: UIViewController, UnityAdsDelegate,UIDocumentInteractionControllerDelegate {

    var videoURL: URL?
    
    var okView = UIView()
    var cancelView = UIView()
    
    var socialView = UIView()
    
    var igView = UIImageView()
    var fbView = UIImageView()
    var sendView = UIImageView()
    
    var currentLevel = 0
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.init(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        
        let iconDim = 75
        okView.frame = CGRect(x: 50, y: Int(view.frame.height) - 50 - iconDim, width: iconDim, height: iconDim)
        okView.layer.cornerRadius = CGFloat(iconDim / 2)
        okView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        
        let okImage = UIImageView(frame: CGRect(x: iconDim / 5, y: iconDim / 5, width: iconDim * 3 / 5, height: iconDim * 3 / 5))
        okImage.image = UIImage(named: "check")
        okView.addSubview(okImage)
        
        let okTap = UITapGestureRecognizer(target: self, action: #selector(confirm))
        okView.isUserInteractionEnabled = true
        okView.addGestureRecognizer(okTap)
        view.addSubview(okView)
        
        cancelView.frame = CGRect(x: Int(view.frame.width) - 50 - iconDim, y: Int(view.frame.height) - 50 - iconDim, width: iconDim, height: iconDim)
        cancelView.layer.cornerRadius = CGFloat(iconDim / 2)
        cancelView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        
        let cancelImage = UIImageView(frame: CGRect(x: iconDim / 5, y: iconDim / 5, width: iconDim * 3 / 5, height: iconDim * 3 / 5))
        cancelImage.image = UIImage(named: "delete")
        cancelView.addSubview(cancelImage)
        
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        cancelView.isUserInteractionEnabled = true
        cancelView.addGestureRecognizer(cancelTap)
        view.addSubview(cancelView)
        
        let shareIconDim = 40
        
        let iconSpacing = (Int(view.frame.width) - (3 * shareIconDim)) / 4
        
        socialView.frame = CGRect(x: -1 * Int(view.frame.width), y: Int(view.frame.height) - shareIconDim - 80, width: Int(view.frame.width), height: shareIconDim + 60)
        
        igView.frame = CGRect(x: iconSpacing, y: 0, width: shareIconDim, height: shareIconDim)
        igView.image = UIImage(named: "instagram")
        igView.isUserInteractionEnabled = true
        let igTap = UITapGestureRecognizer(target: self, action: #selector(shareToInstagram))
        igView.addGestureRecognizer(igTap)
        socialView.addSubview(igView)
        
        fbView.frame = CGRect(x: Int(igView.frame.maxX) + iconSpacing, y: 0, width: shareIconDim, height: shareIconDim)
        fbView.image = UIImage(named: "facebook")
        fbView.isUserInteractionEnabled = true
        let fbTap = UITapGestureRecognizer(target: self, action: #selector(shareToFacebook))
        fbView.addGestureRecognizer(fbTap)
        socialView.addSubview(fbView)
        
        sendView.frame = CGRect(x: Int(fbView.frame.maxX) + iconSpacing, y: 0, width: shareIconDim, height: shareIconDim)
        sendView.image = UIImage(named: "send")
        sendView.isUserInteractionEnabled = true
        let sendTap = UITapGestureRecognizer(target: self, action: #selector(sendToOther))
        sendView.addGestureRecognizer(sendTap)
        socialView.addSubview(sendView)
        
        view.addSubview(socialView)
        
        
        
        let videoView = UIView(frame: CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 450))
        view.addSubview(videoView)
        
        var player: AVPlayer!
        
        // 1
        let playerLayer = AVPlayerLayer()
        playerLayer.frame = videoView.bounds
        
        // 2
        //let url = Bundle.main.url(forResource: "someVideo", withExtension: "m4v")
        player = AVPlayer(url: videoURL!)
        
        // 3
        player.actionAtItemEnd = .none
        playerLayer.player = player
        videoView.layer.addSublayer(playerLayer)
        
        player.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil, using: { (_) in
            DispatchQueue.main.async {
                player?.seek(to: kCMTimeZero)
                player?.play()
            }
        })
        
        
        let preferences = UserDefaults.standard
        
        let timesLoadedKey = "timesLoaded"
        if preferences.object(forKey: timesLoadedKey) == nil {
            preferences.set(0, forKey: timesLoadedKey)
        } else {
            currentLevel = preferences.integer(forKey: timesLoadedKey)
            
            let ratedYet = "ratedYet"
            var ratedResult = 0
            if(preferences.object(forKey: ratedYet) == nil){
                preferences.set(0,forKey: ratedYet)
            }else{
                ratedResult = preferences.integer(forKey: ratedYet)
            }
            print(currentLevel)
            if(currentLevel > 15 && ratedResult == 0){
                SKStoreReviewController.requestReview()
                preferences.set(1,forKey: ratedYet)
            }
            //currentLevel += 1
            //preferences.set(currentLevel, forKey: timesLoadedKey)
        }
        //  Save to disk
        let didSave = preferences.synchronize()
        
        if !didSave {
            //  Couldn't save (I've never seen this happen in real world testing)
        }
        if(currentLevel > 10 && currentLevel % 5 == 0){
            UnityAds.initialize("1580799", delegate: self)
        }
        
        let backButton = UIButton(frame: CGRect(x: 0, y: fbView.frame.maxY + 20, width: view.frame.width, height: 40))
        let backTitle = UILabel(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        backTitle.text = "Back"
        backTitle.textAlignment = NSTextAlignment.center
        backTitle.textColor = UIColor.init(white: 0.4, alpha: 1.0)
        backButton.addSubview(backTitle)
        backButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        socialView.addSubview(backButton)
    }
    
    @objc func confirm(){
        print(videoURL!)
        PHPhotoLibrary.shared().performChanges({ () -> Void in
         
            let createAssetRequest: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL!)!
            createAssetRequest.placeholderForCreatedAsset
         
        }){ (success, error) -> Void in
            if success {
                print("succ")
                //cleanup()
            }else{
                print("no succ")
                print(error)
            }
        }
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.okView.frame = CGRect(x: self.okView.frame.minX + self.view.frame.width, y: self.okView.frame.minY, width: self.okView.frame.width, height: self.okView.frame.height)
            self.cancelView.frame = CGRect(x: self.cancelView.frame.minX + self.view.frame.width, y: self.cancelView.frame.minY, width: self.cancelView.frame.width, height: self.cancelView.frame.height)
            
            self.socialView.frame = CGRect(x: 0, y: self.socialView.frame.minY, width: self.socialView.frame.width, height: self.socialView.frame.height)
        }) { finished in
            
        }
    }
    
    @objc func cancel(){
        if(currentLevel > 10 && currentLevel % 5 == 0){
            
            let preferences = UserDefaults.standard
            let timesLoadedKey = "timesLoaded"
            currentLevel += 1
            preferences.set(currentLevel, forKey: timesLoadedKey)
            //  Save to disk
            let didSave = preferences.synchronize()
            
            let placement = "rewardedVideo"
            if (UnityAds.isReady(placement)) {
                //a video is ready & placement is valid
                
                UnityAds.show(self, placementId: placement)
            }
        }else{
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func shareToInstagram(){
        let message = "#AirWriter" as NSString
        //message.stringByAddingPercentEscapesUsingEncoding
        let escapedCaption = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var localIdentifier = String()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        if (fetchResult.firstObject != nil){
            let lastImageAsset: PHAsset = fetchResult.firstObject as! PHAsset
            localIdentifier = lastImageAsset.localIdentifier
            print("!@#")
            print(localIdentifier)
        }else{
            localIdentifier = ""
        }
        
        //var escapedString = assetsLibraryURL.absoluteString.urlencoded()
        let escapedString = localIdentifier.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        print(escapedString)
        print(escapedCaption)
        
        let instagram = URL(string: "instagram://library?AssetPath=\(escapedString)&InstagramCaption=\(escapedCaption)")
        
        print(instagram)
        
        if UIApplication.shared.canOpenURL(instagram!) {
            UIApplication.shared.open(instagram!, options: ["":""], completionHandler: nil)
        } else {
            print("Instagram not installed")
        }
    }
    
    @objc func shareToFacebook(){
        print("share FB")
        var localIdentifier = String()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        if (fetchResult.firstObject != nil){
            let lastImageAsset: PHAsset = fetchResult.firstObject as! PHAsset
            localIdentifier = lastImageAsset.localIdentifier
            print("!@#")
            print(localIdentifier)
            let assetID = localIdentifier.replacingOccurrences(of: "/.*", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
            
            let ext = "mp4"
            let assetURLStr =
            "assets-library://asset/asset.\(ext)?id=\(assetID)&ext=\(ext)"
            
            let video = FBSDKShareVideo()
            //video.videoURL = URL(fileURLWithPath: localIdentifier)
            video.videoURL = URL(string: assetURLStr)
            let content = FBSDKShareVideoContent()
            content.video = video
            print(localIdentifier)
            print(content)
            print(video.videoURL)
            content.hashtag = FBSDKHashtag(string: "#AirWriter")
            FBSDKShareDialog.show(from: self, with: content, delegate: nil)
    
        }else{
            localIdentifier = ""
        }
    }
    
    @objc func sendToOther(){
        
        var localIdentifier = String()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        if (fetchResult.firstObject != nil){
            let lastImageAsset: PHAsset = fetchResult.firstObject as! PHAsset
            localIdentifier = lastImageAsset.localIdentifier
            print("!@#")
            print(localIdentifier)
            let assetID = localIdentifier.replacingOccurrences(of: "/.*", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
            
            let ext = "mp4"
            let assetURLStr =
            "assets-library://asset/asset.\(ext)?id=\(assetID)&ext=\(ext)"

            
            // file saved
            
            let videoLink = NSURL(fileURLWithPath: assetURLStr)
            
            
            let objectsToShare = [videoLink]
            
            let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            // exclude some activity types from the list (optional)
            //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
            
        }else{
            localIdentifier = ""
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func unityAdsReady(_ placementId: String) { }
    
    func unityAdsDidStart(_ placementId: String) { }
    
    func unityAdsDidError(_ error: UnityAdsError, withMessage message: String) { }
    
    func unityAdsDidFinish(_ placementId: String, with state: UnityAdsFinishState) {
        dismiss(animated: true, completion: nil)
    }
}
