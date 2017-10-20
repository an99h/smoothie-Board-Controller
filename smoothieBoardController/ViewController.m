//
//  ViewController.m
//  testUart
//
//  Created by ANG on 2017/10/17.
//  Copyright © 2017年 IAC. All rights reserved.
//

#import "ViewController.h"
//#import "ORSSerialPort.h"
//#import "ORSSerialPortManager.h"
#import <ORSSerial/ORSSerial.h>

@interface ViewController ()<ORSSerialPortDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, assign) float tempLimit;
@property (assign) BOOL isRelativeHomeBtnClick;
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
@property (nonatomic, strong) NSArray *availableBaudRates;
@property (unsafe_unretained) IBOutlet NSTextView *receivedDataTextView;
@property (weak) IBOutlet NSPopUpButton *serialPortsPop;
@property (weak) IBOutlet NSPopUpButton *serialBoudRatePop;
@property (weak) IBOutlet NSButton *openCloseButton;
@property (weak) IBOutlet NSButton *serialRefreshButton;
@property (weak) IBOutlet NSButton *YPlusBtn;
@property (weak) IBOutlet NSButton *YMinusBtn;
@property (weak) IBOutlet NSButton *XPlusBtn;
@property (weak) IBOutlet NSButton *XMinusBtn;
@property (weak) IBOutlet NSButton *ZPlusBtn;
@property (weak) IBOutlet NSButton *ZMinusBtn;
@property (weak) IBOutlet NSButton *HomeBtn;
@property (weak) IBOutlet NSButton *absoulteBtn;
@property (weak) IBOutlet NSButton *relativeBtn;
@property (weak) IBOutlet NSTextField *sendText;
@property (weak) IBOutlet NSPopUpButton *endStrPop;
@property (weak) IBOutlet NSButton *sendMessageBtn;
@property (weak) IBOutlet NSTextField *delayTime;
@property (weak) IBOutlet NSButton *checkBox;
@property (weak) IBOutlet NSTextField *limitDistance;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //add uart port list
    [self serialPortList];
    
    //add boudrate list to popBtn
    [self.serialBoudRatePop removeAllItems];
    [self.serialBoudRatePop addItemsWithTitles:@[@"9600",@"115200",@"230400"]];
    [self.serialBoudRatePop selectItemAtIndex:1];
    
    //add send message endstring to popBtn
    [self.endStrPop removeAllItems];
    [self.endStrPop addItemsWithTitles:@[@"CR(\\r)",@"LF(\\n)",@"CRLF(\\r\\n)"]];
    
    //Notification of serial port connect or disconnect
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
    [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
    //Notification of sendText
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableSendMessageBtn) name:NSControlTextDidChangeNotification object:nil];
}

- (void)enableSendMessageBtn
{
    self.sendMessageBtn.enabled = self.endStrPop.enabled = [self.sendText.stringValue length] ? true : false;
}

- (void)serialPortList{
    NSArray *ports = [NSArray arrayWithArray:self.serialPortManager.availablePorts];
    NSLog(@"%@",ports);
    [self.serialPortsPop removeAllItems];
    for (int i = 0; i < ports.count; i++) {
        [self.serialPortsPop addItemWithTitle:[NSString stringWithFormat:@"%@",ports[i]]];
    }
//    [self.serialPortsPop selectItemAtIndex:1];
}

#pragma mark Action functions
- (IBAction)openOrClosePort:(id)sender
{
    self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
}

- (IBAction)refreshSerialPort:(NSButton *)sender {
    [self serialPortList];
}

- (IBAction)sendMessageBtn:(NSButton *)sender {
    if ([self.sendText.stringValue length] > 0) {
        NSString *endString = @"";
        if ([self.endStrPop.title isEqualToString:@"CR(\\r)"]) {
            endString = @"\r";
        }else if([self.endStrPop.title isEqualToString:@"LF(\\n)"]){
            endString = @"\n";
        }else if ([self.endStrPop.title isEqualToString:@"CRLF(\\r\\n)"]){
            endString = @"\r\n";
        }
        [self sendMessage:[NSString stringWithFormat:@"%@,%@",self.sendText.stringValue,endString]];
    }
}

- (IBAction)moveBtn:(NSButton *)sender {
    
    self.tempLimit = [self.limitDistance floatValue];
    if (self.serialPort.isOpen == YES) {
        if ([sender.title isEqualToString:@"Y+"]) {
            NSLog(@"Y+");
            [self move:@"Y"];
        }else if([sender.title isEqualToString:@"Y-"]) {
            NSLog(@"Y-");
            [self move:@"Y-"];
        }else if([sender.title isEqualToString:@"X+"]) {
            NSLog(@"X+");
            [self move:@"X"];
        }else if([sender.title isEqualToString:@"X-"]) {
            NSLog(@"X-");
            [self move:@"X-"];
        }else if([sender.title isEqualToString:@"Z+"]) {
            NSLog(@"Z+");
            [self move:@"Z+"];
        }else if([sender.title isEqualToString:@"Z-"]) {
            NSLog(@"Z-");
            [self move:@"Z-"];
        }else if([sender.title isEqualToString:@"Home"]) {
            NSLog(@"home");
            self.limitDistance.floatValue = self.tempLimit;
            if(self.relativeBtn.state){
                self.isRelativeHomeBtnClick = YES;
            }
            else{
                [self sendMessage:@"G1 X0 Y0 F5000\r"];
            }
            
        }
    }
}

-(void)move:(NSString *)direction{
    if (!self.checkBox.state) {
        float delay_time = [self.delayTime floatValue];
        float limit = [self.limitDistance floatValue];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (int i = 20; i <= 20*limit; i = i+20) {
                //send message
                [self sendMessage:[NSString stringWithFormat:@"G1 %@%d F5000\n",direction,i]];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.limitDistance.stringValue = [NSString stringWithFormat:@"%d/%.1f",i/20,limit];
                    //collection data
                }];
                [NSThread sleepForTimeInterval:delay_time];
            }
        });
    }
    else{
        if ([direction rangeOfString:@"Z"].location != NSNotFound) {
            [self sendMessage:[NSString stringWithFormat:@"G1 %@%.2f F5000\n",direction,[self.limitDistance floatValue]/2]];
        }
        else
            [self sendMessage:[NSString stringWithFormat:@"G1 %@%f F5000\n",direction,[self.limitDistance floatValue]*20]];
    }
}
- (IBAction)absoulteOrRelativeAddressBtn:(NSButton *)sender {
    
    self.absoulteBtn.state = !self.relativeBtn.state;
    if (self.tempLimit) {
        self.limitDistance.floatValue = self.tempLimit;
    }
    if (self.absoulteBtn.state == YES) {
        self.checkBox.enabled = YES;
        //self.HomeBtn.enabled = YES;
        [self sendMessage:@"G90\r"];
    }
    else{
        self.checkBox.state = YES;
        self.checkBox.enabled = NO;
        //self.HomeBtn.enabled = NO;
        [self sendMessage:@"G91\r"];
    }
}

- (IBAction)checkStateBtn:(NSButton *)sender {
    self.delayTime.enabled = !sender.state;
    if (sender.state) {
        if (self.tempLimit) {
            self.limitDistance.floatValue = self.tempLimit;
        }
    }
}

//send Message
- (void)sendMessage:(NSString*)message{
    NSLog(@"send:%@",message);
    [self.receivedDataTextView.textStorage.mutableString appendString:[NSString stringWithFormat:@"send:%@\n",message]];
    //NSString to NSData
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.serialPort sendData:data];
    //check currently position
    [self.serialPort sendData:[@"M114\r" dataUsingEncoding:NSUTF8StringEncoding]];
    [self.receivedDataTextView.textStorage.mutableString appendString:@"send:M114\r\n"];
}

#pragma mark ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    self.openCloseButton.title = @"Close";
    [self buttonState:YES];
    if (self.absoulteBtn.state) {
        [self sendMessage:@"G90\r"];
    }else{
        [self sendMessage:@"G91\r"];
    }
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.openCloseButton.title = @"Open";
    [self buttonState:NO];
}

- (void)buttonState:(BOOL)state{
    self.serialBoudRatePop.enabled = self.serialPortsPop.enabled = !state;
    self.serialRefreshButton.enabled = state;
    self.HomeBtn.enabled = self.XPlusBtn.enabled = self.YPlusBtn.enabled = self.XMinusBtn.enabled = self.YMinusBtn.enabled = self.ZPlusBtn.enabled = self.ZMinusBtn.enabled = state;
    self.absoulteBtn.enabled = self.relativeBtn.enabled = state;
    self.serialRefreshButton.enabled = !state;
    self.sendText.enabled = state;
    if (state == 0) {
        self.endStrPop.enabled = state;
        self.sendMessageBtn.enabled = state;
    }
}

///receive data
- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string length] == 0) return;
    NSLog(@"receive:%@",string);
    [self.receivedDataTextView.textStorage.mutableString appendString:string];
    [self.receivedDataTextView scrollRangeToVisible:NSMakeRange([[self.receivedDataTextView string] length], 0)];
    [self.receivedDataTextView setNeedsDisplay:YES];
    
    if (self.isRelativeHomeBtnClick) {
        NSLog(@"RelativeHomeBtnClick");
        NSString *position = string;
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"%@",position);
        });
        self.isRelativeHomeBtnClick = NO;
    }
}

- (void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort {
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.openCloseButton.title = @"Open";
    [self.openCloseButton setState:NSControlStateValueOff];
}
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}


#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}


#pragma mark - lazy functions
- (ORSSerialPort *)serialPort{
    if (!_serialPort) {
        _serialPort = [ORSSerialPort serialPortWithPath:[NSString stringWithFormat:@"/dev/cu.%@",[self.serialPortsPop selectedItem].title]];
        _serialPort.baudRate = @([[self.serialBoudRatePop selectedItem].title intValue]);
        _serialPort.delegate = self;
    }
    return _serialPort;
}

- (ORSSerialPortManager *)serialPortManager{
    if (!_serialPortManager) {
        _serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    }
    return _serialPortManager;
}
@end
