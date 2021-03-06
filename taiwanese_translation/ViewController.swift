//
//  ViewController.swift
//  taiwanese_translation
//
//  Created by Mac OS on 2018/7/28.
//  Copyright © 2018年 taiwanspeech. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftSocket

class ViewController: UIViewController,AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var play_btn_ref: UIButton!
    @IBOutlet weak var record_btn_ref: UIButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var recognized_text: UITextField!
    @IBOutlet weak var upload_btn_ref: UIButton!
    
    @IBOutlet weak var recognized_text2: UITextField!
    @IBOutlet weak var recognized_text3: UITextField!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var meterTimer:Timer!
    var isAudioRecordingGranted:Bool!
    var isRecording = false
    var isPlaying = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        check_record_permission()
        //var iStream: InputStream? = nil
        //var oStream: OutputStream? = nil
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func check_record_permission(){
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSessionRecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL
    {
        let filename = "myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func setup_recorder()
    {
        if isAudioRecordingGranted
        {
            let session = AVAudioSession.sharedInstance()
            do
            {
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
            }
            catch let error {
                display_alert(msg_title: "Error", msg_desc: error.localizedDescription, action_title: "OK")
            }
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Don't have access to use your microphone.", action_title: "OK")
        }
    }
    
    //MARK: Actions
    
    @IBAction func playaudio(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            if let url = Bundle.main.url(forResource: "3_1", withExtension: "wav") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case 1:
            if let url = Bundle.main.url(forResource: "3_2", withExtension: "wav") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case 2:
            if let url = Bundle.main.url(forResource: "3_3", withExtension: "wav") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        default:
            break
        }
        
    }
    
    @IBAction func start_recording(_ sender: UIButton) {
        if(isRecording)
        {
            finishAudioRecording(success: true)
            sender.setTitle("錄音", for: .normal)
            play_btn_ref.isEnabled = true
            isRecording = false
        }
        else
        {
            setup_recorder()
            
            audioRecorder.record()
            meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            sender.setTitle("停止", for: .normal)
            play_btn_ref.isEnabled = false
            isRecording = true
        }
    }
    @objc func updateAudioMeter(timer: Timer)
    {
        if audioRecorder.isRecording
        {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel.text = totalTimeString
            audioRecorder.updateMeters()
        }
    }
    func finishAudioRecording(success: Bool)
    {
        if success
        {
            audioRecorder.stop()
            audioRecorder = nil
            meterTimer.invalidate()
            print("recorded successfully.")
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Recording failed.", action_title: "OK")
        }
    }
    //Play the recording
    func prepare_play()
    {
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch{
            print("Error")
        }
    }
    
    @IBAction func play_recording(_ sender: Any) {
        if(isPlaying)
        {
            audioPlayer.stop()
            record_btn_ref.isEnabled = true
            play_btn_ref.setTitle("Play", for: .normal)
            isPlaying = false
        }
        else
        {
            if FileManager.default.fileExists(atPath: getFileUrl().path)
            {
                record_btn_ref.isEnabled = false
                play_btn_ref.setTitle("pause", for: .normal)
                prepare_play()
                audioPlayer.play()
                isPlaying = true
            }
            else
            {
                display_alert(msg_title: "Error", msg_desc: "Audio file is missing.", action_title: "OK")
            }
        }
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if !flag
        {
            finishAudioRecording(success: false)
        }
        play_btn_ref.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        record_btn_ref.isEnabled = true
    }
    
    func display_alert(msg_title : String , msg_desc : String ,action_title : String)
    {
        let ac = UIAlertController(title: msg_title, message: msg_desc, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: action_title, style: .default)
        {
            (result : UIAlertAction) -> Void in
            _ = self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }
    func textchange(text: String,sender:Int){
        DispatchQueue.main.async{
            switch sender{
            case 0:
                self.recognized_text.text = text
            case 1:
                self.recognized_text2.text = text
            default:
                self.recognized_text3.text = text
            }
            
        }
    }
    
    @IBAction func uploadfile(_ sender: UIButton) {
        if FileManager.default.fileExists(atPath: getFileUrl().path)
        {
            //金鑰
            let token:String=""
            //選用模組,之後有針對醫療詞彙加強會更改main的字串
            var data:String = token+String("@@@main    A")
            
            sender.isEnabled = false
            let fileURL = getFileUrl()
            
            do{
                //音檔
                let audioData = try Data(contentsOf: fileURL)
                let mydata = Data(data.utf8)+audioData
                //**data count要用big endian並大小為4bytes
                var count = UInt32(mydata.count).bigEndian
                let datacount = Data(bytes: &count ,
                                     count: 4)
                //print(MemoryLayout.size(ofValue: count))
                
                
                let client = TCPClient(address: "140.116.245.149", port: 2802)
                switch client.connect(timeout: 5) {
                case .success:
                    switch client.send(data : datacount+mydata) {
                    case .success:
                        guard let data = client.read(1024,timeout: 10) else { return }

                        if let response = String(bytes: data, encoding: .utf8) {
                            let splitarray = response.components(separatedBy: "result:")
                            
                            //輸出
                            //print("responseString = \(String(describing: splitarray[0]))")
                            self.textchange(text: splitarray[0],sender: sender.tag)
                            sender.isEnabled = true
                        }
                    case .failure(let error):
                        print(error)
                    }
                case .failure(let error):
                    print(error)
                }
                
                
            }catch{
                print("error")
            }
            
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Audio file has not been recorded yet!", action_title: "OK")
        }
    }
}

