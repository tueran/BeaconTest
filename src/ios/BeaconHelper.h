//
//  BeaconHelper.h
//  Beacon
//
//  Created by Daniel Mauer on 26.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Cordova/CDVJSON.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDV.h>
#import <MapKit/MapKit.h>


enum BeaconLocationStatus {
    PERMISSIONDENIED = 1,
    POSITIONUNAVAILABLE,
    TIMEOUT,
    REGIONMONITORINGPERMISSIONDENIED,
    REGIONMONITORINGUNAVAILABLE,
    SIGNIFICANTLOCATIONMONITORINGUNAVAILABLE
};
typedef NSInteger BeaconLocationStatus;

#pragma mark - LocationData Interface

@interface BeaconLocationData : NSObject

@property (nonatomic, assign) BeaconLocationStatus beaconLocationStatus;
@property (nonatomic, retain) CLLocation* beaconLocationInfo;
@property (nonatomic, retain) NSMutableArray* beaconLocationCallbacks;
@property (nonatomic, retain) NSMutableArray* beaconCallbacks;


@end


#pragma mark - Beacon Helper Interface
@class CDVWebViewDelegate;
@class CDVViewController;
@class CDVPlugin;
@class UIWebView;
@interface BeaconHelper : NSObject <CLLocationManagerDelegate>

@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, retain) CLBeaconRegion* beaconRegion;
@property (nonatomic, assign) UIWebView* webView;
@property (nonatomic, assign) BOOL didLaunchForRegionUpdate;
@property (nonatomic, retain) BeaconLocationData* beaconLocationData;
@property (nonatomic, assign) id <CDVCommandDelegate> commandDelegate;

+(BeaconHelper*)sharedBeaconHelper;

+ (NSString*) applicationDocumentsDirectory;

- (void) returnLocationError: (NSUInteger) errorCode withMessage: (NSString*) message;
- (void) returnBeaconError: (NSUInteger) errorCode withMessage: (NSString*) message;
- (void) returnRegionSuccess;
- (void) returnLocationSuccess;
- (void) saveLocationCallbackId:(NSString *) callbackId;
- (void) returnBeaconRegionSuccess;
- (void) saveBeaconCallbackId:(NSString *) callbackId;


@end
