//
//  VideoView.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 25/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit
import AVFoundation

class VideoView: UIView {

    let previewImageView = UIImageView()
    let loading = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    var image: UIImage? { didSet { previewImageView.image = image } }
    var player: AVPlayer? {

        willSet {

            if newValue == nil {

                player?.removeObserver(self, forKeyPath: "status")
                player?.removeObserver(self, forKeyPath: "rate")
                player?.removeObserver(self, forKeyPath: "timeControlStatus")
            }
        }

        didSet {

            if  let player = self.player,
                let videoLayer = self.layer as? AVPlayerLayer {

                videoLayer.player = player
                videoLayer.videoGravity = AVLayerVideoGravity.resizeAspect

                player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
                player.addObserver(self, forKeyPath: "timeControlStatus", options: NSKeyValueObservingOptions.new, context: nil)
            }
        }
    }
    
    fileprivate var timer: Timer?

    override class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(previewImageView)
        self.addSubview(loading)

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewImageView.clipsToBounds = true
        
        loading.contentMode = .center
        loading.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loading.startAnimating()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {

        player?.removeObserver(self, forKeyPath: "status")
        player?.removeObserver(self, forKeyPath: "rate")
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let status = self.player?.status,
              let rate = self.player?.rate,
              status == .readyToPlay && rate != 0
              else { return }
                
        if #available(iOS 10.0, *) {
            if let controlStatus = self.player?.timeControlStatus, controlStatus == .playing {
                
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    guard let this = self else { return }
                    
                    if this.player!.currentTime() > CMTimeMakeWithSeconds(0, 1) {
                        
                        this.loading.isHidden = true
                        this.previewImageView.alpha = 0
                        timer.invalidate()
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                
                if let strongSelf = self {
                    
                    strongSelf.loading.isHidden = true
                    strongSelf.previewImageView.alpha = 0
                }
            })
        }
    }
}
