import UIKit
import AVFoundation
import Accelerate
import Surge

class ViewController: UIViewController {

    @IBOutlet weak var tapInstructionLabel: UILabel!
    @IBOutlet weak var imageButton: UIButton!
    
    @IBOutlet weak var successImage: UIImageView!
    var audioRecorder: AVAudioRecorder? = nil
    
    let RANGE : [Float] = [Float](arrayLiteral: 40.0, 80.0, 120.0, 180.0, 300.0)
    
    let onlyFools = [Float](arrayLiteral: 12500000.0, 25.0, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 0.0)
    let theApprentice = [Float](arrayLiteral: 2.30000005e+10, 50.0, 35.0, 20.0, 15.0, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 3.00180132e+10, 0.0)
    
    let recordSettings = [
        AVFormatIDKey : kAudioFormatAppleLossless as AnyObject,
        AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue as AnyObject,
        AVEncoderBitRateKey : 320000 as AnyObject,
        AVNumberOfChannelsKey : 2 as AnyObject,
        AVSampleRateKey : 44100.0 as AnyObject
    ] as [String : AnyObject]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapInstructionLabel.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func tappedImage(_ sender: Any) {
        let alert = UIAlertController(title: "Listening", message: "listening", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Stop", style: UIAlertActionStyle.default, handler: stopRecording))
        self.present(alert, animated: true, completion: nil)
        startListening()
    }
    
    func startListening() {
        record()
    }
    
    func prepareToRecord() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let soundFileURL: NSURL? = NSURL.fileURL(withPath: "\(documentsPath)/recording.caf") as NSURL?
        
        do {
            try self.audioRecorder = AVAudioRecorder(url: soundFileURL! as URL, settings: recordSettings)
            if let recorder = self.audioRecorder {
                recorder.prepareToRecord()
            }
        } catch {
            
        }
    }
    
    func record() {
        prepareToRecord()
        if let recorder = self.audioRecorder {
            recorder.record()
        }
    }
    
    func stopRecording(action : UIAlertAction) -> Void {
        if let recorder = self.audioRecorder {
            recorder.stop()
        }
        matchWithThemeTunes()
    }
    
    func matchWithThemeTunes() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let soundFileURL: URL = NSURL.fileURL(withPath: "\(documentsPath)/recording.caf")
        
        do {
            let savedRecording = try! AVAudioFile(forReading: soundFileURL)
            let fileFormat = savedRecording.processingFormat
            let frameCount = UInt32(savedRecording.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount)
            
            do {
                try savedRecording.read(into: buffer, frameCount:frameCount)
            } catch {
                
            }
            
            let numberOfChunks = buffer.frameLength / 50000
            
            var results = [[Float]](repeating: [Float](repeating: 0.0, count: 100000), count: Int(numberOfChunks))
            
            let floatBuffer = convertBufferToFloat(buffer: buffer)
            
            for chunk in 0...numberOfChunks - 1 {
                var chunkArray = [Float](repeating: 0.0, count: 50000)
                for index in  0...49999 {
                    chunkArray[index] = Float(floatBuffer[(Int(chunk)*index)+1])
                }
                results[Int(chunk)] = Surge.fft(chunkArray)
            }
            
            var highScores = [[Float]](repeating: [Float](repeating: 0.0, count: 5), count: Int(numberOfChunks))
            var recordPoints = [[Float]](repeating: [Float](repeating: 0.0, count: 5), count: Int(numberOfChunks))
            
            for someArray in 0 ..< results.count - 1 {
                
                var freqArray : [Float] = results[someArray]
                
                var highScore = [Float](repeating: 0.0, count: 5)
                var recordPoint = [Float](repeating: 0.0, count: 5)
                
                for freq in 0..<freqArray.count - 1 {
                    let mag = round(log2f(abs(freqArray[freq]) + 1) * 100000)
                    let index = getIndex(freq: mag)
                    
                    if (mag > highScore[index]) {
                        highScore[index] = mag
                        recordPoint[index] = Float(freq)
                    }
                }
                
                highScores[someArray] = highScore
                recordPoints[someArray] = recordPoint
            }
            
            var hashes = [Float](repeating: 0.0, count: highScores.count)
            
            for highScore in 0...highScores.count - 1 {
                hashes[highScore] = getHash(floats: highScores[highScore])
            }
            
            var apprenticeScore : Float = 0.0
            var lowestApprenticeScore : Float = 0.0
            for hash in 0...hashes.count - 1 {
                for apprentice in 0...theApprentice.count - 1 {
                    let hashValue = hashes[hash]
                    apprenticeScore += theApprentice[apprentice] - hashValue
                    let diff = hashes[hash] - theApprentice[apprentice]
                    if (lowestApprenticeScore == 0) {
                        lowestApprenticeScore = diff
                    } else if (diff < lowestApprenticeScore) {
                        lowestApprenticeScore = diff
                    }
                }
            }
            
            var onlyFoolsScore : Float = 0.0
            var lowestOnlyFoolsScore : Float = 0.0
            for hash in 0...hashes.count - 1 {
                for onlyFoolsIndex in 0...onlyFools.count - 1 {
                    let hashValue = hashes[hash]
                    onlyFoolsScore += onlyFools[onlyFoolsIndex] - hashValue
                    let diff = hashes[hash] - onlyFools[onlyFoolsIndex]
                    if (lowestOnlyFoolsScore == 0) {
                        lowestOnlyFoolsScore = diff
                    } else if (diff < lowestOnlyFoolsScore) {
                        lowestOnlyFoolsScore = diff
                    }
                }
            }

            
            if (onlyFoolsScore < 0) {
                onlyFoolsScore = onlyFoolsScore * -1
            }
            
            if (apprenticeScore < 0) {
                apprenticeScore = apprenticeScore * -1
            }
            
            if (onlyFoolsScore < apprenticeScore) {
                print ("This theme tune is Only Fools and Horses")
                successImage.image = UIImage(named: "onlyfools")
            } else {
                print ("This theme tune is The Apprentice")
                successImage.image = UIImage(named: "apprentice")
            }
        } catch {
            
        }
    }

    func getHash(floats : [Float]) -> Float {
        let FUZZY : Float = 5.0
        return (floats[3]-((floats[3]).truncatingRemainder(dividingBy: FUZZY))) * 100000000 + (floats[2]-((floats[2]).truncatingRemainder(dividingBy: FUZZY))) * 100000 + (floats[1]-((floats[1]).truncatingRemainder(dividingBy: FUZZY))) * 100 + (floats[0]-((floats[0]).truncatingRemainder(dividingBy: FUZZY)))
    }
    
    func getIndex(freq : Float) -> Int {
        if (RANGE[4] < freq) {
            return 4
        } else if (RANGE[3] < freq) {
            return 3
        } else if (RANGE[2] < freq) {
            return 2
        } else if (RANGE[1] < freq) {
            return 1
        }
        return 0;
    }
    
    func convertBufferToFloat(buffer: AVAudioPCMBuffer) -> [Float]{
        var bufferInFloat = [Float](repeating: 0.0, count: Int(buffer.frameLength))
        
        for i: Int in 0 ..< Int(buffer.frameLength) {
            bufferInFloat[i] = (buffer.floatChannelData?.pointee[i])!
        }
        
        return bufferInFloat
    }
}

