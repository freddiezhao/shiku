//
//  KKTextTool.m
//  WWImageEdit
//
//  Created by 邬维 on 2017/1/18.
//  Copyright © 2017年 kook. All rights reserved.
//

#import "KKTextTool.h"
#import "KKTextView.h"

#define COLOR_W  26
#define COLOR_INSET  20

@interface KKTextTool()<UITextViewDelegate>
@property (nonatomic, strong) UIView *colorView;         //颜色选择view
@property (nonatomic, strong) UIButton *lastButton;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) CGFloat keyBoardH;


@end

@implementation KKTextTool{

    UIImage *_originalImage;    //原始图片
    UIView *_workingView;       //上层工作区
    UIView *_textMenuView;      //底部工具
    UITextView *_textEditView;  //文字编辑view
}

#pragma -mark KKImageToolProtocol
+ (UIImage*)defaultIconImage{
    return [UIImage imageNamed:@"ToolText"];
}

+ (NSString*)defaultTitle{
    return Localized(@"JX_ImageEditText");
}

+ (NSUInteger)orderNum{
    return KKToolIndexNumberThird;
}

#pragma mark- implementation
- (void)setup {
    
    _colors = @[[UIColor whiteColor],[UIColor blackColor],[UIColor redColor],[UIColor yellowColor],[UIColor greenColor],[UIColor blueColor],[UIColor purpleColor]];
    self.textColor = [_colors firstObject];
    
    _originalImage = self.editor.imageView.image;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _textMenuView = [[UIView alloc] initWithFrame:self.editor.menuView.frame];
    _textMenuView.backgroundColor = self.editor.menuView.backgroundColor;

    [self.editor.view addSubview:_textMenuView];
    
    _workingView = [[UIView alloc] initWithFrame:[self.editor.view convertRect:self.editor.imageView.frame fromView:self.editor.imageView.superview]];
    _workingView.clipsToBounds = YES;
    [self.editor.view addSubview:_workingView];
    
    self.selectedTextView = nil;
    [self setMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeText) name:kTextViewActiveViewDidTapNotification object:nil];
    
    _textMenuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_textMenuView.top);
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textMenuView.transform = CGAffineTransformIdentity;
                     }];
    
    //监听当键盘将要出现时
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    //监听当键将要退出时
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self performSelector:@selector(addNewText) withObject:nil afterDelay:.1f];
}

- (void)updateTextColor:(UIButton *)button {
    if (button.tag == self.lastButton.tag) {
        return;
    }else {
        //还原上个按钮
        self.lastButton.frame = CGRectMake(self.lastButton.frame.origin.x+4, 0, COLOR_W, COLOR_W);
        self.lastButton.layer.cornerRadius = button.frame.size.width/2;
        self.lastButton.layer.borderWidth = 2.f;
        
        button.frame = CGRectMake(button.frame.origin.x-4, -4, COLOR_W+8, COLOR_W+8);
        button.layer.cornerRadius = button.frame.size.width/2;
        button.layer.borderWidth = 3.f;
        self.textColor = self.colors[button.tag];
        //记录一下当前点击按钮
        self.lastButton = button;
    }
    
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  
    [_workingView removeFromSuperview];
    [_textEditView removeFromSuperview];
    [_colorView removeFromSuperview];
    
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textMenuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_textMenuView.top);
                     }
                     completion:^(BOOL finished) {
                         [_textMenuView removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    [KKTextView setActiveTextView:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [self buildImage:_originalImage];
            completionBlock(image, nil, nil);
        });
   
}

#pragma mark- click Action
- (void)addNewText
{
    self.selectedTextView = nil;
    [self showTextEditView:@""];
    [self setNavigationItem:YES];
    
    [self createColorButtonWithArray:self.colors];
}

- (void)changeTextColor{

}

- (void)changeText{
    [self showTextEditView:[_selectedTextView getLableText]];
    [self setNavigationItem:YES];
}

- (void)textSaveBtn{
    [_textEditView resignFirstResponder];
    [self setNavigationItem:NO];
    
    
    
    //修改还是添加
    if (self.selectedTextView) {
        
        [_selectedTextView setLableText:_textEditView.text];
    }else{
        if ([_textEditView.text isEqualToString:@""]) {
            return;
        }
        KKTextView *view = [[KKTextView alloc] initWithTool:self];
        view.textColor = self.textColor;
        view.center = CGPointMake(_workingView.width/2, _workingView.height/2);
        [view setLableText:_textEditView.text];
        [_workingView addSubview:view];
        [KKTextView setActiveTextView:view];
    }
    
    
}

- (void)textCancelBtn{
    [self setNavigationItem:NO];
}

#pragma mark-
- (UIImage*)buildImage:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)setMenu{
//    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 80, 40)];
////    btn.backgroundColor = [UIColor redColor];
//    [btn setTitle:@"添加文字" forState:UIControlStateNormal];
//    btn.titleLabel.textColor = [UIColor whiteColor];
//    btn.titleLabel.font = [UIFont systemFontOfSize:15];
//    [btn addTarget:self action:@selector(addNewText) forControlEvents:UIControlEventTouchUpInside];
//    [_textMenuView addSubview:btn];
    
//    UIButton *btnColor = [[UIButton alloc] initWithFrame:CGRectMake(100, 20, 40, 40)];
//    btnColor.backgroundColor = [UIColor redColor];
//    [btnColor setTitle:@"颜色" forState:UIControlStateNormal];
//    btnColor.titleLabel.textColor = [UIColor whiteColor];
//    btnColor.titleLabel.font = [UIFont systemFontOfSize:15];
//    [btnColor addTarget:self action:@selector(changeTextColor) forControlEvents:UIControlEventTouchUpInside];
//    [_textMenuView addSubview:btnColor];
}


- (void)setNavigationItem:(BOOL)isEdit{

    if(isEdit){
        UINavigationItem *item  = self.editor.navigationItem;
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:Localized(@"JX_Finish") style:UIBarButtonItemStyleDone target:self action:@selector(textSaveBtn)];
        item.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:Localized(@"JX_Cencal") style:UIBarButtonItemStylePlain target:self action:@selector(textCancelBtn)];
        
    }else{
        //修改UINavigationItem
        NSNotification *n = [NSNotification notificationWithName:KTextEditDoneNotification object:self userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
        
        [UIView animateWithDuration:kImageToolAnimationDuration
                         animations:^{
                             _textEditView.transform = CGAffineTransformMakeTranslation(0, 600);
                         }
                         completion:^(BOOL finished) {
                             [_textEditView removeFromSuperview];
                             [_colorView removeFromSuperview];
                         }];
    }
}

//文字编辑view
- (void)showTextEditView:(NSString *)text{
    if (!_textEditView) {
        _textEditView = [[UITextView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, [UIScreen mainScreen].bounds.size.width,800)];
        UIColor *textViewBgColor = [UIColor blackColor];
        _textEditView.backgroundColor = [textViewBgColor colorWithAlphaComponent:0.85];
        [_textEditView setTextColor:[UIColor whiteColor]];
        [_textEditView setFont:[UIFont systemFontOfSize:30]];
        [_textEditView setReturnKeyType:UIReturnKeyDone];
        
        _textEditView.delegate = self;
    }
    [_textEditView setText:text];
    [self.editor.view addSubview:_textEditView];
    _textEditView.transform = CGAffineTransformMakeTranslation(0, 600);
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textEditView.transform = CGAffineTransformIdentity;
                     }];
    [_textEditView becomeFirstResponder];
}

#pragma mark- UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self textSaveBtn];
        return NO;
    }
    return YES;
}


- (void)createColorButtonWithArray:(NSArray *)colorArr {
    self.colorView = [[UIView alloc] init];
    self.colorView.frame = CGRectMake(self.colorView.frame.origin.x, JX_SCREEN_HEIGHT-JX_SCREEN_TOP-self.keyBoardH-44, JX_SCREEN_WIDTH, 44);
    for (int i = 0; i < colorArr.count; i ++) {
        UIButton *btn = [[UIButton alloc] init];
        int X = ((i+1)*COLOR_W)+(i*COLOR_INSET);
        btn.frame = CGRectMake(X, 0, COLOR_W, COLOR_W);
        btn.tag = i;
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = btn.frame.size.width/2;
        btn.layer.borderColor = [[UIColor whiteColor] CGColor];
        btn.layer.borderWidth = 2.f;
        btn.backgroundColor = colorArr[i];
        [btn addTarget:self action:@selector(updateTextColor:) forControlEvents:UIControlEventTouchUpInside];
        if (i <= 0) {
            btn.frame = CGRectMake(X-4, -4, COLOR_W+8, COLOR_W+8);
            btn.layer.cornerRadius = btn.frame.size.width/2;
            btn.layer.borderWidth = 3.f;
            self.lastButton = btn;
        }
        [self.colorView addSubview:btn];
    }
    [_textEditView addSubview:_colorView];
}

//当键盘出现
- (void)keyboardWillShow:(NSNotification *)notification {
    //获取键盘的高度
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    self.keyBoardH = keyboardRect.size.height;
    self.colorView.frame = CGRectMake(self.colorView.frame.origin.x, JX_SCREEN_HEIGHT-JX_SCREEN_TOP-self.keyBoardH-44, JX_SCREEN_WIDTH, 44);
}

//当键退出
- (void)keyboardWillHide:(NSNotification *)notification {
    //获取键盘的高度
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    self.keyBoardH = keyboardRect.size.height;
    self.colorView.frame = CGRectMake(self.colorView.frame.origin.x, JX_SCREEN_HEIGHT-JX_SCREEN_TOP-self.keyBoardH-44, JX_SCREEN_WIDTH, 44);
}

@end
