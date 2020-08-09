//
//  KZViewController.m
//  KZAPLink
//
//  Created by gujianxing on 01/11/2020.
//  Copyright (c) 2020 gujianxing. All rights reserved.
//

#import "KZViewController.h"
#import <KZAPLink/KZAPLinkManager.h>

@interface KZViewController ()<KZAPLinkManagerDelegate>

@end

@implementation KZViewController

- (IBAction)pairingButtonAction:(UIButton *)sender {
    
    if ([KZAPLinkManager currentSSID]) {
        
        [KZAPLinkManager startWithDelegate:self ssid:@"Mi_zhy" pwd:@"123456789" enduser_key:@"02463d4500400240" regionid:@"47.101.31.245:8008" timeout:30];
        
    } else {
        
        NSLog(@"no ssid");
        
    }
    
}

-(void)APLinkManager:(KZAPLinkManager *)manager succeedWithBindCode:(NSString *)bindCode {
    NSLog(@"KZAPLinkSucceedWithBindCode:%@", bindCode);
    
}

/**
 QLink finish,
 */
- (void)KZAPLinkFinish {
    NSLog(@"KZAPLinkFinish");
}

/**
 QLink percentage

 refresh UI should in main queue

 @param percentage current percentage
 */
- (void)KZAPLinkPercentage:(CGFloat)percentage {
    
    NSLog(@"KZAPLinkPercentage:%lf", percentage);

}



- (void)operatorIPAddress:(void(^)(NSString *operatorIP))handler {
    NSURL *ipURL = [NSURL URLWithString:@"http://ip.taobao.com/service/getIpInfo.php?ip=myip"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionTask *task = [session dataTaskWithURL:ipURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data == nil) {
            handler ? handler(@"0.0.0.0") : nil;
            return;
        }
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            handler ? handler(@"0.0.0.0") : nil;
            return;
        }
        NSString *ipStr = nil;
        if (jsonData && [jsonData[@"code"] integerValue] == 0) { //获取成功
            ipStr = jsonData[@"data"][@"ip"];
        }
        handler ? handler(ipStr ? : @"0.0.0.0") : nil;
    }];
    
    [task resume];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
