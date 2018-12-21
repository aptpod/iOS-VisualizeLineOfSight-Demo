//
//  ViewController.swift
//  VisualizeLineOfSight-Demo
//
//  Created by aptueno on 2018/12/08.
//  Copyright © 2018 aptpod,Inc. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {
    
    let ACTIVATE_VALUE_CHECK_TIMER: Bool = true
    let VALUE_CHECK_TIMER_INTERVAL: TimeInterval = 2.0
    let DATE_FORMAT_STRING = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss.SSS", options: 0, locale: NSLocale.current)
    let REPLAY_THREAD_INTERVAL: TimeInterval = 0.001
    
    struct LineOfSightUnit {
        var timeStamp: TimeInterval
        var faceEyeTransform: simd_float4x4
        var leftEyeTransform: simd_float4x4
        var rightEyeTransform: simd_float4x4
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var unitStatusLabel: UILabel!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var replayBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    
    @IBOutlet weak var leftEyeXView: VisualizeDegreesView!
    @IBOutlet weak var leftEyeXLabel: UILabel!
    @IBOutlet weak var leftEyeYView: LeftVisualizeDegreesView!
    @IBOutlet weak var leftEyeYLabel: UILabel!
    @IBOutlet weak var rightEyeXView: VisualizeDegreesView!
    @IBOutlet weak var rightEyeXLabel: UILabel!
    @IBOutlet weak var rightEyeYView: RightVisualizeDegreesView!
    @IBOutlet weak var rightEyeYLabel: UILabel!
    
    var faceNode = SCNNode()
    var faceTargetNode = SCNNode()
    
    // ARSession
    let session = ARSession()
    var isRunning: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.pauseBtn.setTitle(self.isRunning ? "PAUSE" : "START", for: .normal)
                self.recordBtn.isEnabled = self.isRunning
                self.replayBtn.isEnabled = self.isRunning && self.recordedList.count > 0
                if self.isRunning {
                    if !self.isRecording, !self.isReplay {
                        self.statusLabel.text = "LIVE"
                        self.unitStatusLabel.isHidden = true
                    }
                    self.statusLabel.backgroundColor = UIColor.init(red: 215/255.0, green: 62/255.0, blue: 133/255.0, alpha: 1.0)
                } else {
                    self.statusLabel.backgroundColor = UIColor.init(white: 151/255.0, alpha: 1.0)
                }
            }
        }
    }
    
    var lastLineOfSightObj: LineOfSightUnit?
    
    lazy var timeFormat: DateFormatter = DateFormatter()
    
    var valueCheckTimer: Timer?
    
    // Recorder
    var isRecording: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.recordBtn.setTitle(self.isRecording ? "STOP RECORDING" : "START RECORDING", for: .normal)
                self.replayBtn.isEnabled = !self.isRecording && self.recordedList.count > 0
                if self.isRecording {
                    self.statusLabel.text = "REC"
                    self.unitStatusLabel.isHidden = false
                }
            }
        }
    }
    var baseTime: TimeInterval? = nil
    var recordedList: [LineOfSightUnit] = [LineOfSightUnit]()
    
    // Replay
    var isReplay: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.replayBtn.setTitle(self.isReplay ? "STOP REPLAY" : "START REPLAY", for: .normal)
                self.recordBtn.isEnabled = !self.isReplay
                if self.isReplay {
                    self.statusLabel.text = "REPLAY"
                    self.unitStatusLabel.isHidden = false
                }
            }
        }
    }
    var replayCnt: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Not supported ARFaceTracking process.")
            AlertDialog.show(viewController: self, title: "Error", message: "Not supported ARFaceTracking process.")
            self.replayBtn.isEnabled = false
            self.recordBtn.isEnabled = false
            self.pauseBtn.isEnabled = false
            return
        }
        
        // Face Target
        self.faceTargetNode.position = SCNVector3(x: 0, y: 0, z: 1)
        self.faceNode.addChildNode(self.faceTargetNode)
        
        // Time Format
        self.timeFormat.dateFormat = DATE_FORMAT_STRING
        self.replayBtn.isEnabled = false
        self.session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    // Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

//MARK:- ViewEvents
extension ViewController {
    
    @IBAction func replayBtnPushed(_ sender: Any) {
        print("replayBtnPushed()")
        if !self.isReplay {
            self.session.pause()
            self.startReplay()
        } else {
            self.stopReplay()
            self.resetTracking()
        }
    }
    
    @IBAction func recordBtnPushed(_ sender: Any) {
        print("recordBtnPushed()")
        if !self.isRecording {
            self.startRecording()
        } else {
            self.stopRecording()
            self.resetTracking()
        }
    }
    
    @IBAction func pauseBtnPushed(_ sender: Any) {
        print("pauseBtnPushed()")
        if self.isRunning {
            self.isRunning = false
            self.session.pause()
            self.valueCheckTimer?.invalidate()
            self.valueCheckTimer = nil
        } else {
            self.isRunning = true
            if self.isReplay {
                self.startReplay()
            } else {
                self.resetTracking()
            }
        }
    }
    
}


//MARK:- Recorder
extension ViewController {
    
    func startRecording() {
        self.recordedList.removeAll()
        self.baseTime = nil
        self.isRecording = true
    }
    
    func stopRecording() {
        self.isRecording = false
    }
    
    func startReplay() {
        self.isReplay = true
        var delay: TimeInterval = 0
        DispatchQueue.global().async {
            while(self.isReplay) {
                guard self.isReplay, let baseTime = self.baseTime, self.recordedList.count > 0, self.isRunning else {
                    Thread.sleep(forTimeInterval: self.REPLAY_THREAD_INTERVAL)
                    continue
                }
                let obj = self.recordedList[self.replayCnt]
                DispatchQueue.main.async {
                    // Current Time
                    self.currentTimeLabel.text = (obj.timeStamp - baseTime).timeString
                    // Units Status
                    self.unitStatusLabel.text = "\(self.replayCnt.commaString) / \(self.recordedList.count.commaString) units"
                    // Face Transform
                    self.faceNode.simdTransform = obj.faceEyeTransform
                    // Left Transform
                    let leftX = self.radians(v1: self.faceNode.worldPosition.z, v12: self.faceNode.worldPosition.x, v2: self.faceTargetNode.worldPosition.z, v22: self.faceTargetNode.worldPosition.x)
                        + obj.leftEyeTransform.columns.2.x
                    self.leftEyeXLabel.text = String.init(format: "x:%0.2f degrees", leftX.radiansToDegrees)
                    self.leftEyeXView.degrees = CGFloat(leftX.radiansToDegrees)
                    let leftY = obj.faceEyeTransform.columns.2.y + obj.leftEyeTransform.columns.2.y
                    self.leftEyeYLabel.text = String.init(format: "y:%0.2f degrees", leftY.radiansToDegrees)
                    self.leftEyeYView.degrees = CGFloat(leftY.radiansToDegrees)
                    // Right radians
                    let rightX = self.radians(v1: self.faceNode.worldPosition.z, v12: self.faceNode.worldPosition.x, v2: self.faceTargetNode.worldPosition.z, v22: self.faceTargetNode.worldPosition.x)
                        + obj.rightEyeTransform.columns.2.x
                    self.rightEyeXLabel.text = String.init(format: "x:%0.2f degrees", rightX.radiansToDegrees)
                    self.rightEyeXView.degrees = CGFloat(rightX.radiansToDegrees)
                    let rightY = obj.faceEyeTransform.columns.2.y + obj.rightEyeTransform.columns.2.y
                    self.rightEyeYLabel.text = String.init(format: "y:%0.2f degrees", rightY.radiansToDegrees)
                    self.rightEyeYView.degrees = CGFloat(rightY.radiansToDegrees)
                }
                self.replayCnt += 1
                if self.replayCnt >= self.recordedList.count {
                    self.replayCnt = 0
                    delay = self.REPLAY_THREAD_INTERVAL
                } else {
                    delay = self.recordedList[self.replayCnt].timeStamp - obj.timeStamp
                }
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }
    
    func stopReplay() {
        self.isReplay = false
        self.replayCnt = 0
    }
}

//MARK:- ARSession
extension ViewController: ARSessionDelegate {
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            self.isRunning = false
            return
        }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.isRunning = true
        // 取得した値をチェックする時に使うと分かりやすい
        if ACTIVATE_VALUE_CHECK_TIMER {
            self.startValueCheckTimer()
        }
    }
    
    func startValueCheckTimer() {
        self.valueCheckTimer?.invalidate()
        self.valueCheckTimer = Timer.scheduledTimer(withTimeInterval: VALUE_CHECK_TIMER_INTERVAL, repeats: true, block: { (_) in
            NSLog("valueCheckTimer_Tick")
            if let left = self.lastLineOfSightObj?.leftEyeTransform {
                print("left x:\(left.columns.2.x.radiansToDegrees), y:\(left.columns.2.y.radiansToDegrees), z:\(left.columns.2.z.radiansToDegrees)")
            }
            if let face = self.lastLineOfSightObj?.faceEyeTransform {
                print("face 0 x:\(face.columns.0.x.radiansToDegrees), y:\(face.columns.0.y.radiansToDegrees), z:\(face.columns.0.z.radiansToDegrees)")
                print("face 1 x:\(face.columns.1.x.radiansToDegrees), y:\(face.columns.1.y.radiansToDegrees), z:\(face.columns.1.z.radiansToDegrees)")
                print("face 2 x:\(face.columns.2.x.radiansToDegrees), y:\(face.columns.2.y.radiansToDegrees), z:\(face.columns.2.z.radiansToDegrees)")
                print("face 3 x:\(face.columns.3.x.radiansToDegrees), y:\(face.columns.3.y.radiansToDegrees), z:\(face.columns.3.z.radiansToDegrees)")
            }
            print("")
        })
    }
    
    //MARK:- ARSessionDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        AlertDialog.show(viewController: self, title: "The AR session failed.", message: errorMessage, btnTitle: "Restart Session") {
            self.resetTracking()
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frame.anchors.forEach { anchor in
            guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor else { return }
            
            // Keep Time.
            let date = Date()
            
            let obj = LineOfSightUnit.init(
                timeStamp: date.timeIntervalSince1970,
                faceEyeTransform: faceAnchor.transform,
                leftEyeTransform: faceAnchor.leftEyeTransform,
                rightEyeTransform: faceAnchor.rightEyeTransform)
            self.lastLineOfSightObj = obj
            if self.isRecording {
                if self.baseTime == nil {
                    self.baseTime = date.timeIntervalSince1970
                }
                self.recordedList.append(obj)
                self.unitStatusLabel.text = "\(self.recordedList.count.commaString) units saved"
            }
            
            // Current Time
            if self.isRecording {
                self.currentTimeLabel.text = (date.timeIntervalSince1970-self.baseTime!).timeString
            } else {
                self.currentTimeLabel.text = self.timeFormat.string(from: date)
            }
            
            // Face Node
            self.faceNode.simdTransform = faceAnchor.transform
            
            // Left Radians
            let leftX = radians(v1: self.faceNode.worldPosition.z, v12: self.faceNode.worldPosition.x, v2: self.faceTargetNode.worldPosition.z, v22: self.faceTargetNode.worldPosition.x)
                + faceAnchor.leftEyeTransform.columns.2.x
            self.leftEyeXLabel.text = String.init(format: "x:%0.2f degrees", leftX.radiansToDegrees)
            self.leftEyeXView.degrees = CGFloat(leftX.radiansToDegrees)
            let leftY = faceAnchor.transform.columns.2.y + faceAnchor.leftEyeTransform.columns.2.y
            self.leftEyeYLabel.text = String.init(format: "y:%0.2f degrees", leftY.radiansToDegrees)
            self.leftEyeYView.degrees = CGFloat(leftY.radiansToDegrees)
            // Right Radians
            let rightX = radians(v1: self.faceNode.worldPosition.z, v12: self.faceNode.worldPosition.x, v2: self.faceTargetNode.worldPosition.z, v22: self.faceTargetNode.worldPosition.x)
                + faceAnchor.rightEyeTransform.columns.2.x
            self.rightEyeXLabel.text = String.init(format: "x:%0.2f degrees", rightX.radiansToDegrees)
            self.rightEyeXView.degrees = CGFloat(rightX.radiansToDegrees)
            let rightY = faceAnchor.transform.columns.2.y + faceAnchor.rightEyeTransform.columns.2.y
            self.rightEyeYLabel.text = String.init(format: "y:%0.2f degrees", rightY.radiansToDegrees)
            self.rightEyeYView.degrees = CGFloat(rightY.radiansToDegrees)
        }
    }
    
    func radians(v1: Float, v12: Float, v2: Float, v22: Float) -> Float {
        return atan2f(v22 - v12, v2 - v1)
    }
}
