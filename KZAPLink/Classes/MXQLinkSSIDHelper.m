//
//  MXQLinkSSIDHelper.m
//  MXQLink
//
//  Created by Khazan on 2019/8/22.
//

#import "MXQLinkSSIDHelper.h"
#import "MXQLinkMacros.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation MXQLinkSSIDHelper

+ (NSString *)currentSSID {
    
    NSDictionary *info = [self WiFiInfo];
    
    if (!info) {
        
        return nil;
        
    }
    
    return [info valueForKey:@"SSID"];
}

+ (NSString *)currentBSSID {
    
    NSDictionary *info = [self WiFiInfo];
    
    if (!info) {
        
        return nil;
        
    }
    
    return [info valueForKey:@"BSSID"];
}

+ (NSDictionary *)WiFiInfo {
    
    NSDictionary *info;
    
    CFArrayRef myArray = CNCopySupportedInterfaces();
    
    if (myArray != nil) {
        
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        
        if (myDict != nil) {
            
            info = (NSDictionary*)CFBridgingRelease(myDict);
            
        }
        
    }
    
//    NSLog(@"info:%@", info);

    return info;
}

// local IP
+ (NSString *)localIPAddress {
    NSDictionary *ips = [self getBothIPAddresses];
    NSString *localIP = [ips objectForKey:@"wireless"];
    return localIP;
}


+ (NSDictionary *)getBothIPAddresses {
    NSString *WIFI_IF = @"en0";
    NSArray *KNOWN_WIRED_IFS = @[@"en1",@"en2",@"en3",@"en4"];
    NSArray *KNOWN_CELL_IFS = @[@"pdp_ip0",@"pdp_ip1",@"pdp_ip2",@"pdp_ip3"];
    
    const NSString *UNKNOWN_IP_ADDRESS = @"";
    
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithDictionary:@{@"wireless":UNKNOWN_IP_ADDRESS,
                                                                                     @"wired":UNKNOWN_IP_ADDRESS,
                                                                                     @"cell":UNKNOWN_IP_ADDRESS}];
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if (temp_addr->ifa_addr == NULL) {
                continue;
            }
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:WIFI_IF]) {
                    // Get NSString from C String
                    [addresses setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] forKey:@"wireless"];
                    
                }
                // Check if interface is a wired connection
                if([KNOWN_WIRED_IFS containsObject:[NSString stringWithUTF8String:temp_addr->ifa_name]]) {
                    [addresses setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] forKey:@"wired"];
                }
                // Check if interface is a cellular connection
                if([KNOWN_CELL_IFS containsObject:[NSString stringWithUTF8String:temp_addr->ifa_name]]) {
                    [addresses setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] forKey:@"cell"];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return addresses;
}

@end
