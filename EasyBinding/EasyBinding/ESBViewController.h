//
//  ESBViewController.h
//  EasyBinding
//
//  Created by easy on 11-12-22.
//  Copyright (c) 2011年 zeasy@qq.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ESBModel : NSObject {
    BOOL _loaded;
    UIImage *_image;
}

@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, retain) UIImage *image;

-(void) load;

@end


@interface ESBViewController : UIViewController {
    ESBModel *_model;
    UIActivityIndicatorView *_indicatorView;
    UIImageView *_imageView;
}

@property (nonatomic, retain) ESBModel *model;
@end

