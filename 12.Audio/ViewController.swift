//
//  ViewController.swift
//  12.Audio
//
//  Created by 이병현 on 2022/04/14.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var audioPlayer : AVAudioPlayer! // AVAudioPlayer 인스턴스 변수
    var audioFile : URL! // 재생할 오디오의 파일명 변수
    let MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수
    var progressTimer : Timer! // 타이머를 위한 변수
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)

    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblEndTime: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var slVolume: UISlider!
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!
    
    var audioRecord : AVAudioRecorder! // audioRecorder 인스턴스 추가
    var isRecordMode = false // 현재 녹음모드라는 것을 나타낼 isRecordMode를 추가 기본값을 false로 설정
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectAudioFile()
        if !isRecordMode {
        initPlay() // if문의 조건이 !isRecordMode 임. 녹음 모드가 아니라면 이므로 재생모드를 의미함.
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false // 조건에 해당하는 것이 재생모드이므로 Record 버튼과 재생 시간은 비활성화
        } else {
            initRecord() // 조건에 해당하지 않는 경우, 이는 녹음모드이므로 initRecord 함수 불러옴
        }
    }
    
    func selectAudioFile() {
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3")
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] // 재생 모드일 때는 오디오 파일인 Sicilian_Breeze.mp3가 선택됌
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
            // 녹음 모드일 때는 새 파일인 "recordFile.m4a"가 생성
        }
    }
    
    func initRecord() {
        let recordSettings = [
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0] as [String : Any]
        do {
            audioRecord = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        
        slVolume.value = 1.0 // 볼륨 슬라이더 값을 1.0으로 설정
        audioPlayer.volume = 1.0 // audioPlayer의 볼륨도 슬라이더 값과 동일한 1.0으로 설정
        lblEndTime.text = convertNSTimeInterval2Sring(0) // 총 재생시간을 0으로 바꿈
        lblCurrentTime.text = convertNSTimeInterval2Sring(0) // 현재 재생시간을 0으로 바꿈
        setPlayButtons(false, pause: false, stop: false) // Play, Pause, Stop 버튼을 비활성화로 설정
        
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error-setCategory: \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive : \(error)")
        }
    }
    
    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        slVolume.maximumValue = MAX_VOLUME // 슬라이더의 최대 볼륨을 상수 MAX_VOLUME인 10.0으로 초기화
        slVolume.value = 1.0 // 슬라이더의 볼륨을 1.0으로 초기화
        pvProgressPlay.progress = 0 // 프로그레스 뷰의 진행을 0으로 초기화
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트를 self로 함
        audioPlayer.prepareToPlay() // prepareToPlay()을 실행함
        audioPlayer.volume = slVolume.value // audioPlayer의 볼륨을 방금 앞에서 초기화한 슬라이더의 볼륨값 1.0으로 초기화함
        
        lblEndTime.text = convertNSTimeInterval2Sring(audioPlayer.duration)
        // 오디오 파일의 재생시간인 audioPlayer.duration 값을 convertNS..함수를 이용해 lblEndTime의 텍스트에 출력
        lblCurrentTime.text = convertNSTimeInterval2Sring(0)
        // lblCurrentTime의 텍스트에는 convertNS...함수를 이용해 00:00 가 출력되도록 0의 값을 입력
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func setPlayButtons (_ play:Bool, pause:Bool, stop:Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2Sring(_ time: TimeInterval) -> String {
        let min = Int(time/60) // 재생 시간의 매개변수인 time의 값을 60으로 나눈 몫을 상수 min에 초기화
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) // time을 60으로 나눈 나머지를 sec 값에 초기화
        let strTime = String(format: "%02d:%02d", min, sec) // 두 값을 활용해 02d:02d 형태의 문자열로 변환하여 초기화
        return strTime // 이 값을 호출한 함수에 돌려보냄
    }
    
    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play() // audioPlayer 함수를 실행해 오디오를 재생
        setPlayButtons(false, pause: true, stop: true) // Play 버튼은 비활성화, 나머지 두 버튼은 활성화
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @objc func updatePlayTime() {
        lblCurrentTime.text = convertNSTimeInterval2Sring(audioPlayer.currentTime)
        // 재생시간인 audioPlayer.currentTime을 레이블 lblCurrentTime에 나타냄
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
        // 프로그레스 뷰인 pvProgress Play 진행상황에 audioPlayer.currentTime을 audioPlayer.duration으로 나눈 값으로 표시
    }
    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
    }
    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0 // 오디오를 정지하고 다시 재생하면 처음부터 재생해야 하므로 현재시간을 0으로 변경
        lblCurrentTime.text = convertNSTimeInterval2Sring(0) // 재생 시간도 00:00으로 초기화하기 위해 conv..(0)활용
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머도 무효화함
    }
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate() // 타이머를 무효화함
        setPlayButtons(true, pause: false, stop: false) // Play 버튼은 활성화, 나머지 버튼은 비활성화
    }

    @IBAction func swRecordMode(_ sender: UISwitch) {
    }
    @IBAction func btnRecord(_ sender: UIButton) {
    }
    
    
}

