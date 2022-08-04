//
//  MiniCameraController.swift
//  MiniVideoTool
//
//  Created by yleson on 2022/8/2.
//

import UIKit

public enum CameraType {
    case video
    case image
}

open class MiniCameraController: UIViewController {
    
    var url: String?
    var type: CameraType?
    
    public var completeBlock: (String, CameraType) -> () = {_,_  in }
    
    let previewImageView = UIImageView()
    var videoPlayer: MiniVideoPlayer!
    var controlView: MiniCameraControl!
    var manager: MiniCameraManager!
    
    let cameraContentView = UIView()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let scale: CGFloat = 16.0 / 9.0
        let contentWidth = UIScreen.main.bounds.size.width
        let contentHeight = min(scale * contentWidth, UIScreen.main.bounds.size.height)
        
        cameraContentView.backgroundColor = UIColor.black
        cameraContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        cameraContentView.center = self.view.center
        self.view.addSubview(cameraContentView)
        
        manager = MiniCameraManager(superView: cameraContentView)
        setupView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.staruRunning()
        manager.focusAt(cameraContentView.center)
    }
    
    override open var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.black
        cameraContentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(focus(_:))))
        cameraContentView.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(_:))))
        
        videoPlayer = MiniVideoPlayer(frame: cameraContentView.bounds)
        videoPlayer.isHidden = true
        cameraContentView.addSubview(videoPlayer)
        
        previewImageView.frame = cameraContentView.bounds
        previewImageView.backgroundColor = UIColor.black
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        cameraContentView.addSubview(previewImageView)
        
        controlView = MiniCameraControl.init(frame: CGRect(x: 0, y: cameraContentView.height - 150, width: self.view.width, height: 150))
        controlView.delegate = self
        cameraContentView.addSubview(controlView)
    }
    
    @objc func focus(_ ges: UITapGestureRecognizer) {
        let focusPoint = ges.location(in: cameraContentView)
        manager.focusAt(focusPoint)
    }
    
    @objc func pinch(_ ges: UIPinchGestureRecognizer) {
        guard ges.numberOfTouches == 2 else { return }
        if ges.state == .began {
            manager.repareForZoom()
        }
        manager.zoom(Double(ges.scale))
    }
    
}

extension MiniCameraController: MiniCameraControlDelegate {
    
    func cameraControlDidComplete() {
        dismiss(animated: true) {
            self.completeBlock(self.url!, self.type!)
        }
    }
    
    func cameraControlDidTakePhoto() {
        manager.pickImage { [weak self] (imageUrl) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.type = .image
                self.url = imageUrl
                self.previewImageView.image = UIImage.init(contentsOfFile: imageUrl)
                self.previewImageView.isHidden = false
                self.controlView.showCompleteAnimation()
            }
        }
    }
    
    func cameraControlBeginTakeVideo() {
        manager.repareForZoom()
        manager.startRecordingVideo()
    }
    
    func cameraControlEndTakeVideo() {
        manager.endRecordingVideo { [weak self] (videoUrl) in
            guard let `self` = self else { return }
            let url = URL.init(fileURLWithPath: videoUrl)
            self.type = .video
            self.url = videoUrl
            self.videoPlayer.isHidden = false
            self.videoPlayer.videoUrl = url
            self.videoPlayer.play()
            self.controlView.showCompleteAnimation()
        }
    }
    
    func cameraControlDidChangeFocus(focus: Double) {
        let sh = Double(UIScreen.main.bounds.size.width) * 0.15
        let zoom = (focus / sh) + 1
        self.manager.zoom(zoom)
    }
    
    func cameraControlDidChangeCamera() {
        manager.changeCamera()
    }
    
    func cameraControlDidClickBack() {
        self.previewImageView.isHidden = true
        self.videoPlayer.isHidden = true
        self.videoPlayer.pause()
    }
    
    func cameraControlDidExit() {
        dismiss(animated: true, completion: nil)
    }
    
}

