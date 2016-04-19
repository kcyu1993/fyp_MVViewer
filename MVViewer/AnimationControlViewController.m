//
//  AnimationControlViewController.m
//  MVViewer_FYP_15011
//
//  Created by Jack Yu on 18/4/2016.
//
//
#import "ARViewController.h"
#import "ARAppCore/VEObjectOBJMovie.h"
#import "AnimationControlViewController.h"

@interface AnimationControlViewController ()
@property (strong, nonatomic) IBOutlet UIView *arViewContainerView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic)         int      current;
@end

@implementation AnimationControlViewController {
    ARViewController* arController; // Hold
    VEObjectOBJMovie* movieObject;
    
    
    NSArray*        timeStampArray;
    UISlider*       slider;
    
    NSTimer*        movieLoopingTimer;
    NSInvocation*   movieLoopInvocation;
    float           fps;
    
    
}





- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calibrate the GUI
    [_arViewContainerView setHidden:FALSE];
    [[self view] bringSubviewToFront:_navigationBar];
    
    
    slider = (UISlider*) [_slideBar target];
    
    [slider setContinuous:FALSE];
    
    
    VEObjectOBJMovie* object = [_virtualEnvironment findPatientObject:_patientInfo];
    timeStampArray = object.timeStampArray;
    movieObject = object;
    _current = (int) timeStampArray.firstObject;
    
    [slider setMinimumValue: (float) (NSUInteger) timeStampArray.firstObject];
    [slider setMaximumValue: (float) (NSUInteger) timeStampArray.lastObject];
    [slider setValue:(float) (NSUInteger) timeStampArray.firstObject animated:FALSE];
    _textSlide.title = [NSString stringWithFormat:@"%d", (int) slider.value];
    
    
    // [self addObserver:self forKeyPath:@"_current" options:NSKeyValueObservingOptionPrior context: NULL];
   // [object addObserver:self forKeyPath:@"current" options:NSKeyValueObservingOptionNew context:NULL];
    
    
}

- (void)didReceiveMemoryWarning {
    
}

#pragma mark Touch Event Handler

- (IBAction)singleTapHandle:(UITapGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateEnded) {
        NSLog(@"Single tap!");
        [self toggleControl];
    }
}

- (IBAction)doubleTapHandle:(UITapGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateEnded) {
        NSLog(@"Double tap!");
        
    }
}

- (void) performSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([[sender identifier] isEqualToString:@"loadARViewSegue"]) {
        NSLog(@"Look here!");
        arController = (ARViewController*) self.childViewControllers.lastObject;
        arController.virtualEnvironment = _virtualEnvironment;
        arController.patientInfo = _patientInfo;
    
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"loadARViewSegue"]) {
        arController = (ARViewController *) segue.destinationViewController;
        
    }
}


#pragma mark Executor for UI Event

- (void) toggleControl
{
    [self.navigationBar setHidden: [self.navigationBar isHidden]? FALSE : TRUE ];
    [self.controlBar setHidden: [self.controlBar isHidden]? FALSE : YES];
}

- (void) togglePlay
{
    if ([arController isPaused]) {
        
        [_controlBar setNeedsDisplay];
        //[arController start];
        
    }
    else{
        [arController stop];
    }
    
    [self setPlayPauseButton: ! [arController isPaused]];
    
}

- (void) setPlayPauseButton:(BOOL)isPlaying
{
    // we need to change which of play/pause buttons are showing, if the one to
    // reverse current action isn't showing
    if ((isPlaying && !self.pauseButton) || (!isPlaying && !self.playButton))
    {
        UIBarButtonItem *buttonToRemove = nil;
        UIBarButtonItem *buttonToAdd = nil;
        if (isPlaying)
        {
            buttonToRemove = self.playButton;
            self.playButton = nil;
            self.pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                             target:self
                                                                             action:@selector(togglePlay)];
            buttonToAdd = self.pauseButton;
        }
        else
        {
            buttonToRemove = self.pauseButton;
            self.pauseButton = nil;
            self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                            target:self
                                                                            action:@selector(togglePlay)];
            buttonToAdd = self.playButton;
        }
        
        // Get the reference to the current toolbar buttons
        NSMutableArray *toolbarButtons = [[self.controlBar items] mutableCopy];
        
        // Remove a button from the toolbar and add the other one
        if (buttonToRemove)
            [toolbarButtons removeObject:buttonToRemove];
        if (![toolbarButtons containsObject:buttonToAdd])
            [toolbarButtons insertObject:buttonToAdd atIndex:2];    // vary this index to put in diff spots in toolbar
        
        [self.controlBar setItems:toolbarButtons];
    }
}


-(void) nextTimeStamp
{
    NSUInteger index = [timeStampArray indexOfObject:[NSNumber numberWithInt: _current]];
    index++;
    if (index == [timeStampArray count]) {
        index = 0;
    }
    
    _current = [[timeStampArray objectAtIndex:index] intValue];
}

- (void) updateTimeStamp
{
    NSLog(@"Update time stamp");
}

#pragma mark Status bar

- (BOOL) prefersStatusBarHidden
{
    return YES;
}


- (UIStatusBarAnimation) preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}


#pragma mark KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"current"]) {
        // Update all time point display accordingly.
        
        _current = ((VEObjectOBJMovie*) object).currentTimeStamp;
        [slider setValue:(float) _current animated:TRUE];
        _textSlide.title = [NSString stringWithFormat:@"%d", _current];
        [slider setNeedsDisplay];
        [_controlBar setNeedsDisplay];
        
        NSLog(@"KVO observe current changed to %d", _current);
        
    }
}

@end
