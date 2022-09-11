//
//  AVPlayerView.swift
//  VIdeoPlayer
//
//  Created by LanceMacBookPro on 3/26/22.
//

import UIKit

class AVPlayerView: UIView {
    
    var playerLayer: CALayer?
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        playerLayer?.frame = self.bounds
    }
}
