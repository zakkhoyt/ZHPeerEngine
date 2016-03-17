//
//  HostViewController.m
//  ZHPeerEngine
//
//  Created by Zakk Hoyt on 3/16/16.
//  Copyright © 2016 Zakk Hoyt. All rights reserved.
//

#import "HostViewController.h"
#import "GCDAsyncSocket.h"

@interface HostViewController () <NSNetServiceDelegate, GCDAsyncSocketDelegate>

@property (strong, nonatomic) NSNetService *service;
@property (strong, nonatomic) GCDAsyncSocket *socket;

@end

@implementation HostViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Start Broadcast
    [self startBroadcast];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark Helpers

- (void)startBroadcast {
    // Initialize GCDAsyncSocket
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    // Start Listening for Incoming Connections
    NSError *error = nil;
    if ([self.socket acceptOnPort:0 error:&error]) {
        // Initialize Service
        self.service = [[NSNetService alloc] initWithDomain:@"local." type:@"_zakkhoyt._tcp." name:@"" port:[self.socket localPort]];

        // Configure Service
        [self.service setDelegate:self];

        // Publish Service
        [self.service publish];

    } else {
        NSLog(@"Unable to create socket. Error %@ with user info %@.", error, [error userInfo]);
    }
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)service {
    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}

- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)socket didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Accepted New Socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);

    // Socket
    [self setSocket:newSocket];

    // Read Data from Socket
    [newSocket readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.socket == socket) {
        [self.socket setDelegate:nil];
        [self setSocket:nil];
    }
}
@end
