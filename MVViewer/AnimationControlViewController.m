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

@interface AnimationControlViewController () <UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UIView *arViewContainerView;
//@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIToolbar *navigationToolBar;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UISlider *fpsSlider;
@property (nonatomic)         int      current;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *minFPS;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *maxFPS;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *patientInfoText;

@end

@implementation AnimationControlViewController {
    ARViewController* arController; // Hold
    VEObjectOBJMovie* movieObject;
    
    
    NSArray*        timeStampArray;
    
    UISwipeGestureRecognizer* swipe;
}





- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calibrate the GUI
    [_arViewContainerView setHidden:FALSE];
    [[self view] bringSubviewToFront:_navigationToolBar];
    
    
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
    
    [_fpsSlider setMaximumValue: (float) 1200];
    [_fpsSlider setMinimumValue:(float) 200];
    
    [_fpsSlider setValue: 600.0f animated:FALSE];
    [_fpsSlider setContinuous: FALSE];
    [_fpsSlider setEnabled:FALSE];
    _maxFPS.title = [NSString stringWithFormat: @"%d", (int) (600)];
    
    [_patientInfoText setTitle: _patientInfo];
    
//    _textSlide.title = [NSString stringWithFormat:@"%d", (int) slider.value];
    
    
    // [self addObserver:self forKeyPath:@"_current" options:NSKeyValueObservingOptionPrior context: NULL];
    [movieObject addObserver:self forKeyPath:@"current" options:NSKeyValueObservingOptionNew context:NULL];
    [movieObject addObserver:self forKeyPath:@"cftp" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self togglePlay];
    [self togglePlay];
    
    
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
- (IBAction)pauseButton:(UIBarButtonItem *)sender {
    [self togglePlay];
}

- (IBAction)slideBarValue:(UISlider *)sender {
    
    [movieObject setTimeStamp:[NSNumber numberWithInt:(int)sender.value]];
    
}

- (IBAction)nextTimeStampButtonAction:(UIBarButtonItem *)sender {
    //[self next];
    [self next];
}

- (IBAction)previousTimeStampButtionAction:(UIBarButtonItem *)sender {
    [self previous];
}


- (IBAction)swipeAction:(UISwipeGestureRecognizer *)sender {
    if (movieObject.paused) {
        if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
            [self next];
        }
        else if ( sender.direction == UISwipeGestureRecognizerDirectionLeft) {
            [self previous];
        }
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
        [self increaseFPS];
    }
    if (sender.direction == UISwipeGestureRecognizerDirectionDown) {
        [self decreaseFPS];

    }
    
}
- (IBAction)playButtonAction:(UIBarButtonItem *)sender {
    [self togglePlay];
}



- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"loadARViewSegue"]) {
        arController = (ARViewController *) segue.destinationViewController;
        arController.virtualEnvironment = _virtualEnvironment;
        arController.patientInfo = _patientInfo;
    }
}

- (IBAction)edgePanGestureBack:(UIScreenEdgePanGestureRecognizer *)sender {
    [self performSegueWithIdentifier:@"backToScan" sender:sender];
}


#pragma mark Executor for UI Event

- (void) toggleControl
{
    [self.navigationToolBar setHidden: [self.navigationToolBar isHidden]? FALSE : TRUE ];
    [self.controlBar setHidden: [self.controlBar isHidden]? FALSE : YES];
}

- (void) togglePlay
{
    
    [movieObject setMoviePaused: movieObject.paused ? FALSE : TRUE];
    [self setControlBarItemWithPaused: movieObject.paused];
    
}

- (void) setControlBarItemWithPaused: (BOOL) paused
{
    if (paused) {
        [_slider setEnabled:TRUE];
        [_nextSlice setEnabled:TRUE];
        [_previousSlice setEnabled:TRUE];
        [_pauseButton setEnabled:FALSE];
        [_playButton setEnabled:TRUE];
    }
    else{
        [_slider setEnabled:FALSE];
        [_nextSlice setEnabled:FALSE];
        [_previousSlice setEnabled:FALSE];
        [_pauseButton setEnabled:TRUE];
        [_playButton setEnabled:FALSE];
    }
    
}

- (void) next
{
    [movieObject nextTimeStamp];
}

- (void) previous
{
    [movieObject previousTimeStamp];
}

- (void) setTimeStamp: (NSNumber *) timeStamp
{
    [movieObject setTimeStamp:timeStamp];
}

- (void) increaseFPS
{
    [movieObject increaseFPS];
}

- (void) decreaseFPS
{
    [movieObject decreaseFPS];
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
    
    if ([keyPath isEqualToString:@"cftp"]) {
        [_fpsSlider setValue: [((VEObjectOBJMovie *) object).cftp intValue] animated:TRUE];
        _maxFPS.title = [NSString stringWithFormat:@"%d", [((VEObjectOBJMovie *) object).cftp intValue]];
    }
}


- (void) dealloc
{
    [movieObject removeObserver:self forKeyPath:@"current"];
    [movieObject removeObserver:self forKeyPath:@"cftp"];
    
    
}

@end
