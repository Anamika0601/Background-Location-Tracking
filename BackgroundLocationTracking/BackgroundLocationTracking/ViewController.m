//
//  ViewController.m
//  BackgroundLocationTracking
//
//  Created by Anamika Sharma on 23/04/17.
//  Copyright © 2017 Anamika Sharma. All rights reserved.
//

#import "ViewController.h"
#import "AppConstants.h"
@import GoogleMaps;

@interface ViewController ()

@end

@implementation ViewController{
    CLLocationManager *locationManager;
    
    __weak IBOutlet UILabel *swipeBtnLabel;
    __weak IBOutlet UIView *swipeBtnView;
    __weak IBOutlet UIButton *swipeBtn;
    
    float startLatitude;
    float startLongitude;
    float stopLatitude;
    float stopLongitude;
    
    __weak IBOutlet UIView *timeTakenView;
    __weak IBOutlet UIView *mapView;
    GMSMapView* googleMap;
    
    __weak IBOutlet UILabel *timeLabel;
    BOOL isNavigating;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    //LOCATION MANAGER
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    
    [locationManager requestAlwaysAuthorization];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager startUpdatingLocation];
    
    googleMap.myLocationEnabled = YES;
    googleMap.settings.myLocationButton = YES;
    
    //UI'S
    timeLabel.text = @"";
    timeLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.textColor = [UIColor blackColor];
    
    timeTakenView.backgroundColor = [UIColor whiteColor];
    timeTakenView.layer.borderWidth = 1;
    timeTakenView.hidden = YES;
    
    
    swipeBtn.backgroundColor = [UIColor whiteColor];
    swipeBtn.layer.cornerRadius = swipeBtn.frame.size.height / 2;
    
    swipeBtnView.layer.cornerRadius = swipeBtnView.frame.size.height / 2;
    
    swipeBtnLabel.text = swipeRightString;
    swipeBtnLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    swipeBtnLabel.textColor =  [UIColor whiteColor];
    
    
    //ADDING GESTURES
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.delaysTouchesBegan = YES;
    leftSwipe.delegate = self;
    [swipeBtn addGestureRecognizer:leftSwipe];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.delaysTouchesBegan = YES;
    rightSwipe.delegate = self;
    [swipeBtn addGestureRecognizer:rightSwipe];
    
    startLatitude = 0.0;
    startLongitude = 0.0;
    
    stopLatitude = 0.0;
    stopLongitude = 0.0;
    
}
-(void)viewWillAppear:(BOOL)animated{
    [locationManager startUpdatingLocation];
}

#pragma mark - Location Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    CLLocation *newLocation = locations.lastObject;
    if (startLatitude == 0 && startLongitude == 0) {
        startLatitude = newLocation.coordinate.latitude;
        startLongitude = newLocation.coordinate.longitude;
    }
    if(isNavigating){
        stopLatitude = newLocation.coordinate.latitude;
        stopLongitude = newLocation.coordinate.longitude;
    }else{
        startLatitude = newLocation.coordinate.latitude;
        startLongitude = newLocation.coordinate.longitude;
        [self updateStartPositionMarker];
        isNavigating = YES;
    }
    [locationManager stopUpdatingLocation];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:startLatitude
                                                            longitude:startLongitude
                                                                 zoom:16];
    googleMap = [GMSMapView mapWithFrame:mapView.bounds camera:camera];
    [mapView addSubview:googleMap];
}

#pragma mark - Swipe Methods

- (IBAction)didSwipeRight:(UISwipeGestureRecognizer *)recognizer
{
    CGRect frame = swipeBtn.frame;
    frame.origin.x = frame.origin.x + 200;
    
    CGRect labelFrame = swipeBtnLabel.frame;
    labelFrame.origin.x = swipeBtnLabel.frame.origin.x - 80;
    [UIView animateWithDuration:0.3 animations:^{
        swipeBtn.frame = frame;
        swipeBtnLabel.frame = labelFrame;
        swipeBtnLabel.text = swipeLeftString;
        swipeBtnView.backgroundColor = swipeLeftColor;
        swipeBtn.imageView.image = [UIImage imageNamed:@"swipe_left.png"];
    }];
    [self startNavigating];
}

- (IBAction)didSwipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    CGRect frame = swipeBtn.frame;
    frame.origin.x = frame.origin.x - 200;
    CGRect labelFrame = swipeBtnLabel.frame;
    labelFrame.origin.x = swipeBtnLabel.frame.origin.x + 80;
    
    [UIView animateWithDuration:0.3 animations:^{
        swipeBtn.frame = frame;
        swipeBtnLabel.frame = labelFrame;
        swipeBtnLabel.text = swipeRightString;
        swipeBtnView.backgroundColor = swipeRightColor;
        swipeBtn.imageView.image = [UIImage imageNamed:@"swipe_right.png"];
    }];
    [locationManager startUpdatingLocation];
    [self stopNavigating];
}
#pragma mark - Start/Stop Navigation
-(void)startNavigating{
    isNavigating = NO;
    timeTakenView.hidden = YES;
    [googleMap clear];
    [locationManager startUpdatingLocation];
}
-(void)stopNavigating{
    
    NSString *baseUrl = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%@,%@&destination=%@,%@&sensor=true",[NSNumber numberWithFloat:startLatitude],
                         [NSNumber numberWithFloat:startLongitude],
                         [NSNumber numberWithFloat:stopLatitude],
                         [NSNumber numberWithFloat:stopLongitude]];
    
    
    NSURL *url = [NSURL URLWithString:[baseUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
//    NSLog(@"Url: %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(!error){
            NSDictionary *result        = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString * status = [result objectForKey:@"status"];
            if([status isEqualToString: @"OK"]){
                NSArray *routes             = [result objectForKey:@"routes"];
                NSDictionary *firstRoute    = [routes objectAtIndex:0];
                NSString *encodedPath       = [firstRoute[@"overview_polyline"] objectForKey:@"points"];
                
                isNavigating = NO;
                [self drawPath:encodedPath];
                [self calculateTimeTaken];
                [self updateStopPositionMarker];
                [self updateStartPositionMarker];
            }
        }
    }];
    [task resume];
}
-(void)drawPath:(NSString*)encodedPath{
    dispatch_async(dispatch_get_main_queue(), ^{
    GMSPolyline *polyPath  = [GMSPolyline polylineWithPath:[GMSPath pathFromEncodedPath:encodedPath]];
    polyPath.strokeColor        = [UIColor colorWithRed:(101/255.0f) green:(193/255.0f) blue:(254/255.0f) alpha:1.0];
    polyPath.strokeWidth        = 5.5f;
    polyPath.map                = googleMap;
    mapView = googleMap;
        });
}

-(void)calculateTimeTaken{
    
    NSString *baseUrl = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=%@,%@&destinations=%@,%@",[NSNumber numberWithFloat:startLatitude],
                         [NSNumber numberWithFloat:startLongitude],
                         [NSNumber numberWithFloat:stopLatitude],
                         [NSNumber numberWithFloat:stopLongitude]];
    NSURL *url = [NSURL URLWithString:[baseUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
//    NSLog(@"Url: %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(!error){
            NSDictionary *result        = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *rows               = [result objectForKey:@"rows"];
            NSDictionary *firstRow      = [rows objectAtIndex:0];
            
            NSArray *elements           = [firstRow objectForKey:@"elements"];
            NSDictionary *firstElement  = [elements objectAtIndex:0];
            
            NSDictionary *duration      = [firstElement objectForKey:@"duration"];
            NSString *timeText          = [duration objectForKey:@"text"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                timeTakenView.hidden = NO;
                timeLabel.text = timeText;
                
            });
            
        }
    }];
    [task resume];
}
#pragma mark - marker methods
-(void)updateStartPositionMarker{
    dispatch_async(dispatch_get_main_queue(), ^{
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(startLatitude, startLongitude);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.icon = [UIImage imageNamed:@"startLocation"];
        marker.map = googleMap;
        mapView = marker.map;
    });
}
-(void)updateStopPositionMarker{
    dispatch_async(dispatch_get_main_queue(), ^{
        CLLocationCoordinate2D position1 = CLLocationCoordinate2DMake(stopLatitude, stopLongitude);
        GMSMarker *marker1 = [GMSMarker markerWithPosition:position1];
        marker1.icon = [UIImage imageNamed:@"stopLocation"];
        marker1.map = googleMap;
        mapView = marker1.map;
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
