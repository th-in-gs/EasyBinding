//
//  ESBViewController.m
//  EasyBinding
//
//  Created by easy on 11-12-22.
//  Copyright (c) 2011年 zeasy@qq.com. All rights reserved.
//

#import "ESBViewController.h"
#import <EasyBinding/EasyBinding.h>
@implementation ESBViewController
@synthesize model = _model;
- (void)dealloc {
    [self unbindAll];
    [_model release],_model = nil;
    [_indicatorView release],_indicatorView = nil;
    [_imageView release],_imageView = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_indicatorView];
    _indicatorView.center = self.view.center;
    _imageView = [[UIImageView alloc] init];
    [self.view addSubview:_imageView];
    
    [super viewDidLoad];
    [self bindKeyPath:@"model.loaded" withAction:@selector(modelLoadedChanged:)];
    [self bindKeyPath:@"model.image" withAction:@selector(modelImageChanged:)];

    // Do any additional setup after loading the view from its nib.
    [self.model load];
}

-(void) modelLoadedChanged:(id<ESBChangeInfo>) changeInfo {
    if ([changeInfo kind] == NSKeyValueChangeSetting) {
        if ([[changeInfo valueNew] boolValue]) {
            [_indicatorView stopAnimating];
        } else {
            [_indicatorView startAnimating];
        }
    }
}

-(void) setImage:(UIImage *) image {
    _imageView.image = image;
    _imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    _imageView.center = self.view.center;
}
-(void) modelImageChanged:(id<ESBChangeInfo>) changeInfo {
    if ([changeInfo kind] == NSKeyValueChangeSetting) {
        UIImage *image = (UIImage *) [changeInfo valueNew];
        if (image != nil) {
            [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:[NSThread isMainThread]];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(ESBModel *)model {
    if (_model == nil) {
        _model = [[ESBModel alloc] init];
    }
    return _model;
}
@end

@implementation ESBModel
@synthesize loaded = _loaded;
@synthesize image = _image;


- (void)dealloc {
    [_image release],_image = nil;
    [super dealloc];
}

-(void)load {
    self.loaded = NO;
    [NSThread detachNewThreadSelector:@selector(doLoad) toTarget:self withObject:nil];
}

-(void) doLoad {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSThread sleepForTimeInterval:2];
    self.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://images.apple.com/iphone/images/product_title.png"]]];
    self.loaded = YES;
    [pool drain];
}

@end
