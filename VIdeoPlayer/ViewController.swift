//
//  ViewController.swift
//  VIdeoPlayer
//
//  Created by LanceMacBookPro on 3/26/22.
//

import UIKit
import AVFoundation
import os.log

class ViewController: UIViewController {
    
    // MARK: - UIElements - Player
    public lazy var avPlayerView: AVPlayerView = {
        let playerView = AVPlayerView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    
    public lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
    public lazy var spinner: UIActivityIndicatorView = {
        let actIndi = UIActivityIndicatorView(style: .large)
        actIndi.translatesAutoresizingMaskIntoConstraints = false
        actIndi.style = .medium
        actIndi.startAnimating()
        actIndi.color = .white
        return actIndi
    }()
    
    public lazy var pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(pauseIcon, for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(pausePlayButtonPressed), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        button.isHidden = true
        return button
    }()
    
    public lazy var replayButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "replayIcon"), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(replayButtonPressedRewindToBeginning), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        button.isHidden = true
        return button
    }()
    
    public lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text =  "0:00"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    public lazy var videoSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        let minTrckColor = UIColor.red
        slider.minimumTrackTintColor = minTrckColor
        slider.maximumTrackTintColor = UIColor.white
        slider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        slider.isEnabled = false
        return slider
    }()
    
    public lazy var videoDurationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = " 0:00"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    // MARK: - Properties - Player
    public var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    public var playerLayer: AVPlayerLayer?
    
    public var timeObserverToken: Any?
    
    public var playerStatusObserver: NSKeyValueObservation?
    public var playerRateObserver: NSKeyValueObservation?
    public var playerTimeControlStatusObserver: NSKeyValueObservation?
    public var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    public var playbackBufferEmptyObserver: NSKeyValueObservation?
    public var playbackBufferFullObserver: NSKeyValueObservation?
    //private var playerItemFailedToPlayToEndTimeObserver: NSObjectProtocol?
    public var playerItemPlaybackStalledObserver: NSObjectProtocol?
    public var playerItemNewError: NSObjectProtocol?
    
    public var playerTryCount = -1
    private let playerTryCountMaxLimit = 20
    
    private var isUserInteractingWithSlider = false
    
    public let playIcon = UIImage(named: "playIcon")
    public let pauseIcon = UIImage(named: "pauseIcon")
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        configurePlayer()
        
        setupUILayout()
        
        setAudioSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - AVAudioSession
    private func setAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            ViewController.log(function: #function, message: error.localizedDescription)
        }
    }
    
    // MARK: - OS_Log
    static func log(function: String, message: String) {
        os_log(.info, "[ViewController][%{public}@] %{public}@", function, message)
    }
    
    // MARK: - Deinit
    deinit {
        removePeriodicTimeObserver()
        removeNSKeyValueObservers()
    }
}

// MARK: - AVPlayer Creation
extension ViewController {
    
    private func configurePlayer() {
        
        guard let videoURL = Bundle.main.url(forResource: "skater", withExtension: "mp4") else { return }
        
        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let asset = AVURLAsset(url: videoURL, options: assetOpts)
        
        let assetKeys = ["playable", "duration", "tracks"]
        
        asset.loadValuesAsynchronously(forKeys: assetKeys) {
            
            var error: NSError? = nil
            for key in assetKeys {
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed || status == .cancelled {
                    ViewController.log(function: #function, message: "AVAsset keyName: \(key) - failed to load due to error: \(error?.localizedDescription as Any)")
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.setPlayerItem(with: asset)
            }
        }
    }
    
    private func setPlayerItem(with asset: AVURLAsset) {
        
        playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        player?.automaticallyWaitsToMinimizeStalling = false
        playerItem?.preferredForwardBufferDuration = TimeInterval(1.0)
        player?.volume = 1
        
        view.addSubview(avPlayerView)
        avPlayerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        avPlayerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        avPlayerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        avPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        playerLayer!.frame = avPlayerView.bounds
        avPlayerView.layer.addSublayer(playerLayer!)
        avPlayerView.playerLayer = playerLayer
        avPlayerView.layoutIfNeeded()
        
        setNSKeyValueObservers()
        
        player?.replaceCurrentItem(with: playerItem)
        
        setTimeObserverToken()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showReplayButton), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
}

// MARK: - Periodic Time Observer
extension ViewController {
    
    private func setTimeObserverToken() {
        
        guard let player = player else { return }
        guard let duration = player.currentItem?.asset.duration else { return }
        let durationSeconds: Float64 = CMTimeGetSeconds(duration)
        
        let interval = CMTime(value: 1, timescale: 30)
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: {
            [weak self] (progressTime) in
            guard let weakSelf = self else { return }
            
            let currentTime: Float64 = CMTimeGetSeconds(progressTime)
            
            guard !(currentTime.isNaN || currentTime.isInfinite) else { return }
            
            if player.currentItem?.status != .readyToPlay {
                ViewController.log(function: #function, message: "\n\ntimeObserver player-not-ready-yet -currentTime: \(currentTime) | playerTime: \(player.currentTime().seconds)\n\n")
                return
            }
            
            if weakSelf.isUserInteractingWithSlider { return }
            
            let secondsString = String(format: "%02d", Int(currentTime) % 60)
            
            self?.currentTimeLabel.text = " 0:\(secondsString)"
            
            self?.videoSlider.value = Float(currentTime / durationSeconds)
            
            ViewController.log(function: #function, message: "timeObserver -currentTime: \(currentTime) | playerTime: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))")
        })
    }
}

// MARK: - Target Actions - Player
extension ViewController {
    
    @objc private func pausePlayButtonPressed() {
        guard let player = player else { return }
        
        ViewController.log(function: #function, message: "\n\nbuttonPressed-1 -playerTime: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))")
        
        if player.timeControlStatus == .playing {
            
            player.pause()
            pausePlayButton.setImage(playIcon, for: .normal)
            
        } else {
            
            player.play()
            pausePlayButton.setImage(pauseIcon, for: .normal)
        }
        
        ViewController.log(function: #function, message: "\n\nbuttonPressed-2 -playerTime: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))\n\n")
    }
}

// MARK: - KVO
extension ViewController {
    
    private func setNSKeyValueObservers() {
        
        playerStatusObserver = player?.observe(\.currentItem?.status, options: [.new, .old, .initial]) {
            [weak self] (player, change) in
            
            switch (player.status) {
            case .readyToPlay:
                ViewController.log(function: #function, message: "status - Media Ready to Play-: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))\n")
                DispatchQueue.main.async { [weak self] in
                    self?.showPlayButtonAndLoadTimeLabels()
                }
            case .failed, .unknown:
                ViewController.log(function: #function, message: "status - Media Failed to Play\n")
            @unknown default:
                break
            }
        }
        
        playerRateObserver = player?.observe(\.rate, options:  [.new, .old], changeHandler: { (player, change) in
            if player.rate == 1  {
                ViewController.log(function: #function, message: "rate - player is playing -: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))")
            } else {
                ViewController.log(function: #function, message: "rate - ptop is stopped -: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))")
            }
        })
        
        // TimeControl Status
        playerTimeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new, .old]) {
            [weak self](player, change) in
            
            switch (player.timeControlStatus) {
            
            case .playing:
                ViewController.log(function: #function, message: "\n\ntimeControlStatus -player is playing -playerTime: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))\n\n")
                
            case .paused:
                ViewController.log(function: #function, message: "\n\ntimeControlStatus -player is paused -playerTime: \(player.currentTime().seconds) | getSsecs: \(CMTimeGetSeconds(player.currentTime()))\n\n")
                
            case .waitingToPlayAtSpecifiedRate:
                ViewController.log(function: #function, message: "timeControlStatu .waitingToPlayAtSpecifiedRate")
                
                if let reason = player.reasonForWaitingToPlay {
                    
                    switch reason {
                    case .evaluatingBufferingRate:
                        ViewController.log(function: #function, message: "timeControlStatu .evaluatingBufferingRate")
                        
                    case .toMinimizeStalls:
                        ViewController.log(function: #function, message: "timeControlStatu .toMinimizeStalls")
                        
                    case .noItemToPlay:
                        ViewController.log(function: #function, message: "timeControlStatu .noItemToPlay")
                        DispatchQueue.main.async { [weak self] in
                            self?.showSpinnerSlowly()
                        }
                    default:
                        ViewController.log(function: #function, message: "timeControlStatus -Unknown \(reason)")
                    }
                }
            @unknown default:
                break
            }
        }
        
        playbackLikelyToKeepUpObserver = player?.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.old, .new]) {
            (playerItem, change) in
        }
        
        playbackBufferEmptyObserver = player?.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.old, .new]) {
            (playerItem, change) in
        }
        
        playbackBufferFullObserver = player?.currentItem?.observe(\.isPlaybackBufferFull, options: [.old, .new]) {
            (playerItem, change) in
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemNewError(_:)),
                                               name: .AVPlayerItemNewErrorLogEntry,
                                               object: playerItem)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemFailedToPlayToEndTime(_:)),
                                               name: .AVPlayerItemFailedToPlayToEndTime,
                                               object: playerItem)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemPlaybackStalled(_:)),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: playerItem)
    }
}

// MARK: - KVO - Status .readyToPlay - Method
extension ViewController {
    
    private func showPlayButtonAndLoadTimeLabels() {
        
        spinner.stopAnimating()
        
        videoSlider.isEnabled = true
        
        let duration: CMTime = player?.currentItem?.duration ?? .zero
        let seconds:Float64 = CMTimeGetSeconds(duration)
        let secondsText = String(format: "%02d", Int(seconds) % 60)
        
        videoDurationLabel.text = " 0:\(secondsText)"
        
        pausePlayButton.setImage(pauseIcon, for: .normal)
        player?.play()
        pausePlayButton.isHidden = false
    }
}

// MARK: - KVO - Supporting Methods
extension ViewController {
    
    @objc func showSpinnerSlowly() {
        
        if player?.timeControlStatus == .playing { return }
        
        controlsContainerView.isUserInteractionEnabled = false
        spinner.startAnimating()
        pausePlayButton.isHidden = true
    }
    
    @objc func playerIsHangingShowSpinner() {
        
        controlsContainerView.isUserInteractionEnabled = false
        
        spinner.startAnimating()

        pausePlayButton.isHidden = true
    }
    
    @objc private func playerItemNewError(_ notification: Notification) {
        if let error = notification.userInfo?.first(where: { $0.value is Error }) as? Error {
            ViewController.log(function: #function, message: "---> playerItemNewError: \(error.localizedDescription)")
        }
    }
    
    @objc private func playerItemFailedToPlayToEndTime(_ notification: Notification) {
        if let error = notification.userInfo?["AVPlayerItemFailedToPlayToEndTime"] as? Error {
            ViewController.log(function: #function, message: "---> \(error.localizedDescription)")
        }
    }
    
    @objc private func playerItemPlaybackStalled(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        
        if (!playerItem.isPlaybackLikelyToKeepUp)
            && (CMTimeCompare(playerItem.currentTime(), .zero) == 1)
            && (CMTimeCompare(playerItem.currentTime(), playerItem.duration) != 0) {
            ViewController.log(function: #function, message: "---> isPlaybackLikelyToKeepUp -False")
            
            DispatchQueue.main.async { [weak self] in
                self?.playerIsHanging()
            }
        }
    }
    
    private func playerIsHanging() {
        
        if playerTryCount <= playerTryCountMaxLimit {
            
            playerTryCount += 1
            playerIsHangingShowSpinner()
            checkPlayerTryCount()
        }
    }
    
    private func checkPlayerTryCount() {
        
        guard let player = player, let playerItem = player.currentItem else { return }
        
        if CMTimeCompare(playerItem.currentTime(), playerItem.duration) == 0 {
            
            stopSpinnerShowReplayButton()
            
        } else if playerTryCount > playerTryCountMaxLimit {
            
            playerIsHangingShowSpinner()
            
        } else if playerTryCount == 0 {
            
            playerTryCount += 1
            retryCheckPlayerTryCountAgain()
            return
            
        } else if playerItem.isPlaybackLikelyToKeepUp {
            
            playPlayer()
            
        } else {
            
            playerTryCount += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.main.async { [weak self] in
                    guard let safeSelf = self else { return }
                    
                    if safeSelf.playerTryCount > 0 {
                        
                        if safeSelf.playerTryCount <= safeSelf.playerTryCountMaxLimit {
                            
                            self?.retryCheckPlayerTryCountAgain()
                            
                        } else {
                            
                            self?.playPlayer()
                        }
                    }
                }
            }
        }
    }
    
    private func retryCheckPlayerTryCountAgain() {
        checkPlayerTryCount()
    }
}

// MARK:- Slider Methods
extension ViewController {
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                
                isUserInteractingWithSlider = true
                player?.pause()
                
            case .moved:
                
                handleSliderChanged()
                
            case .ended, .cancelled:
                
                fingerLiftedFromSlider()
                
            default: break
            }
        }
    }
    
    @objc private func handleSliderChanged() {
        
        guard let player = player else { return }
        let playerItemDuration = player.currentItem?.duration ?? .zero
        let duration: Float64 = CMTimeGetSeconds(playerItemDuration)
        let sliderValueMultipliedByDuration: Double = Float64(videoSlider.value) * duration
        
        setPlayerSeekTImeAndCurrentTimeAndLabel(player, sliderValueMultipliedByDuration: sliderValueMultipliedByDuration)
        
        buttonsToShoWhileScrubbing()
    }
    
    private func setPlayerSeekTImeAndCurrentTimeAndLabel(_ player: AVPlayer, sliderValueMultipliedByDuration: Double) {
        
        let secondsString = String(format: "%02d", Int(sliderValueMultipliedByDuration) % 60)
        currentTimeLabel.text = " 0:\(secondsString)"
        
        let seekTime: CMTime = CMTimeMakeWithSeconds(sliderValueMultipliedByDuration, preferredTimescale: 1000)
        player.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    private func fingerLiftedFromSlider() {
        
        isUserInteractingWithSlider = false
        
        buttonsToShoWhileScrubbing()
    }
    
    private func buttonsToShoWhileScrubbing() {
        
        guard let player = player else { return }
        let currentTime: Float64 = CMTimeGetSeconds(player.currentTime())
        let playerItemDuration = player.currentItem?.duration ?? .zero
        let duration: Float64 = CMTimeGetSeconds(playerItemDuration)
        let sliderValueMultipliedByDuration: Double = Float64(videoSlider.value) * duration
        
        if currentTime >= duration || sliderValueMultipliedByDuration >= Double(duration) || videoSlider.value >= 1 {
            
            showReplayButton()
            
        } else {
            
            pausePlayButton.setImage(playIcon, for: .normal)
            unhidePausePlayHideReplayButton()
        }
    }
}

//MARK:- Notifications
extension ViewController {
    
    private func configureNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    @objc private func appWillEnterBackground() {
        
        pausePlayerAndShowPlayIcon()
    }
}
