//
//  KZAPLinkManager.h
//  KZAPLink
//
//  Created by Khazan on 2020/1/11.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSNotificationName const _Nullable KZAPLinkPercentageNotification;

NS_ASSUME_NONNULL_BEGIN

@class KZAPLinkManager;

/**
 * delegate gives your application access to received messages
 *
 */
@protocol KZAPLinkManagerDelegate <NSObject>

/**
  QLink success
 
 refresh UI should in main queue

 @param bindCode check bindstatus in server
 */
- (void)APLinkManager:(KZAPLinkManager *)manager succeedWithBindCode:(NSString *)bindCode;


/**
QLink AP Connected
*/
- (void)KZAPLinkConnected;


/**
 QLink ended,
 */
- (void)KZAPLinkEnded;

/**
 QLink percentage

 refresh UI should in main queue

 @param percentage current percentage
 */
- (void)KZAPLinkPercentage:(CGFloat)percentage;

@end


@interface KZAPLinkManager : NSObject

/// get current ssid
/// @param handler ssid
+ (void)requestCurrentSSID:(void(^)(NSString *ssid))handler;

/// start pair
/// @param delegate  delegate
/// @param ssid  ssid
/// @param pwd  password
/// @param enduser_key enduser_key
/// @param regionid  regionid
/// @param timeout  timeout
+ (void)startWithDelegate:(id)delegate
                     ssid:(nonnull NSString *)ssid
                      pwd:(NSString *)pwd
              enduser_key:(NSString *)enduser_key
                 regionid:(NSString *)regionid
                  timeout:(NSTimeInterval)timeout;

/// stop pair
+ (void)stop;

@end

NS_ASSUME_NONNULL_END
