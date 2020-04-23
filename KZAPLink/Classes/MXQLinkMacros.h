//
//  Header.h
//  Pods
//
//  Created by Khazan on 2019/8/13.
//

#ifndef Header_h
#define Header_h

#define MXQLog(format, ...) NSLog(@"%@\n", [NSString stringWithFormat:(format), ##__VA_ARGS__])

#define MXQLINK_HOTSPOT_SSID @"anxin_smart_ap"

#define MXQLINK_TCP_SOCKET_SERVER_PORT 30123

#define MXQLINK_TCP_SOCKET_SERVER_READ_TIMEOUT 15
#define MXQLINK_TCP_SOCKET_SERVER_READ_TIMEOUT_EXTENSION 10

#define MXQ_APPLICATION [UIApplication sharedApplication]

#endif /* Header_h */



