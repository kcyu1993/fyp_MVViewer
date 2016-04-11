//
//  ScanViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/10.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view bringSubviewToFront:_messageLabel];
    [self.captureSession startRunning];
}
-(void)viewWillAppear:(BOOL)animated{

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
            
            self.targetLayer = [[self view] layer];
            [self.targetLayer setMasksToBounds:YES];
            
            CGRect frame = self.scanFrame.frame;
            [_previewLayer setFrame:frame];
            [self.targetLayer insertSublayer:_previewLayer atIndex:0];
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
        return;
    }

    AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
    if (metadataObj.stringValue != nil){
        self.messageLabel.text = metadataObj.stringValue;
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
@end
