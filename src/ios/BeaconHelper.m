//
//  BeaconHelper.m
//  Beacon
//
//  Created by Daniel Mauer on 26.06.14.
//
//

#import "BeaconHelper.h"


static BeaconHelper *sharedBeaconHelper = nil;

#pragma mark - LocationData Implementation

@implementation BeaconLocationData

@synthesize beaconLocationStatus, beaconLocationInfo;
@synthesize beaconLocationCallbacks;
//@synthesize geofenceCallbacks;

@synthesize beaconCallbacks;

-(BeaconLocationData*) init
{
    self = (BeaconLocationData*)[super init];
    if (self) {
        self.beaconLocationInfo = nil;
    }
    return self;
}

@end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#pragma mark - BeaconHelper Implementation
@implementation BeaconHelper

@synthesize webView;
@synthesize locationManager;
@synthesize beaconRegion;
@synthesize beaconLocationData;
@synthesize didLaunchForRegionUpdate;
@synthesize commandDelegate;



-(void)saveLocationCallbackId:(NSString *)callbackId
{
    if (!self.beaconLocationData) {
        self.beaconLocationData = [[BeaconLocationData alloc] init];
    }
    
    BeaconLocationData* lData = self.beaconLocationData;
    if (!lData.beaconLocationCallbacks) {
        lData.beaconLocationCallbacks = [NSMutableArray array];
    }
    
    // add the callbackId into the array so we cann call back when get data
    [lData.beaconLocationCallbacks enqueue:callbackId];
}


#pragma mark - location Manager

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [posError setObject: [NSNumber numberWithInt: error.code] forKey:@"code"];
    [posError setObject: region.identifier forKey: @"regionid"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }
    self.beaconLocationData.beaconCallbacks = [NSMutableArray array];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: error.code] forKey:@"code"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconLocationCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }
    self.beaconLocationData.beaconLocationCallbacks = [NSMutableArray array];
}

- (void) returnRegionSuccess; {
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
    [posError setObject: @"Region Success" forKey: @"message"];
    
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
    }
    self.beaconLocationData.beaconCallbacks = [NSMutableArray array];
}


- (void) returnLocationSuccess; {
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
    [posError setObject: @"Region Success" forKey: @"message"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posError];
    for (NSString* callbackId in self.beaconLocationData.beaconLocationCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }
    
    
    self.beaconLocationData.beaconLocationCallbacks = [NSMutableArray array];
}


- (void) returnLocationError: (NSUInteger) errorCode withMessage: (NSString*) message
{
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: errorCode] forKey:@"code"];
    [posError setObject: message ? message : @"" forKey: @"message"];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconLocationCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
    }
    
    self.beaconLocationData.beaconLocationCallbacks = [NSMutableArray array];
}

- (void) returnBeaconError: (NSUInteger) errorCode withMessage: (NSString*) message
{
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: errorCode] forKey:@"code"];
    [posError setObject: message ? message : @"" forKey: @"message"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }
    self.beaconLocationData.beaconCallbacks = [NSMutableArray array];
}

- (id) init {
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
        self.beaconLocationData = nil;
        
    }
    return self;
}

+(BeaconHelper *)sharedBeaconHelper
{
    //objects using shard instance are responsible for retain/release count
    //retain count must remain 1 to stay in mem
    
    if (!sharedBeaconHelper)
    {
        sharedBeaconHelper = [[BeaconHelper alloc] init];
    }
    
    return sharedBeaconHelper;
}


+ (NSString*) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}



#pragma mark - iBeacon

-(void)saveBeaconCallbackId:(NSString *)callbackId
{
    if (!self.beaconLocationData) {
        self.beaconLocationData = [[BeaconLocationData alloc] init];
    }
    
    BeaconLocationData* lData = self.beaconLocationData;
    if (!lData.beaconCallbacks) {
        lData.beaconCallbacks = [NSMutableArray array];
    }
    
    // add the callbackId into the array so we can call back when get data
    [lData.beaconCallbacks enqueue:callbackId];
}


- (void) returnBeaconRegionSuccess; {
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    [posError setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
    [posError setObject: @"BeaconRegion Success" forKey: @"message"];
    
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posError];
    for (NSString *callbackId in self.beaconLocationData.beaconCallbacks) {
        if (callbackId) {
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
    }
    self.beaconLocationData.beaconCallbacks = [NSMutableArray array];
}



- (void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    
    // Load the storage data from nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *getHost = [preferences stringForKey:@"BeaconHost"];
    NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
    
    /*
     NSLog(@"Enter Region with beacon: %@", region.identifier);
     NSLog(@"----> Beacon Region: %@", beaconRegion);
     NSLog(@"----> Beacon Region with region: %@", region);
     NSLog(@"Beacon sharedBeaconHelper: %@", [BeaconHelper sharedBeaconHelper]);
     NSLog(@"Beacon sharedBeaconHelper Locationmanager: %@", [[BeaconHelper sharedBeaconHelper] locationManager]);
     */
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegionNew = (CLBeaconRegion *)region;
        
        NSLog(@"Passt ------- OK");
        NSLog(@"New CLBeaconRegion: %@", beaconRegionNew);
        [self.locationManager startRangingBeaconsInRegion:beaconRegionNew];
    }
    
    CLBeaconRegion *beaconRegionNew2 = (CLBeaconRegion *)region;
    [[[BeaconHelper sharedBeaconHelper] locationManager] startRangingBeaconsInRegion:beaconRegionNew2];
    
}

- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // Load the storage data from nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *getHost = [preferences stringForKey:@"BeaconHost"];
    NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
    
    NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/away?s=&token=%@", getHost, region.identifier, getUsertoken];
    NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
    //NSLog(@"URL: %@", sfUrl);
    
    // set the request
    NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
    NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
    __block NSUInteger tries = 0;
    
    typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
    __block CompletionBlock completionHandler = nil;
    
    // Block to start the request
    dispatch_block_t enqueueBlock = ^{
        [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
    };
    
    completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
        tries++;
        if (sfError) {
            if (tries < 3) {
                enqueueBlock();
                NSLog(@"Error: %@", sfError);
            } else {
                NSLog(@"Cancel");
            }
        } else {
            NSString* myResponse;
            myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
        }
    };
    
    //NSLog(@"Exit Region");
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegionNew = (CLBeaconRegion *)region;
        [self.locationManager stopRangingBeaconsInRegion:beaconRegionNew];
        //NSLog(@"No more beaconRanging");
    }
    
    enqueueBlock();
    
}


-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    //NSLog(@"didRangeBeacons");
    //NSLog(@"all beacons: %lu", (unsigned long)[beacons count]);
    CLBeacon *beacon = [[CLBeacon alloc] init];
    beacon = [beacons lastObject];
    
    
    for (CLBeacon *beacon in beacons) {
        /*
         NSLog(@"Count: %d", beacons.count);
         NSLog(@"Ranging beacon: %@", beacon.proximityUUID);
         NSLog(@"%@ - %@", beacon.major, beacon.minor);
         NSLog(@"Range: %@", [self stringForProximity:beacon.proximity]);
         NSLog(@"==========================================================");
         
         NSLog(@"----------------------------------------");
         NSLog(@"--------------PROXIMITY-----------------");
         NSLog(@"----------------------------------------");
         */
        if (beacon.proximity == CLProximityUnknown) {
            //NSLog(@"Proximity: Unknown: %d", beacon.proximity);
            
            // Load the storage data from nsuserdefaults
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *getHost = [preferences stringForKey:@"BeaconHost"];
            NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
            //NSLog(@"nsuserdefaultsgetHost: %@", getHost);
            
            NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/away?s=&token=%@", getHost, region.identifier, getUsertoken];
            NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
            //NSLog(@"URL: %@", sfUrl);
            // set the request
            NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
            NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
            __block NSUInteger tries = 0;
            
            typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
            __block CompletionBlock completionHandler = nil;
            
            // Block to start the request
            dispatch_block_t enqueueBlock = ^{
                [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
            };
            
            completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
                tries++;
                if (sfError) {
                    if (tries < 3) {
                        enqueueBlock();
                        NSLog(@"Error: %@", sfError);
                    } else {
                        NSLog(@"Abbruch nach 3 Versuchen.");
                    }
                } else {
                    NSString* myResponse;
                    myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
                }
            };
            
            
            // Load NSUserDefaults
            NSDate *savedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
            
            
            // if savedDate = nil set current time + 5 minutes
            if (savedDate == nil) {
                NSLog(@"No entry found");
                NSDate *dateNow = [NSDate date];
                NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                // Save the timer into ne nsuserdefaults
                NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                [setBeaconTimers synchronize]; //at the end of storage
            }
            
            // compare current date and saved date
            NSDate *dateNow = [NSDate date];
            switch ([dateNow compare:savedDate]){
                case NSOrderedAscending:
                    NSLog(@"NSOrderedAscending");
                    NSLog(@"Time is into the future");
                    
                    break;
                case NSOrderedSame:
                    NSLog(@"NSOrderedSame");
                    break;
                case NSOrderedDescending:
                    NSLog(@"NSOrderedDescending");
                    NSLog(@"Date is in past");
                    
                    NSDate *dateNow = [NSDate date];
                    NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                    // Save the timer into ne nsuserdefaults
                    NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                    [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                    [setBeaconTimers synchronize]; //at the end of storage
                    
                    enqueueBlock();
                    
                    break;
            }
            
            
            
        } else if (beacon.proximity == CLProximityImmediate) {
            //NSLog(@"Proximity: Immediate: %d", beacon.proximity);
            
            // Load the storage data from nsuserdefaults
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *getHost = [preferences stringForKey:@"BeaconHost"];
            NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
            
            
            NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/immediate?s=&token=%@", getHost, region.identifier, getUsertoken];
            NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
            
            // set the request
            NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
            NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
            __block NSUInteger tries = 0;
            
            typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
            __block CompletionBlock completionHandler = nil;
            
            // Block to start the request
            dispatch_block_t enqueueBlock = ^{
                [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
            };
            
            completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
                tries++;
                if (sfError) {
                    if (tries < 3) {
                        enqueueBlock();
                        NSLog(@"Error: %@", sfError);
                    } else {
                        NSLog(@"Cancel");
                    }
                } else {
                    NSString* myResponse;
                    myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
                }
            };
            
            //[NSTimer scheduledTimerWithTimeInterval:.06 target:self selector:@selector(goToSecondButton:) userInfo:nil repeats:NO];
            
            //enqueueBlock();
            
            // Load NSUserDefaults
            NSDate *savedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
            
            // if savedDate = nil set current time + 5 minutes
            if (savedDate == nil) {
                //NSLog(@"No entry found");
                NSDate *dateNow = [NSDate date];
                NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                // Save the timer into ne nsuserdefaults
                NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                [setBeaconTimers synchronize]; //at the end of storage
                
                enqueueBlock();
            }
            
            // compare current date and saved date
            NSDate *dateNow = [NSDate date];
            switch ([dateNow compare:savedDate]){
                case NSOrderedAscending:
                    NSLog(@"NSOrderedAscending");
                    NSLog(@"Time is into the future");
                    
                    
                    break;
                case NSOrderedSame:
                    NSLog(@"NSOrderedSame");
                    break;
                case NSOrderedDescending:
                    NSLog(@"NSOrderedDescending");
                    NSLog(@"Date is in past");
                    
                    NSDate *dateNow = [NSDate date];
                    NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                    // Save the timer into ne nsuserdefaults
                    NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                    [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                    [setBeaconTimers synchronize]; //at the end of storage
                    
                    enqueueBlock();
                    
                    break;
            }
            
            
        } else if (beacon.proximity == CLProximityNear) {
            //NSLog(@"Proximity: Near: %d", beacon.proximity);
            
            // Load the storage data from nsuserdefaults
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *getHost = [preferences stringForKey:@"BeaconHost"];
            NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
            
            NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/near?s=&token=%@", getHost, region.identifier, getUsertoken];
            NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
            
            // set the request
            NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
            NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
            __block NSUInteger tries = 0;
            
            typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
            __block CompletionBlock completionHandler = nil;
            
            // Block to start the request
            dispatch_block_t enqueueBlock = ^{
                [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
            };
            
            completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
                tries++;
                if (sfError) {
                    if (tries < 3) {
                        enqueueBlock();
                        NSLog(@"Error: %@", sfError);
                    } else {
                        NSLog(@"Cancel");
                    }
                } else {
                    NSString* myResponse;
                    myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
                }
            };
            
            //enqueueBlock();
            
            // Load NSUserDefaults
            NSDate *savedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
            
            // if savedDate = nil set current time + 5 minutes
            if (savedDate == nil) {
                //NSLog(@"No entry found");
                NSDate *dateNow = [NSDate date];
                NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                // Save the timer into ne nsuserdefaults
                NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                [setBeaconTimers synchronize]; //at the end of storage
                
                enqueueBlock();
            }
            
            // compare current date and saved date
            NSDate *dateNow = [NSDate date];
            switch ([dateNow compare:savedDate]){
                case NSOrderedAscending:
                    NSLog(@"NSOrderedAscending");
                    NSLog(@"Time is into the future");
                    
                    
                    break;
                case NSOrderedSame:
                    NSLog(@"NSOrderedSame");
                    break;
                case NSOrderedDescending:
                    NSLog(@"NSOrderedDescending");
                    NSLog(@"Date is in past");
                    
                    NSDate *dateNow = [NSDate date];
                    NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                    // Save the timer into ne nsuserdefaults
                    NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                    [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                    [setBeaconTimers synchronize]; //at the end of storage
                    
                    enqueueBlock();
                    
                    break;
            }
            
            
            
        } else if (beacon.proximity == CLProximityFar) {
            NSLog(@"Proximity: Far: %d", beacon.proximity);
            
            
            // Load the storage data from nsuserdefaults
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *getHost = [preferences stringForKey:@"BeaconHost"];
            NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
            NSLog(@"nsuserdefaultsgetHost: %@", getHost);
            
            // Build url to call
            NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/far?s=&token=%@", getHost, region.identifier, getUsertoken];
            //"https://" + host + "/sf/beacons/" + id + "/" + proximity + "?s=&token=" + token;
            NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
            NSLog(@"URL: %@", sfUrl);
            // set the request
            NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
            NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
            __block NSUInteger tries = 0;
            
            typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
            __block CompletionBlock completionHandler = nil;
            
            // Block to start the request
            dispatch_block_t enqueueBlock = ^{
                [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
            };
            
            completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
                tries++;
                if (sfError) {
                    if (tries < 3) {
                        enqueueBlock();
                        NSLog(@"Error: %@", sfError);
                    } else {
                        NSLog(@"Cancel");
                    }
                } else {
                    NSString* myResponse;
                    myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
                    
                }
            };
            
            //enqueueBlock();
            
            NSDate *entryDate = [NSDate date];
            NSLog(@"Date: %@", entryDate);
            NSDate *entryDateIntervall = [[NSDate date] dateByAddingTimeInterval:300];
            NSLog(@"DateIntervall: %@", entryDateIntervall);
            
            NSDate *dateNow = [NSDate date];
            /*
             NSLog(@"Date Now: %@", dateNow);
             NSLog(@"Date Three: dateOne + 5 minutes: %@", dateSaved);
             NSLog(@"Region.identifier: %@", region.identifier);
             */
            
            // Load NSUserDefaults
            NSDate *savedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
            
            // if savedDate = nil set current time + 5 minutes
            if (savedDate == nil) {
                NSLog(@"No entry found");
                NSDate *dateNow = [NSDate date];
                NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                // Save the timer into ne nsuserdefaults
                NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                [setBeaconTimers synchronize]; //at the end of storage
                
                enqueueBlock();
            }
            
            // compare current date and saved date
            switch ([dateNow compare:savedDate]){
                case NSOrderedAscending:
                    NSLog(@"NSOrderedAscending");
                    NSLog(@"Time is into the future");
                    
                    
                    break;
                case NSOrderedSame:
                    NSLog(@"NSOrderedSame");
                    break;
                case NSOrderedDescending:
                    NSLog(@"NSOrderedDescending");
                    NSLog(@"Date is in past");
                    
                    NSDate *dateNow = [NSDate date];
                    NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
                    // Save the timer into ne nsuserdefaults
                    NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
                    [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", region.identifier, [self stringForProximity:beacon.proximity]]];
                    [setBeaconTimers synchronize]; //at the end of storage
                    
                    enqueueBlock();
                    
                    break;
            }
            
            
            
        }
        
        
    }
    
    
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (state == CLRegionStateInside) {
        CLBeaconRegion *beaconRegionNew = (CLBeaconRegion *)region;
        [[[BeaconHelper sharedBeaconHelper] locationManager] startRangingBeaconsInRegion:beaconRegionNew];
        NSLog(@"---- CALLLLLLLLLL");
    }
}

- (NSString *)stringForProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityUnknown:    return @"Away";
        case CLProximityFar:        return @"Far";
        case CLProximityNear:       return @"Near";
        case CLProximityImmediate:  return @"Immediate";
        default:
            return nil;
    }
}


@end

