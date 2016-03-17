//
//  JoinViewController.m
//  ZHPeerEngine
//
//  Created by Zakk Hoyt on 3/16/16.
//  Copyright © 2016 Zakk Hoyt. All rights reserved.
//

#import "JoinViewController.h"
#import "GCDAsyncSocket.h"

@interface JoinViewController () <UITableViewDataSource, UITableViewDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) NSMutableArray *services;
@property (strong, nonatomic) NSNetServiceBrowser *serviceBrowser;

@end

@implementation JoinViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self startBrowsing];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopBrowsing];

    if (_socket.connectedAddress) {
        [_socket disconnect];
    }
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

- (void)startBrowsing {
    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [[NSMutableArray alloc] init];
    }

    // Initialize Service Browser
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];

    // Configure Service Browser
    [self.serviceBrowser setDelegate:self];
    [self.serviceBrowser searchForServicesOfType:@"_zakkhoyt._tcp." inDomain:@"local."];
}

- (void)stopBrowsing {
    if (self.serviceBrowser) {
        [self.serviceBrowser stop];
        [self.serviceBrowser setDelegate:nil];
        [self setServiceBrowser:nil];
    }
}

- (BOOL)connectWithService:(NSNetService *)service {
    BOOL _isConnected = NO;

    // Copy Service Addresses
    NSArray *addresses = [[service addresses] mutableCopy];

    if (!self.socket || ![self.socket isConnected]) {
        // Initialize Socket
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

        // Connect
        while (!_isConnected && [addresses count]) {
            NSData *address = [addresses objectAtIndex:0];

            NSError *error = nil;
            if ([self.socket connectToAddress:address error:&error]) {
                _isConnected = YES;

            } else if (error) {
                NSLog(@"Unable to connect to address. Error %@ with user info %@.", error, [error userInfo]);
            }
        }

    } else {
        _isConnected = [self.socket isConnected];
    }

    return _isConnected;
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.services ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceCell"];

    // Fetch Service
    NSNetService *service = [self.services objectAtIndex:[indexPath row]];

    // Configure Cell
    [cell.textLabel setText:[service name]];

    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch Service
    NSNetService *service = [self.services objectAtIndex:[indexPath row]];

    // Resolve Service
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services addObject:service];

    if (!moreComing) {
        // Sort Services
        [self.services sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];

        // Update Table View
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services removeObject:service];

    if (!moreComing) {
        // Update Table View
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)serviceBrowser {
    [self stopBrowsing];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didNotSearch:(NSDictionary *)userInfo {
    [self stopBrowsing];
}

#pragma mark NSNetServiceDelegate

- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    [service setDelegate:nil];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    // Connect With Service
    if ([self connectWithService:service]) {
        NSLog(@"Did Connect with Service: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);

        NSString *message = @"Hello server!";
        NSData *payload = [message dataUsingEncoding:NSUTF8StringEncoding];

        [self.socket writeData:payload withTimeout:5 tag:0];
    } else {
        NSLog(@"Unable to Connect with Service: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
    }
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Socket Did Connect to Host: %@ Port: %hu", host, port);

    // Start Reading
    [socket readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    NSLog(@"Socket Did Disconnect with Error %@ with User Info %@.", error, [error userInfo]);

    [socket setDelegate:nil];
    [self setSocket:nil];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Socket did write data with tag: %ld", tag);
}

@end
