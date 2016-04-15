//
//  ScanViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/10.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import "ScanViewController.h"
#import "ARViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "../JFMinimalNotification/JFMinimalNotification.h"

@interface ScanViewController () <JFMinimalNotificationDelegate,UITextFieldDelegate,  AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;
@property (nonatomic, strong) JFMinimalNotification* minimalNotification;

@end

@implementation ScanViewController {
    
    
    NSString* noPatientFoundMessageTitle;
    NSString* noPatientFoundMessangeSubTitle;
    NSString* patientFoundMessageTitle;
    NSString* patientFoundMessangeSubTitle;
    NSString* scanQRCodeMessageTitle;
    NSString* scanQRCodeMessageSubTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self.view bringSubviewToFront:_messageLabel];
    [self.captureSession startRunning];
    
    noPatientFoundMessageTitle = @"Warning";
    patientFoundMessageTitle =@"Patient Found";
    scanQRCodeMessageTitle = @"QRCode Scanning";
    scanQRCodeMessageSubTitle = @"Please locate the patient's QRCode in visible region";
    
    // Need to be updated.
    noPatientFoundMessangeSubTitle = @"The patient is not found";
    patientFoundMessangeSubTitle = @"ID:";
    // Setup the fancy on notification center.
    self.titleLabelTextField.text = scanQRCodeMessageTitle;
    self.subTitleLabelTextField.text = scanQRCodeMessageSubTitle;
    
    
    self.titleLabelTextField.text = @"Testing";
    self.subTitleLabelTextField.text = @"This is my awesome sub-title";
    
    /**
     * Create the notification
     */
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleCustom title:self.titleLabelTextField.text subTitle:self.subTitleLabelTextField.text dismissalDelay:0.0 touchHandler:^{
        [self.minimalNotification dismiss];
    }];
    
    self.minimalNotification.edgePadding = UIEdgeInsetsMake(0, 0, 10, 0);
    
    [self.view addSubview:self.minimalNotification];
    
    self.minimalNotification.backgroundColor = [UIColor purpleColor];
    
    self.minimalNotification.titleLabel.textColor = [UIColor whiteColor];
    self.minimalNotification.subTitleLabel.textColor = [UIColor whiteColor];
    
    /**
     * Set the delegate
     */
    self.minimalNotification.delegate = self;
    
    /**
     * Set the desired font for the title and sub-title labels
     * Default is System Normal
     */
    UIFont* titleFont = [UIFont systemFontOfSize:22.0];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont systemFontOfSize:16.0];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    
    /**
     * Uncomment the following line to present notifications from the top of the screen.
     */
     self.minimalNotification.presentFromTop = YES;

    
}
- (void)showToastWithMessage:(NSString *)message {
    if (self.minimalNotification) {
        [self.minimalNotification dismiss];
        [self.minimalNotification removeFromSuperview];
        self.minimalNotification = nil;
    }
    
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleError
                                                                      title:NSLocalizedString(@"Refresh Error", @"Refresh Error")
                                                                   subTitle:message
                                                             dismissalDelay:10.0];
    
    /**
     * Set the desired font for the title and sub-title labels
     * Default is System Normal
     */
    UIFont* titleFont = [UIFont systemFontOfSize:22.0];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont systemFontOfSize:16.0];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    
    /**
     * Add the notification to a view
     */
    [self.view addSubview:self.minimalNotification];
    
    // show
    [self performSelector:@selector(showNotification) withObject:nil afterDelay:0.1];
}

- (void)showNotification {
    [self.minimalNotification show];
}

-(void)viewWillAppear:(BOOL)animated{
    [self showNotification];
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
- (NSMutableArray *)codeObjects
{
    if (!_codeObjects)
    {
        _codeObjects = [NSMutableArray new];
    }
    return _codeObjects;
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession)
    {
        NSLog(@"start");
        NSError *error = nil;
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (device.isAutoFocusRangeRestrictionSupported)
        {
            if ([device lockForConfiguration:&error])
            {
                [device setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
                [device unlockForConfiguration];
            }
        }
        
        // The first time AVCaptureDeviceInput creation will present a dialog to the user
        // requesting camera access. If the user refuses the creation fails.
        // See WWDC 2013 session #610 for details, but note this behaviour does not seem to
        // be enforced on iOS 7 where as it is with iOS 8.
        
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (deviceInput)
        {
            _captureSession = [[AVCaptureSession alloc] init];
            if ([_captureSession canAddInput:deviceInput])
            {
                [_captureSession addInput:deviceInput];
            }
            
            AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
            if ([_captureSession canAddOutput:metadataOutput])
            {
                [_captureSession addOutput:metadataOutput];
                [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
                [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            }
            
            self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            self.targetLayer = [_scanFrame layer];
            [self.targetLayer setMasksToBounds:YES];
            
            CGRect frame = [self.scanFrame bounds];
            frame.size = CGSizeMake(300, 300);
            NSLog(@"Frame for Scan frame \n origin (%f,%f) size (%f, %f)",frame.origin.x, frame.origin.y, frame.size.height,frame.size
                  .width);
            
            
            [_previewLayer setFrame:frame];
            
            [self.targetLayer insertSublayer:_previewLayer atIndex:0];
            [self.targetLayer setContentsCenter: [[self.scanFrame superview] bounds]];
            [self.targetLayer layoutSublayers];
            
        }
        else
        {
            NSLog(@"Input Device error: %@",[error localizedDescription]);
        }
    }
    return _captureSession;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    if (metadataObjects == nil || metadataObjects.count == 0){
        /*
         qrCodeFrameView?.frame = CGRectZero
         */
        self.messageLabel.text = @"No QR code is detected";
        [self showNotification];
        return;
    }

    AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
    if (metadataObj.stringValue != nil){
        
        self.messageLabel.text = metadataObj.stringValue;
//        [self patientFoundMessage:metadataObj.stringValue patientFound:YES];
        [self showNotification];
        // [self performSegueWithIdentifier:@"showModel" sender:self];
    }

    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self.captureSession stopRunning];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self.captureSession startRunning];
}

- (void)dealloc
{
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"showModel"]){
        ARViewController *controller = (ARViewController *)segue.destinationViewController;
        [controller loadPatient:self.messageLabel.text];
        
        controller.modelName = self.messageLabel.text;
    }
}


- (void)patientFoundMessage: (NSString*) patientID patientFound: (BOOL) flag {
    if (flag) {
        patientFoundMessangeSubTitle = [@"ID: " stringByAppendingString:patientID];
        
        self.titleLabelTextField.text = patientFoundMessageTitle;
        self.subTitleLabelTextField.text = patientFoundMessangeSubTitle;
        [self.minimalNotification setStyle:JFMinimalNotificationStyleSuccess animated:YES];
        
        // [_miniNotification setTitle: patientFoundMessageTitle];
        
    }
}

#pragma mark ----------------------
#pragma mark UITextFieldDelegate
#pragma mark ----------------------

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    JFMinimalNotificationStyle style = self.minimalNotification.currentStyle;
    [self.minimalNotification removeFromSuperview];
    self.minimalNotification = nil;
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:style title:self.titleLabelTextField.text subTitle:self.subTitleLabelTextField.text dismissalDelay:0.0f touchHandler:^{
        [self.minimalNotification dismiss];
    }];
    self.minimalNotification.delegate = self;
    UIFont* titleFont = [UIFont fontWithName:@"STHeitiK-Light" size:22];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont fontWithName:@"STHeitiK-Light" size:16];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    [self.view addSubview:self.minimalNotification];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.minimalNotification show];
    });
    
    return YES;
}

#pragma mark ----------------------
#pragma mark JFMinimalNotificationDelegate
#pragma mark ----------------------

- (void)minimalNotificationWillShowNotification:(JFMinimalNotification*)notification {
    NSLog(@"willShowNotification");
}

- (void)minimalNotificationDidShowNotification:(JFMinimalNotification*)notification {
    NSLog(@"didShowNotification");
}

- (void)minimalNotificationWillDisimissNotification:(JFMinimalNotification*)notification {
    NSLog(@"willDisimissNotification");
}

- (void)minimalNotificationDidDismissNotification:(JFMinimalNotification*)notification {
    NSLog(@"didDismissNotification");
}

@end
