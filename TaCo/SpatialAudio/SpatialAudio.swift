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

struct Position {
    var x: Float
    var y: Float
    var z: Float
    
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

class SourceDetails {
    var pos: Position
    var sound_address: String
    var source: PHASESource? = nil
    
    init(pos: Position, addr: String) {
        self.pos = pos
        self.sound_address = addr
    }
}


class SpatialAudio: NSObject, CMHeadphoneMotionManagerDelegate {
    var list_of_sources: [SourceDetails] = [
        SourceDetails(pos: Position(0, 0, 6), addr: "countdown.wav"),
        SourceDetails(pos: Position(0, 0, -6), addr: "drumroll.mp3")
    ]
    
    // PHASE engine variables
    let audio_engine: PHASEEngine
    let listner: PHASEListener
    let spatial_mixer_definition: PHASESpatialMixerDefinition
    var list_of_sound_events: [PHASESoundEvent] = []

    // Headphones motion variables
    let headPhoneManager = CMHeadphoneMotionManager()
    let positionOperationQueue = OperationQueue()
    var updateListnerPosition: Bool = false
    
    public func updateListnerLocation(x: Float, y: Float, z: Float) {
        listner.transform.columns.3.x = x
        listner.transform.columns.3.y = y
        listner.transform.columns.3.z = z
    }
    
    public func rotateTheSource() {
        self.updateListnerLocation(x: 0, y: 0, z: 0)
        
        var x: Double = 0.0;
        var z: Double = 0.0;
        
        for i in stride(from: -6, through: 6, by: 0.2) {
            x = i
            z = -sqrt((36 - (x*x))) + 6
            self.updateListnerLocation(x: Float(x), y: 0, z: Float(z))
            usleep(200000)
        }
    }

    private func registerSoundAssets() {
        for source_information in list_of_sources {
            let sound_asset_addr = source_information.sound_address
            let name: String = String(sound_asset_addr.split(separator: ".")[0])
            let type: String = String(sound_asset_addr.split(separator: ".")[1])
            let url: URL = Bundle.main.url(forResource: name, withExtension: type)!
            logger.debug("Registering \(name).\(type) into the audio engine")
            try! audio_engine.assetRegistry.registerSoundAsset(url: url, identifier: name, assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)
            
            let event_name = name + "_event"
            let sampler_node_definition = PHASESamplerNodeDefinition(soundAssetIdentifier: name, mixerDefinition: spatial_mixer_definition)
            sampler_node_definition.playbackMode = .looping
            sampler_node_definition.setCalibrationMode(calibrationMode: .relativeSpl, level: 12)
            sampler_node_definition.cullOption = .doNotCull
            try! audio_engine.assetRegistry.registerSoundEventAsset(rootNode: sampler_node_definition, identifier: event_name)
        }
    }
    
    private func configureAudioEngine() {
        audio_engine.unitsPerMeter = 1
        audio_engine.outputSpatializationMode = .automatic
        audio_engine.defaultReverbPreset = .largeChamber
    }
    
    override init(){
        
        //setting the phone reference frame
        let reference_frame = CMAttitudeReferenceFrame.xMagneticNorthZVertical
        let device_motion_manager = CMMotionManager()
        device_motion_manager.startDeviceMotionUpdates(using: reference_frame)
        
        audio_engine = PHASEEngine(updateMode: .automatic)
        var worldTransform = simd_float4x4()
        
        if let device_motion = device_motion_manager.deviceMotion {
            logger.info("Here mfs")
            let rotationMatrix = device_motion.attitude.rotationMatrix

                // Convert rotation matrix to simd_float4x4 for use with PHASE
                worldTransform = simd_float4x4(rows: [
                    simd_float4(Float(rotationMatrix.m11), Float(rotationMatrix.m12), Float(rotationMatrix.m13), 0),
                    simd_float4(Float(rotationMatrix.m21), Float(rotationMatrix.m22), Float(rotationMatrix.m23), 0),
                    simd_float4(Float(rotationMatrix.m31), Float(rotationMatrix.m32), Float(rotationMatrix.m33), 0),
                    simd_float4(0, 0, 0, 1)
                ])
            
        }
        
        // Create a Spatial Mixer
        let distance_model_parameters = PHASEGeometricSpreadingDistanceModelParameters()
        distance_model_parameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 10.0)
        distance_model_parameters.rolloffFactor = 2
        let spatial_pipeline_flags: PHASESpatialPipeline.Flags = [.directPathTransmission]
        let spatial_pipeline = PHASESpatialPipeline(flags: spatial_pipeline_flags)!
        spatial_mixer_definition = PHASESpatialMixerDefinition(spatialPipeline: spatial_pipeline)
        spatial_mixer_definition.distanceModelParameters = distance_model_parameters
        
        // Creating a listner
        listner = PHASEListener(engine: audio_engine)
        listner.transform = matrix_identity_float4x4
        try! audio_engine.rootObject.addChild(listner)
        
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.142, inwardNormals: false, allocator:nil)
        let shape = PHASEShape(engine: audio_engine, mesh: mesh)

        // Create a Volumetric Source from the Shape.
        // Initialise all the sources
        for i in 0..<list_of_sources.count {
            let source_detail = list_of_sources[i]
            source_detail.source = PHASESource(engine: audio_engine, shapes: [shape])
            source_detail.source?.transform = matrix_identity_float4x4
            source_detail.source?.transform.columns.3.x = source_detail.pos.x
            source_detail.source?.transform.columns.3.y = source_detail.pos.y
            source_detail.source?.transform.columns.3.z = source_detail.pos.z
            
            try! audio_engine.rootObject.addChild(source_detail.source!)
        }

        super.init()
        
        self.registerSoundAssets()
        self.configureAudioEngine()
        
        try! audio_engine.start()
        self.headphoneMotionConfig()
    }
    
    func playSpatialSound() {
        updateListnerPosition.toggle()
        
        if updateListnerPosition {
            
            headPhoneManager.startDeviceMotionUpdates(to: positionOperationQueue, withHandler: headphoneMotionHandler)
            
            logger.info("Playing the sound")
            // Associate the Source and Listener with the Spatial Mixer in the Sound Event.
            for i in 0..<list_of_sources.count {
                let source_information = list_of_sources[i]
                let name = String(source_information.sound_address.split(separator: ".")[0]) + "_event"
                
                let mixerParameters = PHASEMixerParameters()
                mixerParameters.addSpatialMixerParameters(identifier: spatial_mixer_definition.identifier, source: source_information.source!, listener: listner)
                
                let sound_event = try! PHASESoundEvent(engine: audio_engine, assetIdentifier: name, mixerParameters: mixerParameters)
                list_of_sound_events.append(sound_event)
                sound_event.start()
            }
        }
        
        else {
            //headPhoneManager.stopDeviceMotionUpdates()
            logger.info("Stopping the sound")
            for sound_event in list_of_sound_events {
                sound_event.stopAndInvalidate()
            }
            list_of_sound_events = []
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
