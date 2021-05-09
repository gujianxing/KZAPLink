//
//  KZAPLinkManager.m
//  KZAPLink
//
//  Created by Khazan on 2020/1/11.
//

#import "KZAPLinkManager.h"
#import <CoreLocation/CoreLocation.h>
#import "MXQLinkTCPSocketServer.h"
#import "MXQLinkSSIDHelper.h"
#import "MXQLinkMacros.h"

NSString * const KZAPLinkPercentageNotification = @"KZAPLinkPercentageNotification";

@interface KZAPLinkManager ()<MXQLinkTCPSocketServerDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) id<KZAPLinkManagerDelegate> delegate;

@property (nonatomic, strong) CLLocationManager *locationManager;  // 获取位置权限

@property (nonatomic, strong) MXQLinkTCPSocketServer *server;  // 等待设备连接

@property (nonatomic, copy) NSString *ssid;

@property (nonatomic, copy) NSString *pwd;

@property (nonatomic, copy) NSString *enduser_key;

@property (nonatomic, copy) NSString *regionid;

@property (nonatomic, copy) NSString *bindCode;

@property (nonatomic, assign) NSTimeInterval configSuccessTime;  // 记录配置成功时间点，完成后轮询接口

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) NSTimeInterval timeout;  // 超时时间
@property (nonatomic, assign) NSTimeInterval times;  // 定时器运行时间

@property (nonatomic, assign) NSTimeInterval timeIntervalStart;  //开始时的时间戳
@property (nonatomic, assign) NSTimeInterval timeIntervalEnterBackground;  // 进入后台时间
@property (nonatomic, assign) NSTimeInterval timeIntervalEnterForeground;  // 回到前台时间

@end

@implementation KZAPLinkManager

void(^getSSID)(NSString *ssid);

+ (void)requestCurrentSSID:(void(^)(NSString *ssid))handler {
    NSInteger access = [self requestAccess];

    if (access == kCLAuthorizationStatusAuthorizedAlways ||
        access == kCLAuthorizationStatusAuthorizedWhenInUse) {
        handler([MXQLinkSSIDHelper currentSSID]);
    } else {
        getSSID = handler;
    }
}

+ (void)startWithDelegate:(id)delegate
                     ssid:(nonnull NSString *)ssid
                      pwd:(NSString *)pwd
              enduser_key:(NSString *)enduser_key 
                 regionid:(NSString *)regionid
                  timeout:(NSTimeInterval)timeout {
    
    [[self sharedInstanced] startWithDelegate:delegate
                                         ssid:ssid
                                          pwd:pwd
                                  enduser_key:enduser_key
                                     regionid:regionid
                                      timeout:timeout];
}

- (void)startWithDelegate:(id)delegate
                     ssid:(nonnull NSString *)ssid
                      pwd:(NSString *)pwd
              enduser_key:(NSString *)enduser_key
                 regionid:(NSString *)regionid
                  timeout:(NSTimeInterval)timeout {
    
    self.delegate = delegate;
    
    self.ssid = ssid;
    
    self.pwd = pwd;
    
    self.enduser_key = enduser_key;
    
    self.regionid = regionid;
    
    self.timeout = timeout;
    
    [self startTimerAndCheck];
}

+ (void)stop {
    
    [[self sharedInstanced] pairStop];
}

/**
 start timer
 */
- (void)startTimerAndCheck {
    
    if (self.timeout < 0) {
        return;
    }

    self.timeIntervalStart = [[NSDate date] timeIntervalSince1970];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    
    [self timer_HotspotConnected_event_handler];
    
    dispatch_resume(self.timer);
}

/**
 waiting user connected the ap
 */
- (void)timer_HotspotConnected_event_handler {
    
    MXQLog(@"check if ap connected");
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_source_set_event_handler(self.timer, ^{
                
        BOOL connected = [[MXQLinkSSIDHelper currentSSID] isEqualToString:MXQLINK_HOTSPOT_SSID];
        
        MXQLog(@"checking");
        
        if (!connected) {
            return ;
        }
        
        MXQLog(@"ap connected");
        
        if ([self.delegate respondsToSelector:@selector(KZAPLinkConnected)]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate performSelector:@selector(KZAPLinkConnected)];
            });
            
        }
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf timer_pairConnected_event_handler];
        
    });
}


- (void)applicationDidEnterBackground {
    self.timeIntervalEnterBackground = [[NSDate date] timeIntervalSince1970];
}

- (void)applicationWillEnterForeground {
    
    if (self.timeIntervalStart < self.timeIntervalEnterBackground) {
        return;
    }
    
    self.timeIntervalEnterForeground = [[NSDate date] timeIntervalSince1970];
    
    self.times += (self.timeIntervalEnterForeground - self.timeIntervalEnterBackground);
}

/**
 percentage
 */
- (void)timer_pairConnected_event_handler {
    
    NSString *timeStr = [self currentTimeStr];
    
    self.server = [MXQLinkTCPSocketServer startWithDelegate:self ssid:self.ssid pwd:self.pwd enduser_key:self.enduser_key bindcode:timeStr regionid:self.regionid];
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_source_set_event_handler(self.timer, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.times += 1;
        
        [strongSelf pairPercentage];
        
        if (strongSelf.times - strongSelf.configSuccessTime > 3) {
            
            strongSelf.configSuccessTime = strongSelf.times;
            
            if ([strongSelf.delegate respondsToSelector:@selector(APLinkManager:succeedWithBindCode:)]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.delegate APLinkManager:strongSelf succeedWithBindCode:strongSelf.bindCode];
                });
            }
            
        }
        
    });
}


- (void)pairPercentage {
    
    CGFloat percentage = self.times / self.timeout;
    
    MXQLog(@"times:%f__percentage:%f", self.times, percentage);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(KZAPLinkPercentage:)]) {
            [self.delegate KZAPLinkPercentage:percentage];
        }
        
    });
    
    if (percentage < 0.9) {
        return;
    }
    
    [self pairStop];
}

/**
 停止配网
 */
- (void)pairStop {
    MXQLog(@"pair Stop");
    
    [self timerStop];
    
    [MXQLinkTCPSocketServer stopServer];
    
    self.server = nil;
        
    MXQLog(@"delegate: %@ respondsToSelector:%d", self.delegate, [self.delegate respondsToSelector:@selector(KZAPLinkEnded)]);
    
    if ([self.delegate respondsToSelector:@selector(KZAPLinkEnded)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate KZAPLinkEnded];
        });
        
    }
}

- (void)timerStop {
    
    self.times = 0;

    if (self.timer == nil) {
        return;
    }
    
    dispatch_source_cancel(self.timer);
    self.timer = nil;
}


#pragma mark MXQLinkTCPSocketServerDelegate

- (void)tcpSocketServerEndSuccessWithBindCode:(NSString *)bindCode {
    
    self.bindCode = bindCode;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(APLinkManager:succeedWithBindCode:)]) {
            [self.delegate APLinkManager:self succeedWithBindCode:bindCode];
        }
        
        self.configSuccessTime = self.times;
        
    });
}

+ (NSInteger)requestAccess {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        
        [[[KZAPLinkManager sharedInstanced] locationManager] requestWhenInUseAuthorization];
        
    }
        
    return status;
}

+ (KZAPLinkManager *)sharedInstanced {
    
    static KZAPLinkManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[KZAPLinkManager alloc] init];
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate = manager;
        
        manager.locationManager = locationManager;
        
    });

    return manager;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"status:%d", status);
    
    getSSID ? getSSID([MXQLinkSSIDHelper currentSSID]) : nil;
    
}

// current timeinterval
- (NSString *)currentTimeStr {
    
    NSDate *date = [NSDate date]; //获取当前时间
    
    NSTimeInterval time = [date timeIntervalSince1970] * 1000; // *1000 是精确到毫秒，不乘就是精确到秒
    
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    
    return timeString;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
