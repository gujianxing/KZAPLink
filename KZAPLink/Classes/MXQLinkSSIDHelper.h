//
//  MXQLinkSSIDHelper.h
//  MXQLink
//
//  Created by Khazan on 2019/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXQLinkSSIDHelper : NSObject

/**
ssid

@return ssid
*/
+ (NSString *)currentSSID;


/**
 mac

 @return mac address
 */
+ (NSString *)currentBSSID;


/**
local ip

@return local ip
*/
+ (NSString *)localIPAddress;


@end

NS_ASSUME_NONNULL_END
