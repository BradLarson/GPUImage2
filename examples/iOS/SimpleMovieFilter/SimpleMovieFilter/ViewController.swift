import UIKit
import GPUImage
import CoreAudio
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!
    
    var movie:MovieInput!
    var filter:Pixellate!
    var speaker:SpeakerOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bundleURL = Bundle.main.resourceURL!
        let movieURL = URL(string:"sample_iPod.m4v", relativeTo:bundleURL)!
        
        do {
            let audioDecodeSettings = [AVFormatIDKey:kAudioFormatLinearPCM]
            
            movie = try MovieInput(url:movieURL, playAtActualSpeed:true, loop:true, audioSettings:audioDecodeSettings)
            speaker = SpeakerOutput()
            movie.audioEncodingTarget = speaker
            
            filter = Pixellate()
            movie --> filter --> renderView
            movie.runBenchmark = true
            
            movie.start()
            speaker.start()
        } catch {
            print("Couldn't process movie with error: \(error)")
        }

//            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
//            let fileURL = NSURL(string:"test.png", relativeToURL:documentsDir)!
//            try pngImage.writeToURL(fileURL, options:.DataWritingAtomic)
    }
    
    @IBAction func pause() {
        movie.pause()
        speaker.cancel()
    }
    
    @IBAction func cancel() {
        movie.cancel()
        speaker.cancel()
    }
    
    @IBAction func play() {
        movie.start()
        speaker.start()
    }
}

