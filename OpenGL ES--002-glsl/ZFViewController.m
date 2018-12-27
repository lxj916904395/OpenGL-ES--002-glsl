//
//  ViewController.m
//  OpenGL ES--002-glsl
//
//  Created by zhongding on 2018/12/27.
//

#import "ZFViewController.h"
#import "ZFView.h"

@interface ZFViewController ()
@property(strong ,nonatomic) ZFView *myView;

@end

@implementation ZFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.myView = (ZFView*)self.view;
}


@end
