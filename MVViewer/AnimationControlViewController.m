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
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (nonatomic)         int      current;
@end

@implementation AnimationControlViewController {
    ARViewController* arController; // Hold
    VEObjectOBJMovie* movieObject;
    
    
    NSArray*        timeStampArray;
    
    
}





- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calibrate the GUI
    [_arViewContainerView setHidden:FALSE];
    [[self view] bringSubviewToFront:_navigationBar];
    
    
    [_slider setContinuous:FALSE];
    
    
    VEObjectOBJMovie* object = [_virtualEnvironment findPatientObject:_patientInfo];
    timeStampArray = object.timeStampArray;
    movieObject = object;
    [movieObject setMoviePaused:TRUE];
    
    float min =  [((NSNumber*) [timeStampArray firstObject]) floatValue];
    float max = [((NSNumber*) [timeStampArray lastObject]) floatValue];
    _current = (int) min;
    [_slider setMinimumValue: (float) min];
    [_slider setMaximumValue: (float) max];
    [_slider setValue: _current animated:FALSE];
    
   
    
    
//    _textSlide.title = [NSString stringWithFormat:@"%d", (int) slider.value];
    
    
    // [self addObserver:self forKeyPath:@"_current" options:NSKeyValueObservingOptionPrior context: NULL];
    [movieObject addObserver:self forKeyPath:@"current" options:NSKeyValueObservingOptionNew context:NULL];
    
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
        [self togglePlay];
    }
}
- (IBAction)slideBarValue:(UISlider *)sender {
    _current = (int) sender.value;
    _textSlide.title = [NSString stringWithFormat:@"%d",_current];
    
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
        arController.virtualEnvironment = _virtualEnvironment;
        arController.patientInfo = _patientInfo;
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
    
    [movieObject setMoviePaused: movieObject.paused ? FALSE : TRUE];
    [self setPlayPauseButton: movieObject.paused];
    
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
        
        _current = [((VEObjectOBJMovie*) object).current intValue];
        [_slider setValue:(float) _current animated:TRUE];
        _textSlide.title = [NSString stringWithFormat:@"%d", _current];
        [_slider setNeedsDisplay];
        [_controlBar setNeedsDisplay];
        
        NSLog(@"KVO observe current changed to %d", _current);
        
    }
}


- (void) dealloc
{
    [movieObject removeObserver:self forKeyPath:@"current"];
}

@end
