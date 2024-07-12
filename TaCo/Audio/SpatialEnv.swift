//
//  SpatialEnv.swift
//  TaCo
//
//  Created by Harshit Garg on 12/07/24.
//

import Foundation
import AVFoundation
import AVFAudio
import PHASE

struct SpatialEnv {
    let engine = PHASEEngine(updateMode: .automatic)
    let audioURL: URL
    let spatialMixerDefinition: PHASESpatialMixerDefinition
    
    let mesh = MDLMesh.newIcosahedron(withRadius: 0.0142, inwardNormals: false, allocator: nil)
    let listner: PHASEListener
    let source: PHASESource
    let shape: PHASEShape
    
    var soundEvent: PHASESoundEvent

    init() {
        audioURL = Bundle.main.url(forResource: "CountDown", withExtension: "wav")!
        
        try! engine.assetRegistry.registerSoundAsset(url: audioURL, identifier: "countdown", assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)
        
        let spatialPipelineFlags: PHASESpatialPipeline.Flags = [.directPathTransmission, .lateReverb]
        let spatialPipeline = PHASESpatialPipeline(flags: spatialPipelineFlags)!
        spatialPipeline.entries[PHASESpatialCategory.lateReverb]!.sendLevel = 0.1;
        engine.defaultReverbPreset = .mediumRoom
        
        spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)
        
        let distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
        distanceModelParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 10.0)
        distanceModelParameters.rolloffFactor = 0.25
        spatialMixerDefinition.distanceModelParameters = distanceModelParameters
        
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: "countdown", mixerDefinition:spatialMixerDefinition)
        samplerNodeDefinition.playbackMode = .oneShot
        samplerNodeDefinition.setCalibrationMode(calibrationMode: .relativeSpl, level: 12)
        samplerNodeDefinition.cullOption = .sleepWakeAtRealtimeOffset;
        
        try! self.engine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: "countdownEvent")
        
        self.listner = PHASEListener(engine: engine)
        listner.transform = matrix_identity_float4x4
        
        try! engine.rootObject.addChild(listner)
        
        shape = PHASEShape(engine: engine, mesh: self.mesh)
        source = PHASESource(engine: engine, shapes: [shape])
        
        var sourceTransform = simd_float4x4()
        sourceTransform.columns.0 = simd_make_float4(-1.0, 0.0, 0.0, 0.0)
        sourceTransform.columns.1 = simd_make_float4(0.0, 1.0, 0.0, 0.0)
        sourceTransform.columns.2 = simd_make_float4(0.0, 0.0, -1.0, 0.0)
        sourceTransform.columns.3 = simd_make_float4(0.0, 0.0, 2, 1.0)
        source.transform = sourceTransform;
        
        try! engine.rootObject.addChild(source)
        let mixerParam = PHASEMixerParameters()
        
        mixerParam.addSpatialMixerParameters(identifier: self.spatialMixerDefinition.identifier, source: self.source, listener: self.listner)
        
        soundEvent = try! PHASESoundEvent(engine: engine, assetIdentifier: "countdownEvent", mixerParameters: mixerParam)
    }
    
    mutating func playSpatialAudio() throws {
        let mixerParam = PHASEMixerParameters()
        
        mixerParam.addSpatialMixerParameters(identifier: self.spatialMixerDefinition.identifier, source: self.source, listener: self.listner)
        
        soundEvent = try! PHASESoundEvent(engine: engine, assetIdentifier: "countdownEvent", mixerParameters: mixerParam)
        try! engine.start()
        soundEvent.start(completion: {x in
            debugPrint("Finished")
        })
        do {
            sleep(10)
        }
        debugPrint("Started")
    }
    
    mutating func modifySourceLocation(x: Float) {
        var sourceTransform = simd_float4x4()
        sourceTransform.columns.0 = simd_make_float4(-1.0, 0.0, 0.0, 0.0)
        sourceTransform.columns.1 = simd_make_float4(0.0, 1.0, 0.0, 0.0)
        sourceTransform.columns.2 = simd_make_float4(0.0, 0.0, -1.0, 0.0)
        sourceTransform.columns.3 = simd_make_float4(0.0, 0.0, x, 1.0)
        source.transform = sourceTransform;
    }
}
