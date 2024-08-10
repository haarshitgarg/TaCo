//
//  SpatialAudio.swift
//  TaCo
//
//  Created by Harshit Garg on 02/08/24.
//

import Foundation
import PHASE
import AVFoundation
import CoreMotion
import Spatial

class SpatialAudio: NSObject, CMHeadphoneMotionManagerDelegate {
    // PHASE engine variables
    let audioEngine: PHASEEngine
    let listner: PHASEListener
    let source: PHASESource
    let spatialPipeline: PHASESpatialPipeline
    let spatialMixerDefinition: PHASESpatialMixerDefinition
    var soundEvent: PHASESoundEvent? = nil

    // Headphones motion variables
    let headPhoneManager = CMHeadphoneMotionManager()
    let positionManagerQueue = DispatchQueue(label: "postionMotionManger")
    let positionOperationQueue = OperationQueue()
    var updateListnerPosition: Bool = false
    
    public func updateListnerLocation(x: Float, y: Float, z: Float) {
        listner.transform.columns.3.x = x
        listner.transform.columns.3.y = y
        listner.transform.columns.3.z = z
    }
    
    override init(){
        
        audioEngine = PHASEEngine(updateMode: .automatic)
        audioEngine.unitsPerMeter = 1
        
        // Registering sound asset
        let audioFileURL = Bundle.main.url(forResource: "countdown", withExtension: "wav")!
        try! audioEngine.assetRegistry.registerSoundAsset(url: audioFileURL, identifier: "countdown", assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)
        
        // Create a Spatial Pipeline.
        let spatialPipelineOptions: PHASESpatialPipeline.Flags = [.directPathTransmission, .lateReverb]
        spatialPipeline = PHASESpatialPipeline(flags: spatialPipelineOptions)!
        spatialPipeline.entries[PHASESpatialCategory.lateReverb]!.sendLevel = 0.1;
        audioEngine.defaultReverbPreset = .mediumRoom
        
        // Create a Spatial Mixer
        spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)
        let distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
        distanceModelParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 10.0)
        distanceModelParameters.rolloffFactor = 2
        spatialMixerDefinition.distanceModelParameters = distanceModelParameters
        
        // Registering a Spatial sound event
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: "countdown", mixerDefinition:spatialMixerDefinition)
        samplerNodeDefinition.playbackMode = .looping
        samplerNodeDefinition.setCalibrationMode(calibrationMode: .relativeSpl, level: 12)
        samplerNodeDefinition.cullOption = .sleepWakeAtRealtimeOffset;
        try! audioEngine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: "countdownEvent")
        

        // Creating a listner
        listner = PHASEListener(engine: audioEngine)
        listner.transform = matrix_identity_float4x4
        try! audioEngine.rootObject.addChild(listner)
        
        // Create an Icosahedron Mesh.
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.142, inwardNormals: false, allocator:nil)

        // Create a Shape from the Icosahedron Mesh.
        let shape = PHASEShape(engine: audioEngine, mesh: mesh)

        // Create a Volumetric Source from the Shape.
        source = PHASESource(engine: audioEngine, shapes: [shape])
        source.transform = matrix_identity_float4x4;
        source.transform.columns.3.z = -6
        try! audioEngine.rootObject.addChild(source)
        try! audioEngine.start()

        super.init()
        
        self.headphoneMotionConfig()
    }
    
    func playSpatialSound() {
        updateListnerPosition.toggle()
        
        if updateListnerPosition {
            
            headPhoneManager.startDeviceMotionUpdates(to: positionOperationQueue, withHandler: headphoneMotionHandler)
            
            logger.info("Playing the sound")
            // Associate the Source and Listener with the Spatial Mixer in the Sound Event.
            let mixerParameters = PHASEMixerParameters()
            mixerParameters.addSpatialMixerParameters(identifier: spatialMixerDefinition.identifier, source: source, listener: listner)
            soundEvent = try! PHASESoundEvent(engine: audioEngine, assetIdentifier: "countdownEvent", mixerParameters: mixerParameters)
            
            soundEvent?.start()
        }
        else {
            headPhoneManager.stopDeviceMotionUpdates()
            logger.info("Stopping the sound")
            soundEvent?.stopAndInvalidate()
        }
        
    }
    
}

extension SpatialAudio {
    private func headphoneMotionHandler(manager: CMDeviceMotion?, error: Error?) {
        logger.info("Handler called")
        guard let manager = manager else {
            logger.info("Manager is nil")
            return
        }
        
        let pitch = manager.attitude.pitch
        logger.info("Pitch of the device, \(pitch)")
        
        let roll = manager.attitude.roll
        logger.info("Roll of the device, \(roll)")
        
        let yaw = manager.attitude.yaw
        logger.info("Yaw of the device, \(yaw)")
        
        
        let position = simd_float3(x: listner.transform.columns.3.x, y: listner.transform.columns.3.y, z: listner.transform.columns.3.z)
        var rotationMatrix = simd_float3x3.init()
        rotationMatrix.columns.0.x = Float(manager.attitude.rotationMatrix.m11)
        rotationMatrix.columns.0.y = Float(manager.attitude.rotationMatrix.m21)
        rotationMatrix.columns.0.z = Float(manager.attitude.rotationMatrix.m31)
        
        rotationMatrix.columns.1.x = Float(manager.attitude.rotationMatrix.m12)
        rotationMatrix.columns.1.y = Float(manager.attitude.rotationMatrix.m22)
        rotationMatrix.columns.1.z = Float(manager.attitude.rotationMatrix.m32)
        
        rotationMatrix.columns.2.x = Float(manager.attitude.rotationMatrix.m13)
        rotationMatrix.columns.2.y = Float(manager.attitude.rotationMatrix.m23)
        rotationMatrix.columns.2.z = Float(manager.attitude.rotationMatrix.m33)
        
        var adjustMatrix = simd_float3x3.init(0)
        adjustMatrix.columns.0.x = 1
        adjustMatrix.columns.1.z = 1
        adjustMatrix.columns.2.y = -1
        
        
        let final_matrix = simd_quatf(adjustMatrix*rotationMatrix)
        debugPrint(final_matrix)
        
        let spatial_position = Pose3D.init(position: position, rotation: final_matrix)
        
        listner.transform = simd_float4x4(spatial_position)
        
    }
    
    private func headphoneMotionConfig() {
        headPhoneManager.delegate = self
        if headPhoneManager.isDeviceMotionAvailable {
            logger.info("Starting the head phone motion updates")
        }
        else {
            logger.info("Headphone motion is not available")
        }
    }
    
    public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        logger.info("HeadphoneMotionManageerDidConnect function is called")
    }
    
    public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        logger.info("HeadphoneMotionManageerDidDisconnect function is called")
    }
}
