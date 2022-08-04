//
//  MiniVideoPlayer.swift
//  MiniVideoTool
//
//  Created by yleson on 2022/8/2.
//

import UIKit
import AVFoundation

open class MiniVideoPlayer: UIView {
    
    public var videoUrl: URL?
    let player = AVPlayer()
    var playerLayer: AVPlayerLayer!
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        
        self.playerLayer = AVPlayerLayer.init(player: self.player)
        self.playerLayer.frame = self.layer.bounds
        self.playerLayer.videoGravity = .resizeAspect
        self.layer.addSublayer(self.playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPlay), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func finishPlay() {
        self.player.seek(to: CMTime.zero)
        self.player.play()
    }
    
    public func play() {
        let item = AVPlayerItem.init(asset: AVURLAsset.init(url: self.videoUrl!))
        self.player.replaceCurrentItem(with: item)
        self.player.play()
    }
    
    func pause() {
        self.player.pause()
    }
}
