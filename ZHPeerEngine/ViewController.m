//
//  ViewController.m
//  ZHPeerEngine
//
//  Created by Zakk Hoyt on 3/16/16.
//  Copyright © 2016 Zakk Hoyt. All rights reserved.
//

#import "ViewController.h"
#import "HostViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"SegueMainToHost"]) {
//    }
//}
- (IBAction)hostGameAction:(id)sender {
    [self performSegueWithIdentifier:@"SegueMainToHost" sender:nil];
}

- (IBAction)joinGameAction:(id)sender {
    [self performSegueWithIdentifier:@"SegueMainToJoin" sender:nil];
}

@end
