//
//  ViewController.swift
//  SimpleMovieEncoding
//
//  Created by Josh Bernfeld on 4/1/18.
//  Copyright © 2018 Sunset Lake Software LLC. All rights reserved.
//

import UIKit
import GPUImage
import CoreAudio
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var progressView:UIProgressView!
    
    var movieInput:MovieInput!
    var movieOutput:MovieOutput!
    var filter:MissEtikateFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let bundleURL = Bundle.main.resourceURL!
        // The movie you want to reencode
        let movieURL = URL(string:"sample_iPod.m4v", relativeTo:bundleURL)!
        
        let documentsDir = FileManager().urls(for:.documentDirectory, in:.userDomainMask).first!
        // The location you want to save the new video
        let exportedURL = URL(string:"test.mp4", relativeTo:documentsDir)!
        
        let inputOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:NSNumber(value:true)]
        let asset = AVURLAsset(url:movieURL, options:inputOptions)
        
        guard let videoTrack = asset.tracks(withMediaType:AVMediaType.video).first else { return }
        let audioTrack = asset.tracks(withMediaType:AVMediaType.audio).first
        
        let audioDecodingSettings:[String:Any]?
        let audioEncodingSettings:[String:Any]?
        var audioSourceFormatHint:CMFormatDescription? = nil
        
        let shouldPassthroughAudio = false
        if(shouldPassthroughAudio) {
            audioDecodingSettings = nil
            audioEncodingSettings = nil
            // A format hint is required when writing to certain file types with passthrough audio
            // A conditional downcast would not work here for some reason
            if let description = audioTrack?.formatDescriptions.first { audioSourceFormatHint = (description as! CMFormatDescription) }
        }
        else {
            audioDecodingSettings = [AVFormatIDKey:kAudioFormatLinearPCM] // Noncompressed audio samples
            var acl = AudioChannelLayout()
            memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
            audioEncodingSettings = [
                AVFormatIDKey:kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey:2,
                AVSampleRateKey:AVAudioSession.sharedInstance().sampleRate,
                AVChannelLayoutKey:NSData(bytes:&acl, length:MemoryLayout<AudioChannelLayout>.size),
                AVEncoderBitRateKey:96000
            ]
            audioSourceFormatHint = nil
        }
        
        do {
            movieInput = try MovieInput(asset:asset, videoComposition:nil, playAtActualSpeed:false, loop:false, audioSettings:audioDecodingSettings)
        }
        catch {
            print("ERROR: Unable to setup MovieInput with error: \(error)")
            return
        }
        
        try? FileManager().removeItem(at: exportedURL)
        
        let videoEncodingSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [
                AVVideoExpectedSourceFrameRateKey:videoTrack.nominalFrameRate,
                AVVideoAverageBitRateKey:videoTrack.estimatedDataRate,
                AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel,
                AVVideoH264EntropyModeKey:AVVideoH264EntropyModeCABAC,
                AVVideoAllowFrameReorderingKey:videoTrack.requiresFrameReordering],
            AVVideoCodecKey:AVVideoCodecH264]
        
        do {
            movieOutput = try MovieOutput(URL: exportedURL, size:Size(width:Float(videoTrack.naturalSize.width), height:Float(videoTrack.naturalSize.height)), fileType:.mp4, liveVideo:false, videoSettings:videoEncodingSettings, videoNaturalTimeScale:videoTrack.naturalTimeScale, audioSettings:audioEncodingSettings, audioSourceFormatHint:audioSourceFormatHint)
        }
        catch {
            print("ERROR: Unable to setup MovieOutput with error: \(error)")
            return
        }
        
        filter = MissEtikateFilter()
        
        if(audioTrack != nil) { movieInput.audioEncodingTarget = movieOutput }
        movieInput.synchronizedMovieOutput = movieOutput
        //movieInput.synchronizedEncodingDebug = true
        movieInput --> filter --> movieOutput
        
        movieInput.completion = {
            self.movieOutput.finishRecording {
                self.movieInput.audioEncodingTarget = nil
                self.movieInput.synchronizedMovieOutput = nil
                
                DispatchQueue.main.async {
                    print("Encoding finished")
                }
            }
        }
        movieInput.progress = { progressVal in
            DispatchQueue.main.async {
                self.progressView.progress = Float(progressVal)
            }
        }
        
        movieOutput.startRecording { started, error in
            if(!started) {
                print("ERROR: MovieOutput unable to start writing with error: \(String(describing: error))")
                return
            }
            self.movieInput.start()
            print("Encoding started")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

