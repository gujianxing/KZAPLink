//
//  MXQLinkTCPSocketServer.m
//  MXQLink
//
//  Created by Khazan on 2019/8/13.
//

#import "MXQLinkTCPSocketServer.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "MXQLinkMacros.h"
#import "MXQLinkSSIDHelper.h"

@interface MXQLinkTCPSocketServer ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socketServer;

@property (nonatomic, strong) NSMutableArray *connectedSockets;

@property (nonatomic, strong) dispatch_queue_t socketQueue;

/**
 tcp server status
 */
@property (nonatomic, assign) BOOL status;

@property (nonatomic, copy) NSString *ssid;

@property (nonatomic, copy) NSString *pwd;

@property (nonatomic, copy) NSString *enduser_key;

@property (nonatomic, copy) NSString *bindcode;

@property (nonatomic, copy) NSString *regionid;

@end

@implementation MXQLinkTCPSocketServer

+ (MXQLinkTCPSocketServer *)startWithDelegate:(id)delegate
                                         ssid:(NSString *)ssid
                                          pwd:(NSString *)pwd
                                  enduser_key:(NSString *)enduser_key
                                     bindcode:(NSString *)bindcode
                                     regionid:(NSString *)regionid {
    
    MXQLinkTCPSocketServer *manager = [self sharedInstanced];
    
    manager.delegate = delegate;
    
    manager.ssid = ssid;
    
    manager.pwd = pwd;
    
    manager.enduser_key = enduser_key;
    
    manager.bindcode = bindcode;

    manager.regionid = regionid;

    [manager startServer];
    
    return manager;
}

+ (void)stopServer {
    
    MXQLinkTCPSocketServer *manager = [self sharedInstanced];
    
    [manager stopServer];
}

+ (BOOL)status {
    
    return [[self sharedInstanced] status];
}

- (void)startServer {
    
    self.connectedSockets = [NSMutableArray arrayWithCapacity:1];
    
    self.socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    self.socketServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
    
    NSError *accpetError;
    
    BOOL status = [self.socketServer acceptOnPort:MXQLINK_TCP_SOCKET_SERVER_PORT error:&accpetError];
    
    self.status = status;
    
    if (status) {
        MXQLog(@"start server on ssid:%@ mac:%@ address:%@ port: %hu", [MXQLinkSSIDHelper currentSSID], [MXQLinkSSIDHelper currentBSSID], [MXQLinkSSIDHelper localIPAddress], [self.socketServer localPort]);
    } else {
        MXQLog(@"start server accpet error: %@", accpetError);
    }
}

- (void)stopServer {
    MXQLog(@"stop server");
    
    if (self.delegate == nil) {
        return;
    }
    
    self.status = NO;
    
    // disconnect
    @synchronized(self.connectedSockets)
    {
        NSUInteger i;
        for (i = 0; i < [self.connectedSockets count]; i++)
        {
            [[self.connectedSockets objectAtIndex:i] disconnect];
        }
    }
    
    [self.connectedSockets removeAllObjects];
    
    [self.socketServer disconnect];
    
    self.socketServer = nil;
    
    self.delegate = nil;
}

#pragma socket delegate

// new socket connection
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
    @synchronized(self.connectedSockets)
    {
        [self.connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    
    UInt16 port = [newSocket connectedPort];
    
    MXQLog(@"Accepted client %@:%hu", host, port);
    
    // read socket data
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:MXQLINK_TCP_SOCKET_SERVER_READ_TIMEOUT tag:[self.connectedSockets indexOfObject:newSocket]];
}

// read data
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:MXQLINK_TCP_SOCKET_SERVER_READ_TIMEOUT tag:tag];
}

// 解析收到的消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSData *jsonData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
    
    NSError *error;
    
    id result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    
    if (error) {
        MXQLog(@"json_error: %@", error);
        return;
    }
    
    if (![result isKindOfClass:[NSDictionary class]]) {
        MXQLog(@"wifi数据格式错误: %@", result);
        return;
    }
    
    MXQLog(@"didReadData: %@", result);
    
    NSNumber *code = result[@"code"];
    
    if (code.integerValue == 100) {
        
        // 固件已连接，可以接收配网数据
        [self clientConnectedAndReady];
        
    } else if (code.integerValue == 0) {
        
        // 固件已收到配网数据
        [self clientDidRecivedData];
    };
    
}

// timeout
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    MXQLog(@"wait client response time out");
    
    return 0.0;
}

// disconnected
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (sock != self.socketServer) {
        MXQLog(@"socket client Did Disconnect: %@ error:%@", sock, err);
        @synchronized(self.connectedSockets) {
            [self.connectedSockets removeObject:sock];
        }
    } else {
        MXQLog(@"socket server Did Disconnect: %@ error:%@", sock, err);
    }
}


/**
 设备已连接
 
 设备已准备好，开始发送配网数据到固件
 */
- (void)clientConnectedAndReady {
    
    [self sendMessageWithSSID:self.ssid pwd:self.pwd enduser_key:self.enduser_key bindcode:self.bindcode regionid:self.regionid];
}


/**
 设备已收到配网数据
 
 回执200，告诉设备关闭softap 开始查询绑定状态
 */
- (void)clientDidRecivedData {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendMessageWithCode:200];
        
        if ([self.delegate respondsToSelector:@selector(tcpSocketServerEndSuccessWithBindCode:)]) {
            [self.delegate tcpSocketServerEndSuccessWithBindCode:self.bindcode];
        }
        
        [self stopServer];
    });
}



/**
 发送配网数据到设备

 @param ssid ssid
 @param pwd pwd
 @param token token
 @param bindCode bindcode
 */
- (void)sendMessageWithSSID:(NSString *)ssid pwd:(NSString *)pwd enduser_key:(NSString *)enduser_key bindcode:(NSString *)bindcode regionid:(NSString *)regionid {
    
    NSString *extraData = nil;
        
    NSDictionary *params = @{@"type": @"config",
                             @"data": @{@"enduser_key": enduser_key ? : @"",
                                        @"bindcode": bindcode ? : @"",
                                        @"regionid": regionid ? : @"",
                                        @"ssid": ssid ? : @"",
                                        @"password": pwd ? : @"",
                                        @"extraData": extraData ? : @""
                                        }
                             };
    
    NSLog(@"pairing with params:%@", params);
    
    [self sendMessageWithObject:params];
}


/**
 发送状态码到设备

 @param code 告诉设备关闭ap
 */
- (void)sendMessageWithCode:(NSInteger)code {
    NSDictionary *params = @{@"code": [NSNumber numberWithInteger:200]};
    
    [self sendMessageWithObject:params];
}


- (void)sendMessageWithObject:(id)object {
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        
        MXQLog(@"json_error: %@", error);
        
    } else {
        
        for (GCDAsyncSocket *socket in self.connectedSockets) {
            [socket writeData:jsonData withTimeout:MXQLINK_TCP_SOCKET_SERVER_READ_TIMEOUT tag:[self.connectedSockets indexOfObject:socket]];
        }
        
    }
}




+ (MXQLinkTCPSocketServer *)sharedInstanced {
    static MXQLinkTCPSocketServer *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MXQLinkTCPSocketServer alloc] init];
    });
    return manager;
}


// current timeinterval
- (NSString *)currentTimeStr {
    
    NSDate *date = [NSDate date]; //获取当前时间
    
    NSTimeInterval time = [date timeIntervalSince1970] * 1000; // *1000 是精确到毫秒，不乘就是精确到秒
    
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    
    return timeString;
}


@end
