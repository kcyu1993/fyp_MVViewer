//
//  ScanViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/10.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import "../ModelHandler.h"
#import "ScanViewController.h"
#import "ARViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CRToast/CRToast.h>

#define hsb(_H, _S, _B) [UIColor colorWithHue:_H/360.0f saturation:_S/100.0f brightness:_B/100.0f alpha:1.0]

@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;
@property (nonatomic, strong) UIImage *success;
@property (nonatomic, strong) UIImage *failure;
@property (nonatomic, strong) VirtualEnvironment* virtualEnvironment;
@property (nonatomic, strong) ModelHandler* modelHandler;



@end

@implementation ScanViewController {
    
    UIColor*    green;
    UIColor*    red;
    UIColor*    blue;
    NSString* noPatientFoundMessageTitle;
    NSString* noPatientFoundMessangeSubTitle;
    NSString* patientFoundMessageTitle;
    NSString* patientFoundMessangeSubTitle;
    NSString* scanQRCodeMessageTitle;
    NSString* scanQRCodeMessageSubTitle;
    
    NSString* lastCheckQRCodeString;
    
    
    NSString* correctPatientID;
    
    NSProgress* loadingProgress;
    
    //NSTimer* notificationToolBarTimer;
    BOOL patientFound;
}
- (IBAction)confirmAction:(UIBarButtonItem *)sender {
    
    
    
    NSArray* baseFiles = [_modelHandler getPatientBaseModelPaths: correctPatientID];
    NSArray* valveFiles = [_modelHandler getPatientValveModelPaths:correctPatientID];
    
    loadingProgress = [NSProgress progressWithTotalUnitCount:baseFiles.count + valveFiles.count];
    
    [_progressView setHidden:FALSE];
    [_progressBar setObservedProgress:loadingProgress];
    [[NSNotificationCenter defaultCenter] addObserver:loadingProgress selector:@selector(updateProgressBarLabel) name:@"progressBarLabel" object:nil];
    
    [self.virtualEnvironment addOBJMovieObjectsForPatient:correctPatientID baseFiles:baseFiles valveFiles:valveFiles connectToARMarker:nil config: [self getFullPath: @"Data/param.dat"] progress: nil];
    
}

- (void) updateProgressBarLabel
{
    _progressBarLabel.text = [NSString stringWithFormat:@"Loading %lld / %lld", [loadingProgress completedUnitCount],[loadingProgress totalUnitCount]];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // [self.view bringSubviewToFront:_messageLabel];
    [self.captureSession startRunning];
    
    patientFound = false;
    
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
    
    self.success = [UIImage imageNamed:@"white_checkmark.png"];
    self.failure = [UIImage imageNamed:@"alert_icon.png"];
    
    // Make color
    green = hsb(145, 77, 80);
    red = hsb(6, 74, 91);
    blue = hsb(224,50,63);

    // Initialize model handler
    _modelHandler = [[ModelHandler alloc] init];
    [self loadPatientList];
    // Initialize virtual environment
    self.virtualEnvironment = [[VirtualEnvironment alloc] initWithScanViewController:self];
    
    
    // Refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadPatientList)];
    _navigationBar.rightBarButtonItem = refreshButton;
    
    
    // Progress view
    [_progressView setHidden:YES];
    [_bottomBar setHidden:TRUE];
    
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
        
        return;
    }

    AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
    if (!patientFound)
        if (metadataObj.stringValue != nil){
            
            NSString* patientName = self.messageLabel.text = metadataObj.stringValue;
            if ([_modelHandler checkPatientExistence:patientName]) {
                [self patientFoundMessage:metadataObj.stringValue patientFound:YES];
                [_bottomBar setHidden:NO];
                patientFound = TRUE;
                correctPatientID = patientName;
            }
            else{
                [self patientFoundMessage:metadataObj.stringValue patientFound:NO];
                
                
            }
            
            
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
        NSLog(@"Found message %@ ",patientID);
        patientFoundMessangeSubTitle = [@"ID: " stringByAppendingString:patientID];
        [CRToastManager cancelPreviousPerformRequestsWithTarget:self];
        [self makeAndShowMessageWithOptionsSpecs:patientFoundMessageTitle subtitle:patientFoundMessangeSubTitle color:green activityBar:NO showImage:_success];
        
    }
    else{
        [CRToastManager cancelPreviousPerformRequestsWithTarget:self];
        noPatientFoundMessangeSubTitle = [NSString stringWithFormat:@"Patinet with ID %@ is not found!",patientID];
        [self makeAndShowMessageWithOptionsSpecs:noPatientFoundMessageTitle subtitle:noPatientFoundMessangeSubTitle color:red activityBar:NO showImage:_failure];
    }
}

- (void) makeAndShowMessageWithOptionsSpecs: (NSString*) title subtitle:(NSString*) subtitle color: (UIColor*) color
                           activityBar: (BOOL) activityBar showImage: (UIImage*) image
{
    float padding = 1.0f;
    
    NSMutableDictionary* options
                 = [@{kCRToastNotificationTypeKey: @(CRToastTypeNavigationBar),
                      kCRToastNotificationPresentationTypeKey   : @(CRToastPresentationTypeCover),
                      kCRToastUnderStatusBarKey                 : @(YES),
                      kCRToastTextKey                           :title,
                      kCRToastSubtitleTextKey                   : subtitle,
                      kCRToastTextAlignmentKey                  : @(NSTextAlignmentLeft),
                      kCRToastSubtitleTextAlignmentKey          : @(NSTextAlignmentLeft),
                      kCRToastTimeIntervalKey                   : @5.0f,
                      kCRToastAnimationInTypeKey                : @(CRToastAnimationTypeSpring),
                      kCRToastAnimationOutTypeKey               : @(CRToastAnimationTypeSpring),
                      kCRToastAnimationInDirectionKey           : @(1),
                      kCRToastAnimationOutDirectionKey          : @(3),
                      kCRToastNotificationPreferredPaddingKey   : @(padding),
                      kCRToastShowActivityIndicatorKey          : @(activityBar),
                      kCRToastActivityIndicatorAlignmentKey     :@(NSTextAlignmentLeft),
                      kCRToastBackgroundColorKey: color}
                    mutableCopy];
    [CRToastManager showNotificationWithOptions:options
                                 apperanceBlock:^(void) {
                                     NSLog(@"Appeared");
                                 }
                                completionBlock:^(void) {
                                    NSLog(@"Completed");
                                }];
}


- (NSString*) getFullPath: (NSString*) path
{
    return [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:path];
}


- (void) loadPatientList
{
    NSUInteger size1 = [_modelHandler readPatientFoldersWithRootFolder:[self getFullPath:@"Data/mvmodels"]];
    NSString* publicDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSUInteger size2 = [_modelHandler readPatientFoldersWithRootFolder:publicDocumentsDir];
    NSLog(@"Load model from location 1 %d and location 2 %d", (int) size1, (int) size2);
}

@end
