//
//  SpeakerOutput.swift
//  GPUImage
//
//  Rewritten by Josh Bernfeld on 3/1/18
//  and originally created by Uzi Refaeli on 3/9/13.
//  Copyright (c) 2018 Brad Larson. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

public class SpeakerOutput: AudioEncodingTarget {
    
    public var changesAudioSession = true
    
    public private(set) var isPlaying = false
    var hasBuffer = false
    var isReadyForMoreMediaData = true {
        willSet {
            guard newValue else { return }
            
            // When we are ready to begin accepting new data check if we had something
            // in the rescue buffer. If we did then move it to the main buffer.
            self.copyRescueBufferContentsToCircularBuffer()
        }
    }
    
    var processingGraph:AUGraph?
    var mixerUnit:AudioUnit?
    
    var firstBufferReached = false
    
    let outputBus:AudioUnitElement = 0
    let inputBus:AudioUnitElement = 1
    
    let unitSize = UInt32(MemoryLayout<Int16>.size)
    let bufferUnit:UInt32 = 655360
    
    var circularBuffer = TPCircularBuffer()
    let circularBufferSize:UInt32
    
    var rescueBuffer:UnsafeMutableRawPointer?
    let rescueBufferSize:Int
    var rescueBufferContentsSize:UInt32 = 0

    
    public init() {
        circularBufferSize = bufferUnit * unitSize
        rescueBufferSize = Int(bufferUnit / 2)
    }
    
    deinit {
        if let processingGraph = processingGraph {
            DisposeAUGraph(processingGraph)
        }
        if let rescueBuffer = rescueBuffer {
            free(rescueBuffer)
        }
        TPCircularBufferCleanup(&circularBuffer)
        
        self.cancel()
    }
    
    // MARK: -
    // MARK: Playback control
    
    public func start() {
        if(isPlaying || processingGraph == nil) { return }
        
        AUGraphStart(processingGraph!)
        
        isPlaying = true
    }
    
    public func cancel() {
        if(!isPlaying || processingGraph == nil) { return }
        
        AUGraphStop(processingGraph!)
        
        isPlaying = false
        
        rescueBufferContentsSize = 0
        TPCircularBufferClear(&circularBuffer)
        hasBuffer = false
        isReadyForMoreMediaData = true
    }
    
    // MARK: -
    // MARK: AudioEncodingTarget protocol
    
    public func activateAudioTrack() {
        if(changesAudioSession) {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch {
                print("ERROR: Unable to set audio session: \(error)")
            }
        }
        
        // Create a new AUGraph
        NewAUGraph(&processingGraph)
        
        // AUNodes represent AudioUnits on the AUGraph and provide an
        // easy means for connecting audioUnits together.
        var outputNode = AUNode()
        var mixerNode = AUNode()
        
        // Create AudioComponentDescriptions for the AUs we want in the graph mixer component
        var mixerDesc = AudioComponentDescription()
        mixerDesc.componentType = kAudioUnitType_Mixer
        mixerDesc.componentSubType = kAudioUnitSubType_SpatialMixer
        mixerDesc.componentFlags = 0
        mixerDesc.componentFlagsMask = 0
        mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        
        // Output component
        var outputDesc = AudioComponentDescription()
        outputDesc.componentType = kAudioUnitType_Output
        outputDesc.componentSubType = kAudioUnitSubType_RemoteIO
        outputDesc.componentFlags = 0
        outputDesc.componentFlagsMask = 0
        outputDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        
        // Add nodes to the graph to hold our AudioUnits,
        // You pass in a reference to the  AudioComponentDescription
        // and get back an  AudioUnit
        AUGraphAddNode(processingGraph!, &mixerDesc, &mixerNode)
        AUGraphAddNode(processingGraph!, &outputDesc, &outputNode)
        
        // Now we can manage connections using nodes in the graph.
        // Connect the mixer node's output to the output node's input
        AUGraphConnectNodeInput(processingGraph!, mixerNode, 0, outputNode, 0)
        
        // Upon return from this function call, the audio units belonging to the graph are open but not initialized. Specifically, no resource allocation occurs.
        AUGraphOpen(processingGraph!)
        
        // Get a link to the mixer AU so we can talk to it later
        AUGraphNodeInfo(processingGraph!, mixerNode, nil, &mixerUnit)
        
        var elementCount:UInt32 = 1
        AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, UInt32(MemoryLayout<UInt32>.size))
        
        // Set output callback, this is how audio sample data will be retrieved
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = playbackCallback
        callbackStruct.inputProcRefCon = bridgeObject(self)
        AUGraphSetNodeInputCallback(processingGraph!, mixerNode, 0, &callbackStruct)
        
        // Describe the format, this will get adjusted when the first sample comes in.
        var audioFormat = AudioStreamBasicDescription()
        audioFormat.mFormatID    = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked
        audioFormat.mSampleRate = 44100.0
        audioFormat.mReserved = 0
        
        audioFormat.mBytesPerPacket = 2
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerFrame = 2
        audioFormat.mChannelsPerFrame = 1
        audioFormat.mBitsPerChannel = 16
        
        // Apply the format
        AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputBus, &audioFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        // Initialize the processing graph
        AUGraphInitialize(processingGraph!)
        
        circularBuffer = TPCircularBuffer()
        
        // Initialize the circular buffer
        _TPCircularBufferInit(&circularBuffer, circularBufferSize, MemoryLayout<TPCircularBuffer>.size)
        
        hasBuffer = false
    }
    
    public func processAudioBuffer(_ sampleBuffer: CMSampleBuffer, shouldInvalidateSampleWhenDone: Bool) {
        defer {
            if(shouldInvalidateSampleWhenDone) {
                CMSampleBufferInvalidate(sampleBuffer)
            }
        }
        
        if(!isReadyForMoreMediaData || !isPlaying) { return }
        
        if(!firstBufferReached) {
            firstBufferReached = true
            // Get the format information of the sample
            let desc = CMSampleBufferGetFormatDescription(sampleBuffer)!
            let basicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(desc)!
            
            var oSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            // Retrieve the existing set audio format
            var audioFormat = AudioStreamBasicDescription()
            AudioUnitGetProperty(mixerUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputBus, &audioFormat, &oSize)
            
            // Update the audio format with the information we have from the sample
            audioFormat.mSampleRate = basicDesc.pointee.mSampleRate
            
            audioFormat.mBytesPerPacket = basicDesc.pointee.mBytesPerPacket
            audioFormat.mFramesPerPacket = basicDesc.pointee.mFramesPerPacket
            audioFormat.mBytesPerFrame = basicDesc.pointee.mBytesPerFrame
            audioFormat.mChannelsPerFrame = basicDesc.pointee.mChannelsPerFrame
            audioFormat.mBitsPerChannel = basicDesc.pointee.mBitsPerChannel
            
            // Apply the format
            AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputBus, &audioFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
            AUGraphUpdate(processingGraph!, nil)
        }
        
        // Populate an AudioBufferList with the sample
        var audioBufferList = AudioBufferList()
        var blockBuffer:CMBlockBuffer?
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, nil, &audioBufferList, MemoryLayout<AudioBufferList>.size, nil, nil, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer)
        
        // This is actually doing audioBufferList.mBuffers[0]
        // Since the struct has an array of length of 1 the compiler is interpreting
        // it as a single item array and not letting us use the above line.
        // Since the array pointer points to the first item of the c array
        // and all we want is the first item this is equally fine.
        let audioBuffer = audioBufferList.mBuffers
        
        // Place the AudioBufferList in the circular buffer
        let sampleSize = UInt32(CMSampleBufferGetTotalSampleSize(sampleBuffer))
        let didCopyBytes = TPCircularBufferProduceBytes(&circularBuffer, audioBuffer.mData, sampleSize)
        
        // The circular buffer has not been proceseed quickly enough and has filled up.
        // Disable reading any further samples and save this last buffer so we don't lose it.
        if(!didCopyBytes) {
            //print("TPCircularBuffer limit reached: \(sampleSize) Bytes")
            
            isReadyForMoreMediaData = false
            
            self.writeToRescueBuffer(audioBuffer.mData, sampleSize)
        }
        else {
            hasBuffer = true
        }
    }
    
    public func readyForNextAudioBuffer() -> Bool {
        return isReadyForMoreMediaData
    }
    
    // MARK: -
    // MARK: Rescue buffer
    
    func writeToRescueBuffer(_ src: UnsafeRawPointer!, _ size: UInt32) {
        if(rescueBufferContentsSize > 0) {
            print("WARNING: Writing to rescue buffer with contents already inside")
        }
        
        if(size > rescueBufferSize) {
            print("WARNING: Unable to allocate enought space for rescue buffer, dropping audio sample")
        }
        else {
            if(rescueBuffer == nil) {
                rescueBuffer = malloc(rescueBufferSize)
            }
            
            rescueBufferContentsSize = size
            memcpy(rescueBuffer!, src, Int(size))
        }
    }
    
    func copyRescueBufferContentsToCircularBuffer() {
        if(rescueBufferContentsSize > 0) {
            let didCopyBytes = TPCircularBufferProduceBytes(&circularBuffer, rescueBuffer, rescueBufferContentsSize)
            if(!didCopyBytes) {
                print("WARNING: Unable to copy rescue buffer into main buffer, dropping audio sample")
            }
            rescueBufferContentsSize = 0
        }
    }
}

func playbackCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    let audioBuffer = ioData!.pointee.mBuffers
    let numberOfChannels = audioBuffer.mNumberChannels
    let outSamples = audioBuffer.mData
    
    // Zero-out all of the output samples first
    memset(outSamples, 0, Int(audioBuffer.mDataByteSize))
    
    let p = bridgeRawPointer(inRefCon) as! SpeakerOutput
    
    if(p.hasBuffer && p.isPlaying) {
        var availableBytes:UInt32 = 0
        let bufferTail = TPCircularBufferTail(&p.circularBuffer, &availableBytes)
        
        let requestedBytesSize = inNumberFrames * p.unitSize * numberOfChannels
        
        let bytesToRead = min(availableBytes, requestedBytesSize)
        // Copy the bytes from the circular buffer into the outSample
        memcpy(outSamples, bufferTail, Int(bytesToRead))
        // Clear what we just read out of the circular buffer
        TPCircularBufferConsume(&p.circularBuffer, bytesToRead)
        
        if(availableBytes <= requestedBytesSize*2) {
            p.isReadyForMoreMediaData = true
        }
        
        if(availableBytes <= requestedBytesSize) {
            p.hasBuffer = false
        }
    }
    
    return noErr
}

func bridgeObject(_ obj : AnyObject) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

func bridgeRawPointer(_ ptr : UnsafeMutableRawPointer) -> AnyObject {
    return Unmanaged.fromOpaque(ptr).takeUnretainedValue()
}

