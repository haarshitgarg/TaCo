//
//  SpatialAudio.swift
//  TaCo
//
//  Created by Harshit Garg on 02/08/24.
//

import Foundation
import PHASE
import AVFoundation

struct SpatialAudio {
    let audioEngine: PHASEEngine
    let audioFileURL: URL
    let listner: PHASEListener
    let source: PHASESource
    let spatialPipeline: PHASESpatialPipeline
    let spatialMixerDefinition: PHASESpatialMixerDefinition
    
    public func updateListnerLocation(x: Float, y: Float, z: Float) {
        listner.transform.columns.3.x = x
        listner.transform.columns.3.y = y
        listner.transform.columns.3.z = z
    }
    
    init(){
        debugPrint("Creating the engine")
        audioEngine = PHASEEngine(updateMode: .automatic)
        
        debugPrint("Creating audio File URL")
        audioFileURL = Bundle.main.url(forResource: "countdown", withExtension: "wav")!
        debugPrint("Registering Sound Asset")
        try! audioEngine.assetRegistry.registerSoundAsset(url: audioFileURL, identifier: "countdown", assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)
        
        // Create a Spatial Pipeline.
        debugPrint("Creating the spatial pipeline")
        let spatialPipelineOptions: PHASESpatialPipeline.Flags = [.directPathTransmission, .lateReverb]
        spatialPipeline = PHASESpatialPipeline(flags: spatialPipelineOptions)!
        spatialPipeline.entries[PHASESpatialCategory.lateReverb]!.sendLevel = 0.1;
        audioEngine.defaultReverbPreset = .mediumRoom
        
        // Create a Spatial Mixer with the Spatial Pipeline.
        debugPrint("Creating the spatial pipeline mixer")
        spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)

        // Set the Spatial Mixer's Distance Model.
        debugPrint("Creating Distance Model")
        let distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
        distanceModelParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 10.0)
        distanceModelParameters.rolloffFactor = 2
        spatialMixerDefinition.distanceModelParameters = distanceModelParameters
        
        debugPrint("Setting the sampler Node definition")
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: "countdown", mixerDefinition:spatialMixerDefinition)

        // Set the Sampler Node's Playback Mode to Looping.
        samplerNodeDefinition.playbackMode = .looping

        // Set the Sampler Node's Calibration Mode to Relative SPL and Level to 12 dB.
        samplerNodeDefinition.setCalibrationMode(calibrationMode: .relativeSpl, level: 12)

        // Set the Sampler Node's Cull Option to Sleep.
        samplerNodeDefinition.cullOption = .sleepWakeAtRealtimeOffset;

        // Register a Sound Event Asset with the Engine named "drumEvent".
        try! audioEngine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: "countdownEvent")
        
        debugPrint("Creating listner")
        listner = PHASEListener(engine: audioEngine)
        listner.transform = matrix_identity_float4x4
        
        try! audioEngine.rootObject.addChild(listner)
        
        // Create an Icosahedron Mesh.
        debugPrint("Creating a mesh and a shape")
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.0142, inwardNormals: false, allocator:nil)

        // Create a Shape from the Icosahedron Mesh.
        let shape = PHASEShape(engine: audioEngine, mesh: mesh)

        // Create a Volumetric Source from the Shape.
        debugPrint("Creating a spatial spherical source")
        source = PHASESource(engine: audioEngine, shapes: [shape])

        // Translate the Source 2 meters in front of the Listener and rotated back toward the Listener.
        var sourceTransform = simd_float4x4()
        sourceTransform.columns.0 = simd_make_float4(-1.0, 0.0, 0.0, 0.0)
        sourceTransform.columns.1 = simd_make_float4(0.0, 1.0, 0.0, 0.0)
        sourceTransform.columns.2 = simd_make_float4(0.0, 0.0, -1.0, 0.0)
        sourceTransform.columns.3 = simd_make_float4(0.0, 0.0, 0.0, 1.0)
        source.transform = sourceTransform;

        // Attach the Source to the Engine's Scene Graph.
        // This actives the Listener within the simulation.
        try! audioEngine.rootObject.addChild(source)
    }
    
    func playSpatialSound() {
        debugPrint("Playing the spatial sound")
        
        // Associate the Source and Listener with the Spatial Mixer in the Sound Event.
        let mixerParameters = PHASEMixerParameters()
        mixerParameters.addSpatialMixerParameters(identifier: spatialMixerDefinition.identifier, source: source, listener: listner)


        let soundEvent = try! PHASESoundEvent(engine: audioEngine, assetIdentifier: "countdownEvent", mixerParameters: mixerParameters)
        
        try! audioEngine.start()
        
        soundEvent.start()
    }
    
}
