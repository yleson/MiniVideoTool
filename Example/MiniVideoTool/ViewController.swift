//
//  ViewController.swift
//  MiniVideoTool
//
//  Created by huangshuoxing on 08/02/2022.
//  Copyright (c) 2022 huangshuoxing. All rights reserved.
//

import UIKit
import MiniVideoTool

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let cameraVc = MiniCameraController()
        cameraVc.modalPresentationStyle = .fullScreen
        cameraVc.completeBlock = { url, type in
            if type == .video {
                // 只支持视频
                
            }
        }
        self.present(cameraVc, animated: true, completion: nil)
    }

}

