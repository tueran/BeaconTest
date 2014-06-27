//
//  Beacon.m
//  Beacon
//
//  Created by Daniel Mauer on 26.06.14.
//
//

#import "Beacon.h"

#import <Cordova/CDV.h>
#import <Cordova/CDVViewController.h>
#import <CoreLocation/CoreLocation.h>



#pragma mark - Geofenfing Implementation

@implementation Beacon

- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (Beacon*)[super initWithWebView:(UIWebView*)theWebView];
    if (self)
    {
        
    }
    return self;
}

- (BOOL) isSignificantLocationChangeMonitoringAvailable
{
    BOOL significantLocationChangeMonitoringAvailablelassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(significantLocationChangeMonitoringAvailable)];
    if (significantLocationChangeMonitoringAvailablelassPropertyAvailable)
    {
        BOOL significantLocationChangeMonitoringAvailable = [CLLocationManager significantLocationChangeMonitoringAvailable];
        return (significantLocationChangeMonitoringAvailable);
    }
    
    // by default, assume NO
    return NO;
}

- (BOOL) isRegionMonitoringAvailable
{
    BOOL regionMonitoringAvailableClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(regionMonitoringAvailable)];
    if (regionMonitoringAvailableClassPropertyAvailable)
    {
        BOOL regionMonitoringAvailable = [CLLocationManager regionMonitoringAvailable];
        return (regionMonitoringAvailable);
    }
    
    // by default, assume NO
    return NO;
}

- (BOOL) isRegionMonitoringEnabled
{
    BOOL regionMonitoringEnabledClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(regionMonitoringEnabled)];
    if (regionMonitoringEnabledClassPropertyAvailable)
    {
        BOOL regionMonitoringEnabled = [CLLocationManager regionMonitoringEnabled];
        return (regionMonitoringEnabled);
    }
    
    // by default, assume NO
    return NO;
}

- (BOOL) isAuthorized
{
    BOOL authorizationStatusClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
    if (authorizationStatusClassPropertyAvailable)
    {
        NSUInteger authStatus = [CLLocationManager authorizationStatus];
        return (authStatus == kCLAuthorizationStatusAuthorized) || (authStatus == kCLAuthorizationStatusNotDetermined);
    }
    
    // by default, assume YES (for iOS < 4.2)
    return YES;
}


- (BOOL) isLocationServicesEnabled
{
    BOOL locationServicesEnabledInstancePropertyAvailable = [[[BeaconHelper sharedBeaconHelper] locationManager] respondsToSelector:@selector(locationServicesEnabled)]; // iOS 3.x
    BOOL locationServicesEnabledClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 4.x
    
    if (locationServicesEnabledClassPropertyAvailable)
    { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    }
    else if (locationServicesEnabledInstancePropertyAvailable)
    { // iOS 2.x, iOS 3.x
        return [(id)[[BeaconHelper sharedBeaconHelper] locationManager] locationServicesEnabled];
    }
    else
    {
        return NO;
    }
}

#pragma mark - iBeacon functions

-(void)addBeaconRegion:(CDVInvokedUrlCommand *)command
{
    NSString* callbackId = command.callbackId;
    
    [[BeaconHelper sharedBeaconHelper] saveBeaconCallbackId:callbackId];
    [[BeaconHelper sharedBeaconHelper] setCommandDelegate:self.commandDelegate];
    
    
    if (self.isLocationServicesEnabled) {
        BOOL forcePrompt = NO;
        
        if (forcePrompt) {
            [[BeaconHelper sharedBeaconHelper] returnBeaconError:PERMISSIONDENIED withMessage:nil];
            return;
        }
        
    }
    
    if (![self isAuthorized]) {
        NSString* message = nil;
        BOOL authStatusAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
        
        if (authStatusAvailable) {
            NSUInteger code = [CLLocationManager authorizationStatus];
            
            if (code == kCLAuthorizationStatusNotDetermined) {
                // could return POSITION_UNAVAILABLE but need to coordinate with other platforms
                message = @"User undecided on application's use of location services";
            } else if (code == kCLAuthorizationStatusRestricted) {
                message = @"application use of location services is restricted";
            }
        }
        //PERMISSIONDENIED is only PositionError that makes sense when authorization denied
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:PERMISSIONDENIED withMessage: message];
        
        return;
    }
    
    if (![self isRegionMonitoringAvailable])
    {
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:REGIONMONITORINGUNAVAILABLE withMessage: @"Region monitoring is unavailable"];
        return;
    }
    
    if (![self isRegionMonitoringEnabled])
    {
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:REGIONMONITORINGPERMISSIONDENIED withMessage: @"User has restricted the use of region monitoring"];
        return;
    }
    
    
    NSMutableDictionary *options = [command.arguments objectAtIndex:0];
    [self addBeaconRegionToMonitor:options];
    [[BeaconHelper sharedBeaconHelper] returnBeaconRegionSuccess];
    
    NSLog(@"addRegions: options: %@", options);
}


- (void) addBeaconRegionToMonitor:(NSMutableDictionary *)params {
    // Parse Incoming Params
    NSString *beaconId = [[params objectForKey:KEY_BEACON_ID] stringValue];
    NSString *proximityUUID = [params objectForKey:KEY_BEACON_PUUID];
    NSInteger majorInt = [[params objectForKey:KEY_BEACON_MAJOR] intValue];
    NSInteger minorInt = [[params objectForKey:KEY_BEACON_MINOR] intValue];
    NSUUID *puuid = [[NSUUID alloc] initWithUUIDString:proximityUUID];
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:puuid major:majorInt minor:minorInt identifier:beaconId];
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    NSLog(@"Function: addRegion, BeaconRegion: %@", beaconRegion);
    [[[BeaconHelper sharedBeaconHelper] locationManager] startMonitoringForRegion:beaconRegion];
    
}


- (void)getWatchedBeaconRegionIds:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    
    NSSet *beaconRegions = [[BeaconHelper sharedBeaconHelper] locationManager].monitoredRegions;
    NSLog(@"getWatchedBeaconRegionIds: %@", beaconRegions);
    
    NSMutableArray *watchedBeaconRegions = [NSMutableArray array];
    for (CLRegion *beaconRegion in beaconRegions) {
        [watchedBeaconRegions addObject:beaconRegion.identifier];
        NSLog(@"beaconRegion.identifier: %@", beaconRegion.identifier);
        NSLog(@"beaconRegion.description: %@", beaconRegion.description);
        
    }
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:3];
    [posError setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
    [posError setObject: @"BeaconRegion Success" forKey: @"message"];
    [posError setObject: watchedBeaconRegions forKey: @"beaconRegionids"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posError];
    if (callbackId) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
    NSLog(@"watchedBeaconRegions: %@", watchedBeaconRegions);
}

- (void) removeBeaconRegionToMonitor:(NSMutableDictionary *)params {
    // Parse Incoming Params
    NSString *beaconId = [[params objectForKey:KEY_BEACON_ID] stringValue];
    NSString *proximityUUID = [params objectForKey:KEY_BEACON_PUUID];
    NSInteger majorInt = [[params objectForKey:KEY_BEACON_MAJOR] intValue];
    NSInteger minorInt = [[params objectForKey:KEY_BEACON_MINOR] intValue];
    NSUUID *puuid = [[NSUUID alloc] initWithUUIDString:proximityUUID];
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:puuid major:majorInt minor:minorInt identifier:beaconId];
    [[[BeaconHelper sharedBeaconHelper] locationManager] stopMonitoringForRegion:beaconRegion];
}


- (void)removeBeaconRegion:(CDVInvokedUrlCommand*)command {
    
    NSString* callbackId = command.callbackId;
    NSLog(@"removeBeaconRegion.callbackId: %@", callbackId);
    NSLog(@"removeBeaconRegion.command.arguments: %@", command.arguments);
    [[BeaconHelper sharedBeaconHelper] saveBeaconCallbackId:callbackId];
    [[BeaconHelper sharedBeaconHelper] setCommandDelegate:self.commandDelegate];
    
    
    NSLog(@"isLocationServicesEnabled: %hhd", [self isLocationServicesEnabled]);
    if (![self isLocationServicesEnabled])
    {
        BOOL forcePrompt = NO;
        NSLog(@"removeRegion.forcePromt: %hhd", forcePrompt);
        if (!forcePrompt)
        {
            NSLog(@"removeRegion.forcePromt: %hhd", forcePrompt);
            [[BeaconHelper sharedBeaconHelper] returnBeaconError:PERMISSIONDENIED withMessage: nil];
            return;
        }
    }
    
    if (![self isAuthorized])
    {
        NSString* message = nil;
        BOOL authStatusAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
        if (authStatusAvailable) {
            NSUInteger code = [CLLocationManager authorizationStatus];
            if (code == kCLAuthorizationStatusNotDetermined) {
                // could return POSITION_UNAVAILABLE but need to coordinate with other platforms
                message = @"User undecided on application's use of location services";
            } else if (code == kCLAuthorizationStatusRestricted) {
                message = @"application use of location services is restricted";
            }
        }
        //PERMISSIONDENIED is only PositionError that makes sense when authorization denied
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:PERMISSIONDENIED withMessage: message];
        
        return;
    }
    
    if (![self isRegionMonitoringAvailable])
    {
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:REGIONMONITORINGUNAVAILABLE withMessage: @"Region monitoring is unavailable"];
        return;
    }
    
    if (![self isRegionMonitoringEnabled])
    {
        [[BeaconHelper sharedBeaconHelper] returnBeaconError:REGIONMONITORINGPERMISSIONDENIED withMessage: @"User has restricted the use of region monitoring"];
        return;
    }
    
    
    NSMutableDictionary *options = [command.arguments objectAtIndex:0];
    [self removeBeaconRegionToMonitor:options];
    
    [[BeaconHelper sharedBeaconHelper] returnBeaconRegionSuccess];
}


-(void)setHost:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* beaconHost = [command.arguments objectAtIndex:0];
    NSLog(@"Parameter: %@", command.arguments);
    NSLog(@"Host: %@", beaconHost);
    
    // Save the host into ne nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:beaconHost forKey:@"BeaconHost"];
    [preferences synchronize]; //at the end of storage
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", beaconHost]];
    if (callbackId) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
    
    
    NSUserDefaults *getBeaconPreferences = [NSUserDefaults standardUserDefaults];
    NSString *getBeaconHost = [getBeaconPreferences objectForKey:@"BeaconHost"];
    NSLog(@"getBeaconHost - objectForKey: %@", getBeaconHost);
    
    NSString *savedHost = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BeaconHost"];
    NSLog(@"savedHost: %@", savedHost);
}


-(void)setToken:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* token = [command.arguments objectAtIndex:0];
    
    
    // Save the host into ne nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:token forKey:@"BeaconUsertoken"];
    [preferences synchronize]; //at the end of storage
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", token]];
    if (callbackId) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
}


@end
