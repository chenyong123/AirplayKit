//
//  AKServiceManager.m
//  AirplayKit
//
//  Created by Andy Roth on 1/18/11.
//  Copyright 2011 Roozy. All rights reserved.
//

#import "AKAirplayManager.h"


@implementation AKAirplayManager

@synthesize delegate = _delegate, autoConnect = _autoConnect, connectedDevice = _connectedDevice;

#pragma mark -
#pragma mark Initialization

- (id) init {
    if((self = [super init])) {
        self.autoConnect = NO;
        _foundServices = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)filterAddDevice:(NSNetService *)service {
    for(NSNetService * tmService in _foundServices) {
        if([tmService.name isEqualToString:service.name]) {
            return;
        }
    }
    [_foundServices addObject:service];
}

#pragma mark -
#pragma mark Public Methods
- (void)findDevices {
    NSLog(@"Finding Airport devices.");
    
    _serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [_serviceBrowser setDelegate:self];
    [_serviceBrowser searchForServicesOfType:@"_airplay._tcp" inDomain:@""];
}

- (void)connect2device:(AKDevice *)device {
    NSLog(@"Connecting to device : %@:%zd", device.hostname, device.port);
    if(!_tempDevice) {
        _tempDevice = [device retain];
        
        AsyncSocket *socket = [[AsyncSocket alloc] initWithDelegate:self];
        [socket connectToHost:device.hostname onPort:device.port error:NULL];
    }
}

- (void)airPlayPopSelectIndex:(NSInteger)index {
    if(_foundServices.count > 0 && index != NSNotFound && index < _foundServices.count) {
        NSNetService * service = _foundServices[index];
        [self connect2device:[self convert2DeviceFromService:service]];
    } else {
        NSLog(@"所选设备越界");
    }
}

- (void)stop {
    if(self.connectedDevice) {
        [self.connectedDevice sendStop];
    }
}

- (AKDevice *)convert2DeviceFromService:(NSNetService *)service {
    AKDevice *device = [[AKDevice alloc] init];
    device.hostname = service.hostName;
    device.port = service.port;
    device.name = service.name;
    return device;
    
}

- (NSArray<AKDevice *> *)allDevices {
    NSMutableArray<AKDevice *> * devices = [[NSMutableArray alloc] init];
    
    for(NSNetService * service in _foundServices)  {
        [devices addObject:[self convert2DeviceFromService:service]];
    }
    
    return devices;
}

#pragma mark -
#pragma mark Net Service Browser Delegate
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
    
}


- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict {
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"Found service");
    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:20.0];
    [self filterAddDevice:aNetService];
    
    if(!moreComing) {
        if([_delegate respondsToSelector:@selector(allFoundDevices:)]) {
            [_delegate allFoundDevices:[self allDevices]];
        }
        [_serviceBrowser stop];
        [_serviceBrowser release];
        _serviceBrowser = nil;
    }
}

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered domain is no longer available.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    
}

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered service is no longer published.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    //TODO:: finish . need Next info
}




#pragma mark -
#pragma mark Net Service Delegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"Resolved service: %@:%zd", sender.hostName, sender.port);
    
    AKDevice *device = [[AKDevice alloc] init];
    device.hostname = sender.hostName;
    device.port = sender.port;
    device.name = sender.name;
    
    if(_delegate && [_delegate respondsToSelector:@selector(manager:didFindDevice:)]) {
        [_delegate manager:self didFindDevice:[device autorelease]];
    }
    
    if(_autoConnect && !_connectedDevice) {
        [self connect2device:device];
    }
}

#pragma mark -
#pragma mark AsyncSocket Delegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Connected to device.");
    
    AKDevice *device = _tempDevice;
    device.socket = sock;
    device.connected = YES;
    
    self.connectedDevice = device;
    [device release];
    _tempDevice = nil;
    
    if(_delegate && [_delegate respondsToSelector:@selector(manager:didConnectToDevice:)]) {
        [self.connectedDevice sendReverse];
        [_delegate manager:self didConnectToDevice:self.connectedDevice];
    }
}


#pragma mark -
#pragma mark Cleanup

- (void) dealloc {
    [_connectedDevice release];
    [_foundServices removeAllObjects];
    [_foundServices release];
    
    [super dealloc];
}

@end
