//
//  HeadTracker.swift
//  TaCo
//
//  Created by Harshit Garg on 15/08/24.
//

import Foundation
import CoreMotion
import CoreLocation
import simd

class HeadTracker: NSObject, CMHeadphoneMotionManagerDelegate {
    let headphone_manager = CMHeadphoneMotionManager()
    let device_manager = CMMotionManager()
    let tracking_operation = OperationQueue()
    var rotation_matrix_simd = simd_float3x3()
    
    override init() {
        super.init()
        
        headphoneMotionConfig()
    }
    
    public func startHeadTracking() {
        let referenceFrame = CMAttitudeReferenceFrame.xMagneticNorthZVertical
        
        device_manager.startDeviceMotionUpdates(using: referenceFrame, to: tracking_operation, withHandler: deviceMotionHandler)
        device_manager.startMagnetometerUpdates()
        headphone_manager.startDeviceMotionUpdates(to: tracking_operation, withHandler: headphoneMotionHandler)
    }
    
    private func headphoneMotionConfig() {
        headphone_manager.delegate = self
        if headphone_manager.isDeviceMotionAvailable {
            logger.info("Head phone motion is available")
        }
        else {
            logger.info("Head phone motion is not available")
        }
    }
    
    private func headphoneMotionHandler(manager: CMDeviceMotion?, error: Error?) {
        logger.info("Head phone motion detected")
        guard let manager = manager else {
            logger.error("Error in headphone motion handler: \(error)")
            return
        }
        
        let rotation_matrix = manager.attitude.rotationMatrix
        let row1 = simd_float3(x: Float(rotation_matrix.m11), y: Float(rotation_matrix.m12), z: Float(rotation_matrix.m13))
        let row2 = simd_float3(x: Float(rotation_matrix.m21), y: Float(rotation_matrix.m22), z: Float(rotation_matrix.m23))
        let row3 = simd_float3(x: Float(rotation_matrix.m31), y: Float(rotation_matrix.m32), z: Float(rotation_matrix.m33))
        
        let head_phone_rotation_matrix_simd = simd_float3x3(rows: [row1, row2, row3])
        let final_rotation_matrix = simd_mul(rotation_matrix_simd, head_phone_rotation_matrix_simd)
        
        debugPrint("HeadPhone manager: \(final_rotation_matrix.columns.0)")
    }
    
    private func deviceMotionHandler(manager: CMDeviceMotion?, error: Error?) {
        guard let manager = manager else {
            logger.error("Error in device motion handler: \(error)")
            return
        }
        
        let rotation_matrix = manager.attitude.rotationMatrix
        let row1 = simd_float3(x: Float(rotation_matrix.m11), y: Float(rotation_matrix.m12), z: Float(rotation_matrix.m13))
        let row2 = simd_float3(x: Float(rotation_matrix.m21), y: Float(rotation_matrix.m22), z: Float(rotation_matrix.m23))
        let row3 = simd_float3(x: Float(rotation_matrix.m31), y: Float(rotation_matrix.m32), z: Float(rotation_matrix.m33))
        
        rotation_matrix_simd = simd_float3x3(rows: [row1, row2, row3])
        
        //debugPrint("X: \(rotation_matrix_simd.columns.0)")
    }
    
}
