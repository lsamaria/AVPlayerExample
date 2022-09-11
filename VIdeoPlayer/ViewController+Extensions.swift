//
//  ViewController+Extensions.swift
//  VIdeoPlayer
//
//  Created by LanceMacBookPro on 3/26/22.
//

import UIKit
import AVFoundation

// MARK: - Player Supporting Methods
extension ViewController {
    
    public func pausePlayerAndShowPlayIcon() {
        player?.pause()
        pausePlayButton.setImage(playIcon, for: .normal)
    }
    
    public func stopSpinnerShowReplayButton() {
        
        spinner.stopAnimating()
        showReplayButton()
    }
    
    public func playPlayer() {
        
        playerTryCount = 0
        
        spinner.stopAnimating()
        
        guard let player = player else { return }
        
        if player.timeControlStatus == .paused {
            
            player.play()
            pausePlayButton.setImage(pauseIcon, for: .normal)
        }
    }
    
    @objc public func showReplayButton() {
        
        player?.pause()
        
        pausePlayButton.isHidden = true
        replayButton.isHidden = false
    }
    
    @objc public func replayButtonPressedRewindToBeginning() {
        
        guard let player = player else { return }
        let seekTime: CMTime = CMTimeMakeWithSeconds(.zero, preferredTimescale: 1000)
        player.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if !replayButton.isHidden {
            
            unhidePausePlayHideReplayButton()
            
            pausePlayButton.setImage(pauseIcon, for: .normal)
            
            player.play()
            return
        }
        
        if player.timeControlStatus != .playing {
            
            unhidePausePlayHideReplayButton()
            pausePlayButton.setImage(playIcon, for: .normal)
        }
    }
    
    @objc public func unhidePausePlayHideReplayButton() {
        replayButton.isHidden = true
        pausePlayButton.isHidden = false
    }
}

// MARK: - Remove TimeObserver && KVO
extension ViewController {
    
    public func removePeriodicTimeObserver() {
        
        pausePlayerAndShowPlayIcon()
        
        if timeObserverToken == nil { return }
        
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
            
            playerLayer?.removeFromSuperlayer()
        }
    }
    
    public func removeNSKeyValueObservers() {
        playerStatusObserver = nil
        playerRateObserver = nil
        playerTimeControlStatusObserver = nil
        playbackLikelyToKeepUpObserver = nil
        playbackBufferEmptyObserver = nil
        playbackBufferFullObserver = nil
        
        if let playerItemNewError = playerItemNewError {
            NotificationCenter.default.removeObserver(playerItemNewError)
        }
        if let playerItemPlaybackStalledObserver = playerItemPlaybackStalledObserver {
            NotificationCenter.default.removeObserver(playerItemPlaybackStalledObserver)
        }
        if let playerItemNewError = playerItemNewError {
            NotificationCenter.default.removeObserver(playerItemNewError)
        }
    }
}

// MARK: - UILayout
extension ViewController {
    
    public func setupUILayout() {
        
        view.addSubview(controlsContainerView)
        
        controlsContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        controlsContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        controlsContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        controlsContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        controlsContainerView.addSubview(spinner)
        controlsContainerView.addSubview(replayButton)
        controlsContainerView.addSubview(pausePlayButton)
        controlsContainerView.addSubview(videoDurationLabel)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(videoSlider)
        
        spinner.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor).isActive = true
        spinner.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor).isActive = true
        
        let buttonWidthHeight: CGFloat = 50
        
        replayButton.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor).isActive = true
        replayButton.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor).isActive = true
        replayButton.heightAnchor.constraint(equalToConstant: buttonWidthHeight).isActive = true
        replayButton.widthAnchor.constraint(equalToConstant: buttonWidthHeight).isActive = true
        
        pausePlayButton.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor).isActive = true
        pausePlayButton.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: buttonWidthHeight).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: buttonWidthHeight).isActive = true
        
        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 24
        let labelBottomPadding: CGFloat = 34
        let labelLeadingTrailingPadding: CGFloat = 8
        
        currentTimeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -labelBottomPadding).isActive = true
        currentTimeLabel.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: labelLeadingTrailingPadding).isActive = true
        currentTimeLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        currentTimeLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        videoDurationLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -labelBottomPadding).isActive = true
        videoDurationLabel.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -labelLeadingTrailingPadding).isActive = true
        videoDurationLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        videoDurationLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        let sliderHeight: CGFloat = 30
        let sliderBottomPadding: CGFloat = 32
        
        videoSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor).isActive = true
        videoSlider.trailingAnchor.constraint(equalTo: videoDurationLabel.leadingAnchor).isActive = true
        videoSlider.heightAnchor.constraint(equalToConstant: sliderHeight).isActive = true
        videoSlider.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -sliderBottomPadding).isActive = true
    }
}
