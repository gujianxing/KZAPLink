//
//  MXQLinkTCPSocketServer.h
//  MXQLink
//
//  Created by Khazan on 2019/8/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MXQLinkTCPSocketServerDelegate <NSObject>

/**
 get the bindCode and request the bind result from server.

 @param bindCode only
 */
- (void)tcpSocketServerEndSuccessWithBindCode:(NSString *)bindCode;

@end



@interface MXQLinkTCPSocketServer : NSObject

@property (nonatomic, weak) id<MXQLinkTCPSocketServerDelegate> delegate;

+ (MXQLinkTCPSocketServer *)startWithDelegate:(id)delegate ssid:(NSString *)ssid pwd:(NSString *)pwd enduser_key:(NSString *)enduser_key bindcode:(NSString *)bindcode regionid:(NSString *)regionid;

+ (void)stopServer;

+ (BOOL)status;

@end

NS_ASSUME_NONNULL_END
