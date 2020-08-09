//
//  KZAPLinkManager.h
//  KZAPLink
//
//  Created by Khazan on 2020/1/11.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSNotificationName const KZAPLinkPercentageNotification;

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
 QLink finish,
 */
- (void)KZAPLinkFinish;

/**
 QLink percentage

 refresh UI should in main queue

 @param percentage current percentage
 */
- (void)KZAPLinkPercentage:(CGFloat)percentage;

@end


@interface KZAPLinkManager : NSObject

+ (NSString *)currentSSID;

+ (void)SSID:(void(^)(NSString *ssid))handler;


+ (void)startWithDelegate:(id)delegate ssid:(nonnull NSString *)ssid pwd:(NSString *)pwd enduser_key:(NSString *)enduser_key regionid:(NSString *)regionid timeout:(NSTimeInterval)timeout;

+ (void)stop;

@end

NS_ASSUME_NONNULL_END
