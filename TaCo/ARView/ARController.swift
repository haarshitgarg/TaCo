//
//  ARController.swift
//  TaCo
//
//  Created by Harshit Garg on 07/09/24.
//

import Foundation
import ARKit

class ARController: NSObject, ARSessionDelegate {
    private var ar_session_: ARSession
    private var b_session_active_: Bool = false
    private var b_origin_set_: Bool = false
    private let delegate_queue_: DispatchQueue = DispatchQueue(label: "AR session delegate dispatch queue")
    private let spation_audio_controller_: SpatialAudio = SpatialAudio()

    override init() {
        ar_session_ = ARSession()
        ar_session_.delegateQueue = delegate_queue_
        
        super.init()
        
        ar_session_.delegate = self
    }
    
    public func StartARSession() {
        b_session_active_ = true
        let ar_session_configuration: ARConfiguration = ARWorldTrackingConfiguration()
        ar_session_.run(ar_session_configuration)
        logger.info("Running the AR session with configuration: \(ar_session_configuration.description)")
    }
    
    public func StopARSession() {
        b_session_active_ = false
        ar_session_.pause()
        logger.info("Pausing the AR session")
    }
    
    public func IsSessionActive() -> Bool {
        return b_session_active_
    }
    
    private func SetWorldOrigin() {
        //Set world origin here befor any other task
        logger.info("Setting world origin")
        b_origin_set_ = true
    }
    
}

// Useless check and debug functions
extension ARController {
    public func PlaySound() {
        self.SetWorldOrigin()
        logger.info("Playing Sound")
        spation_audio_controller_.updateListnerPosition = false
        spation_audio_controller_.playSpatialSound()
    }
    
    public func StopSound() {
        logger.info("Stoppin the sound")
        
        spation_audio_controller_.updateListnerPosition = true
        spation_audio_controller_.playSpatialSound()
    }
    
    public func checkSessionActive() {
        guard let session_configuration = ar_session_.configuration
        else {
            debugPrint("ARSession configuration nil")
            return
        }
        debugPrint(session_configuration)
    }
}
