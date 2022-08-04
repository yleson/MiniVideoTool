//
//  MiniVideoEditor.swift
//  MiniVideoTool
//
//  Created by yleson on 2022/8/2.
//

import UIKit
import AVKit

open class MiniVideoEditor: NSObject {
    
    typealias ExportProgress = (Double) -> ()
    
    var avAsset: AVAsset!
    
    let videoComposition = AVMutableVideoComposition()
    let composition = AVMutableComposition()
    
    var videoAssetTrack: AVAssetTrack?
    var audioAssetTrack: AVAssetTrack?
    
    var videoTrack: AVMutableCompositionTrack?
    var audioTrack: AVMutableCompositionTrack?
    
    var duration: CMTime!
    var naturalSize: CGSize!
    
    var exportProgressBlock: ExportProgress?
    var timer: Timer?
    
    public init(videoUrl: URL) {
        super.init()
        
        avAsset = AVAsset(url: videoUrl)
        duration = avAsset.duration
        
        guard let avAssetVideoTrack = avAsset.tracks(withMediaType: .video).first,
            let avAssetAudioTrack = avAsset.tracks(withMediaType: .audio).first else {
                return
        }
        videoAssetTrack = avAssetVideoTrack
        audioAssetTrack = avAssetAudioTrack
        naturalSize = avAssetVideoTrack.naturalSize
        
        videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: avAssetVideoTrack, at: CMTime.zero)
        
        audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? audioTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: avAssetVideoTrack, at: CMTime.zero)
        
        videoComposition.renderSize = naturalSize
        videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
        rotatoTo(avAssetVideoTrack.preferredTransform)
    }
    
    public func addWaterMark(image: UIImage) {
        let videoSize = videoComposition.renderSize
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        let parentLayer = CALayer()
        parentLayer.backgroundColor = UIColor.clear.cgColor
        parentLayer.frame = videoLayer.bounds
        parentLayer.addSublayer(videoLayer)
        
        let imageView = UIImageView(frame: CGRect(x: 30, y: videoSize.height - 150, width: 270, height: 120))
        imageView.image = image
        parentLayer.addSublayer(imageView.layer)
        
        videoComposition.animationTool = .init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    public func addAudio(audioUrl: String) {
        composition.tracks(withMediaType: .audio).forEach { (track) in
            composition.removeTrack(track)
        }
        
        let url = URL.init(fileURLWithPath: audioUrl)
        let audioAsset = AVAsset.init(url: url)
        let avAssetAudioTrack = audioAsset.tracks(withMediaType: .audio).first
        
        audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? audioTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: avAssetAudioTrack!, at: CMTime.zero)
    }
    
    public func rotatoTo(_ transform: CGAffineTransform) {
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoAssetTrack!)
        let videoRotate = translatedBy(naturalSize, transform: transform)
        layerInstruction.setTransform(videoRotate, at: CMTime.zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: duration)
        instruction.layerInstructions = [layerInstruction]
        
        let videoSize = transformSize(naturalSize, to: transform)
        
        videoComposition.renderSize = videoSize
        videoComposition.instructions = [instruction]
    }
    
    public func export(progress: @escaping ((Double) -> ()) ,completeHandler: @escaping (String) -> ()) {
        let savePath = createFileUrl("MOV")
        
        let avAssetExportSession = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        avAssetExportSession?.videoComposition = videoComposition
        avAssetExportSession?.outputURL = .init(fileURLWithPath: savePath)
        avAssetExportSession?.outputFileType = .mov
        avAssetExportSession?.shouldOptimizeForNetworkUse = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (_) in
            progress(Double(avAssetExportSession?.progress ?? 0))
        })
        avAssetExportSession?.exportAsynchronously(completionHandler: {
            if avAssetExportSession?.status == .completed {
                DispatchQueue.main.async {
                    self.timer?.invalidate()
                    completeHandler(savePath)
                }
            }
        })
    }
    
    public func assetReaderExport(completeHandler: @escaping (String) -> ()) {
        let export = MiniVideoExport()
        export.composition = composition
        export.videoComposition = videoComposition
        export.outputUrl = createFileUrl("MOV")
        export.exportVideo { (url) in
            completeHandler(url)
        }
    }
    
    private func createFileUrl(_ type: String) -> String {
        let formate = DateFormatter()
        formate.dateFormat = "yyyyMMddHHmmss"
        let fileName = formate.string(from: Date()) + "." + type
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let filePath = path! + "/" + fileName
        return filePath
    }
    
    private func transformSize(_ naturalSize: CGSize, to transform: CGAffineTransform) -> CGSize {
        let videoSize: CGSize
        if transform.a * transform.d + transform.b * transform.c == -1 {
            videoSize = CGSize(width: min(naturalSize.width, naturalSize.height),
                               height: max(naturalSize.width, naturalSize.height))
        } else {
            videoSize = CGSize(width: max(naturalSize.width, naturalSize.height),
                               height: min(naturalSize.width, naturalSize.height))
        }
        return videoSize
    }
    
    private func translatedBy(_ naturalSize: CGSize, transform: CGAffineTransform) -> CGAffineTransform {
        var x: CGFloat = 0
        var y: CGFloat = 0
        if transform.a + transform.b == -1 {
            x = -naturalSize.width
        }
        if transform.c + transform.d == -1 {
            y = -naturalSize.height
        }
        return transform.translatedBy(x: x, y: y)
    }
    
}
