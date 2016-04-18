//
//  ScanViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/10.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//
//  Author:
//      Helen Zheng for QRCode reading
//      Jack Yu     for
//          Notification bar, auto-layout and UI settings,
//          model creation and handling, progress view (bar and label)
//          and all other misc issue.


#import "../ModelHandler.h"
#import "VEObjectOBJMovie.h"
#import "ScanViewController.h"
// #import "ARViewController.h"
#import "AnimationControlViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CRToast/CRToast.h>

#define hsb(_H, _S, _B) [UIColor colorWithHue:_H/360.0f saturation:_S/100.0f brightness:_B/100.0f alpha:1.0]

@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate,VEObjectOBJMovieLoadingIncrementProgressBarDelegate>
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;
@property (nonatomic, strong) UIImage *success;
@property (nonatomic, strong) UIImage *failure;
@property (nonatomic, strong) VirtualEnvironment* virtualEnvironment;
@property (nonatomic, strong) ModelHandler* modelHandler;


@property (strong, nonatomic) IBOutlet UIImageView *hkuLogo;


@end

@implementation ScanViewController {
    
    // Constant tags
    NSString*   modelLoadingStartString;
    
    UIColor*    green;
    UIColor*    red;
    UIColor*    blue;
    NSString*   noPatientFoundMessageTitle;
    NSString*   noPatientFoundMessangeSubTitle;
    NSString*   patientFoundMessageTitle;
    NSString*   patientFoundMessangeSubTitle;
    NSString*   scanQRCodeMessageTitle;
    NSString*   scanQRCodeMessageSubTitle;
    
    // For notification purpose
    NSString*   lastCheckQRCodeString;
    
    
    
    
    NSString*   correctPatientID;
    
    NSProgress* loadingProgress;
    
    NSTimer* notificationToolBarTimer;
    NSArray*    patientList;
    BOOL        patientFound;
}

#pragma mark UI Life cycle related

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // [self.view bringSubviewToFront:_messageLabel];
    [self startCaptureSession];
    
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
    
    modelLoadingStartString = @"Model loading started";
    
    self.success = [UIImage imageNamed:@"white_checkmark"];
    self.failure = [UIImage imageNamed:@"alert_icon"];
    
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
    [_startAnimation setHidden:TRUE];
    [_hkuLogo setHidden:TRUE];
    
    [_startAnimation setHidden:FALSE];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self stopCaptureSession];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self startCaptureSession];
}

- (void)dealloc
{
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
                [CRToastManager dismissAllNotifications:TRUE];
                [self patientFoundMessage:metadataObj.stringValue patientFound:YES];
                [_bottomBar setHidden:NO];
                patientFound = TRUE;
                correctPatientID = patientName;
                [self stopCaptureSession];
                
            }
            else{
                if (![lastCheckQRCodeString isEqualToString:patientName]) {
                    [self patientFoundMessage:metadataObj.stringValue patientFound:NO];
                    notificationToolBarTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f invocation:[NSInvocation invocationWithMethodSignature: [self methodSignatureForSelector:@selector(resetLastLoadedQRCode)]] repeats:NO];
                }
                
            }
            lastCheckQRCodeString = patientName;
            
        }

    
}

- (void) stopCaptureSession
{
    [self.captureSession stopRunning];
    [_previewLayer setHidden:TRUE];
    [_hkuLogo setHidden:FALSE];
    
}

- (void) startCaptureSession
{
    [self.captureSession startRunning];
    [_previewLayer setHidden:FALSE];
    [_bottomBar setHidden:TRUE];
    [_hkuLogo setHidden:TRUE];
}

#pragma mark IBAction

- (IBAction)confirmAction:(UIBarButtonItem *)sender {
    
    NSArray* baseFiles = [_modelHandler getPatientBaseModelPaths: correctPatientID];
    NSArray* valveFiles = [_modelHandler getPatientValveModelPaths:correctPatientID];
    NSUInteger count = baseFiles.count + valveFiles.count;
    
    [_progressView setHidden:FALSE];
    
    loadingProgress = [NSProgress progressWithTotalUnitCount:baseFiles.count + valveFiles.count];
    [_progressBar setProgress:0.0f animated:NO];
    
    [self performSelectorInBackground:@selector(loadCurrentPatientModel) withObject:nil];
    [self makeAndShowMessageWithOptionsSpecs:modelLoadingStartString subtitle:[NSString stringWithFormat: @"Total count of model: %lu", count] color:blue activityBar:YES showImage:nil];
    [_bottomBar setHidden:TRUE];
    [_bottomBar setNeedsDisplay];
}

- (IBAction)cancelButtonAction:(UIBarButtonItem *)sender {
    
    [self startCaptureSession];
    patientFound = FALSE;
    [self makeAndShowMessageWithOptionsSpecs:@"Please scan patient's QR Code" subtitle:@"" color:blue activityBar:NO showImage:nil];
}

// Refresh button action list
- (void) loadPatientList
{
    NSUInteger size1 = [_modelHandler readPatientFoldersWithRootFolder:[self getFullPath:@"Data/mvmodels"]];
    NSString* publicDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSUInteger size2 = [_modelHandler readPatientFoldersWithRootFolder:publicDocumentsDir];
    
    // Calling the first time.
    if (!patientList) {
        [self makeAndShowMessageWithOptionsSpecs:@"Patient list loaded successfully"
                                        subtitle: [ NSString stringWithFormat:@"%lu from internal and %lu from iTunes", size1, size2]
                                           color:green activityBar:NO showImage:_success];
        patientList = [_modelHandler getPatientFullList];
        return;
    }
    
    if (patientList && ![patientList isEqualToArray:[_modelHandler getPatientFullList]]) {
        patientList = [_modelHandler getPatientFullList];
        [self makeAndShowMessageWithOptionsSpecs:@"Patient list has changes, updated successfully"
                                        subtitle: [ NSString stringWithFormat:@"%lu from internal and %lu from iTunes", size1, size2]
                                           color:blue activityBar:NO showImage:_failure];
    }
    else {
        [self makeAndShowMessageWithOptionsSpecs:@"Patient list up to date"
                                        subtitle: [ NSString stringWithFormat:@"%lu from internal and %lu from iTunes", size1, size2]
                                           color:blue activityBar:NO showImage:_success];
    }
    
    NSLog(@"Load model from location 1 %d and location 2 %d", (int) size1, (int) size2);
    
}

- (IBAction)startAnimationAction:(UIButton *)sender {
    [self performSegueWithIdentifier:@"showModel" sender:sender];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"showModel"]){
        
        AnimationControlViewController *controller = (AnimationControlViewController *)segue.destinationViewController;
        controller.patientInfo = correctPatientID;
        controller.virtualEnvironment = _virtualEnvironment;
    }
}


#pragma mark Progress Updating

- (void) updateProgressBarWithProgress: (NSProgress *) progress
{
    [_progressBar setProgress: [loadingProgress fractionCompleted] animated:YES];
    [_progressBar setNeedsDisplay];
    [self updateProgressBarLabel];
    [_progressBarLabel setNeedsDisplay];
}


- (void) workDone
{
    NSLog(@"Loading done");
    _progressBarLabel.text = @"Loading done!";
    
    [CRToastManager dismissAllNotifications:TRUE];
    [self makeAndShowMessageWithOptionsSpecs:@"Model load finished" subtitle:@"" color:blue activityBar:NO showImage:_success];

    [_startAnimation setHidden:FALSE];
    
}

- (void) updateProgressBarLabel
{
    _progressBarLabel.text = [NSString stringWithFormat:@"Loading %lld / %lld", [loadingProgress completedUnitCount],[loadingProgress totalUnitCount]];
    
}

- (void) resetLastLoadedQRCode
{
    lastCheckQRCodeString = @"";
}

#pragma mark Model Loading

- (void) loadCurrentPatientModel
{
    NSArray* baseFiles = [_modelHandler getPatientBaseModelPaths: correctPatientID];
    NSArray* valveFiles = [_modelHandler getPatientValveModelPaths:correctPatientID];
    
    //loadingProgress = [NSProgress progressWithTotalUnitCount:baseFiles.count + valveFiles.count];
    
    //[_progressBar setObservedProgress:loadingProgress];
    // [[NSNotificationCenter defaultCenter] addObserver:loadingProgress selector:@selector(updateProgressBarLabel) name:@"progressBarLabel" object:nil];
    
    //    [self.virtualEnvironment addOBJMovieObjectsForPatient:correctPatientID baseFiles:baseFiles valveFiles:valveFiles connectToARMarker:nil config: [self getFullPath: @"Data/param.dat"]];
    VEObjectOBJMovie* tempObject = [[VEObjectOBJMovie alloc] initFromSettings:nil rotation:nil scale:nil];
    tempObject.delegate = self;
    [self.virtualEnvironment loadObjectMovieObjectForPatient:tempObject patientName:correctPatientID baseFiles:baseFiles valveFiles:valveFiles connectToARMarker:nil config: [self getFullPath: @"Data/param.dat"]];
    [self performSelectorOnMainThread:@selector(workDone) withObject:nil waitUntilDone:NO];
}


#pragma mark Notification

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
                      kCRToastBackgroundColorKey                : color,
                      kCRToastForceUserInteractionKey : @YES}
                    mutableCopy];
    
    if (image) {
        options[kCRToastImageKey] = image;
        options[kCRToastImageAlignmentKey] = @((NSTextAlignmentLeft));
    }
    options[kCRToastInteractionRespondersKey] = @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeTap
                                                                                                  automaticallyDismiss:YES
                                                                                                                 block:^(CRToastInteractionType interactionType){
                                                                                                                     NSLog(@"Dismissed with %@ interaction", NSStringFromCRToastInteractionType(interactionType));
                                                                                                                 }]];
    if ([title isEqualToString:modelLoadingStartString]) {
        options[kCRToastTimeIntervalKey] = @100.0f;
        
    }
    
    
    [CRToastManager showNotificationWithOptions:options
                                 apperanceBlock:^(void) {
                                     NSLog(@"Appeared");
                                 }
                                completionBlock:^(void) {
                                    NSLog(@"Completed");
                                }];
}


- (void)patientFoundMessage: (NSString*) patientID patientFound: (BOOL) flag {
    if (flag) {
        NSLog(@"Found message %@ ",patientID);
        patientFoundMessangeSubTitle = [@"ID: " stringByAppendingString:patientID];
        
        
        [self makeAndShowMessageWithOptionsSpecs:patientFoundMessageTitle subtitle:patientFoundMessangeSubTitle color:green activityBar:NO showImage:_success];
        
        
        
    }
    else{
        
        noPatientFoundMessangeSubTitle = [NSString stringWithFormat:@"Patinet with ID %@ is not found!",patientID];
        [self makeAndShowMessageWithOptionsSpecs:noPatientFoundMessageTitle subtitle:noPatientFoundMessangeSubTitle color:red activityBar:NO showImage:_failure];
    }
}

#pragma mark Utilities

- (NSString*) getFullPath: (NSString*) path
{
    return [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:path];
}



#pragma mark VEOBjectMovieDelegate

-(void) incrementProgressBar
{
    NSLog(@"Increment the progress bar");
    [loadingProgress setCompletedUnitCount:[loadingProgress completedUnitCount] + 1];
    [self performSelectorOnMainThread:@selector(updateProgressBarWithProgress:) withObject:loadingProgress waitUntilDone:NO];
}


@end
