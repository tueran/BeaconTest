//
//  Beacon.h
//  Beacon
//
//  Created by Daniel Mauer on 26.06.14.
//
//

//#import <Cordova/Cordova.h>

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDV.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MapKit/MapKit.h>
#import "BeaconHelper.h"

#define KEY_BEACON_ID @"bid"
#define KEY_BEACON_PUUID @"puuid"
#define KEY_BEACON_MAJOR @"major"
#define KEY_BEACON_MINOR @"minor"



@interface Beacon : CDVPlugin <CLLocationManagerDelegate>

- (BOOL) isLocationServicesEnabled;
- (BOOL) isAuthorized;
- (BOOL) isRegionMonitoringAvailable;
- (BOOL) isRegionMonitoringEnabled;
- (BOOL) isSignificantLocationChangeMonitoringAvailable;

- (void) addBeaconRegionToMonitor:(NSMutableDictionary *)params;
- (void) removeBeaconRegionToMonitor:(NSMutableDictionary *)params;

#pragma mark Plugin Functions
- (void) addBeaconRegion:(CDVInvokedUrlCommand*)command;
- (void) removeBeaconRegion:(CDVInvokedUrlCommand*)command;
- (void) getWatchedBeaconRegionIds:(CDVInvokedUrlCommand*)command;
- (void) setHost:(CDVInvokedUrlCommand*)command;
- (void) setToken:(CDVInvokedUrlCommand*)command;

@end
