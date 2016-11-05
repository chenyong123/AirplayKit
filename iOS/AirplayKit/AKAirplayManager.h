//
//  AKServiceManager.h
//  AirplayKit
//
//  Created by Andy Roth on 1/18/11.
//  Copyright 2011 Roozy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AKDevice.h"
#import "AsyncSocket.h"

@class AKAirplayManager;

@protocol AKAirplayManagerDelegate <NSObject>

@optional
- (void)manager:(AKAirplayManager *)manager didFindDevice:(AKDevice *)device; // Use - (void) connectToDevice:(AKDevice *)device; to connect to a specific device.
- (void)manager:(AKAirplayManager *)manager didConnectToDevice:(AKDevice *)device; // Once connected, use AKDevice methods to communicate over Airplay.

- (void)allFoundDevices:(NSArray<AKDevice *> *)devices;

@end


@interface AKAirplayManager : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
@private
    id <AKAirplayManagerDelegate> _delegate;
    BOOL _autoConnect;
    NSNetServiceBrowser *_serviceBrowser;
    AKDevice *_connectedDevice;
    AKDevice *_tempDevice;
    NSMutableArray<NSNetService *> *_foundServices;
}

@property (nonatomic, assign) id <AKAirplayManagerDelegate> delegate;
@property (nonatomic) BOOL autoConnect; // Connects to the first found device automatically. Defaults to YES.
@property (nonatomic, retain) AKDevice *connectedDevice;

- (void)findDevices; // Searches for Airplay devices on the same wifi network.
- (void)connect2device:(AKDevice *)device; // Connects to a found device.
- (void)airPlayPopSelectIndex:(NSInteger)index;
- (void)stop;
@end
