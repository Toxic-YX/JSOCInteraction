//
//  ViewController.m
//  JS调用OCMethond(相机和相册)
//
//  Created by Rookie_YX on 16/10/24.
//  Copyright © 2016年 Rookie_YX. All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "SaveImage_Util.h"

@protocol JSDelegate <JSExport>
//这个方法就是window.document.iosDelegate.getImage(JSON.stringify(parameter)); 中的 getImage()方法
- (void)getImage:(id)parameter;
@end

@interface ViewController ()<UIWebViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,JSDelegate>{
  int indextNumb;// 交替图片名字
  UIImage *getImage;//获取的图片
}
@property(strong, nonatomic) JSContext *jsContext;
@property(retain, nonatomic) UIWebView *myWebView;
@end

@implementation ViewController
#pragma mark - life cycle
- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupWebView];
  }

#pragma private methond
- (void)setupWebView{
  if (!self.myWebView) {
    //初始化 WebView
    self.myWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.myWebView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:0.400 alpha:1.000];
    // 代理
    self.myWebView.delegate = self;
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:path]];
    [self.view addSubview:self.myWebView];
  }
}

#pragma mark UIWebViewDelegate  
// 加载完成开始监听js的方法
- (void)webViewDidFinishLoad:(UIWebView *)webView{
  self.jsContext = [self.myWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
  self.jsContext[@"iosDelegate"] = self;//挂上代理  iosDelegate是window.document.iosDelegate.getImage(JSON.stringify(parameter)); 中的 iosDelegate
  self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception){
    context.exception = exception;
    NSLog(@"获取 self.jsContext 异常信息：%@",exception);
  };
}

#pragma mark - JSDelegate
- (void)getImage:(id)parameter{
  // 把 parameter json字符串解析成字典
  NSString *jsonStr = [NSString stringWithFormat:@"%@", parameter];
  NSDictionary *jsParameDic = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding ] options:NSJSONReadingAllowFragments error:nil];
  NSLog(@"js传来的json字典: %@", jsParameDic);
  for (NSString *key in jsParameDic.allKeys)
  {
    NSLog(@"jsParameDic[%@]:%@", key, jsParameDic[key]);
  }
  [self beginOpenPhoto];
}
- (void)beginOpenPhoto
{
  // 主队列 异步打开相机
  dispatch_async(dispatch_get_main_queue(), ^{
    [self takePhoto];
  });
}

#pragma mark 取消选择照片代理方法 
- (void) localPhoto
{
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
  imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  imagePicker.delegate = self;
  [self presentViewController:imagePicker animated:YES completion:nil];
}
#pragma mark      //打开相机拍照
- (void) takePhoto
{
  UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
  {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = sourceType;
    picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:picker animated:YES completion:nil];
  }
  else
  {
    NSLog(@"模拟器中不能打开相机");
    [self localPhoto];
  }
}

//  选择一张照片后进入这里
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
  NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
  //  当前选择的类型是照片
  if ([type isEqualToString:@"public.image"])
  {
    // 获取照片
    getImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    NSLog(@"===Decoded image size: %@", NSStringFromCGSize(getImage.size));
    // obtainImage 压缩图片 返回原尺寸
    indextNumb = indextNumb == 1?2:1;
    NSString *nameStr = [NSString stringWithFormat:@"Varify%d.jpg",indextNumb];
    [SaveImage_Util saveImage:getImage ImageName:nameStr back:^(NSString *imagePath) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"图片路径：%@",imagePath);
        /**
         *  这里是IOS 调 js 其中 setImageWithPath 就是js中的方法 setImageWithPath(),参数是字典
         */
        JSValue *jsValue = self.jsContext[@"setImageWithPath"];
        [jsValue callWithArguments:@[@{@"imagePath":imagePath,@"iosContent":@"获取图片成功，把系统获取的图片路径传给js 让html显示"}]];
      });
    }];
    [picker dismissViewControllerAnimated:YES completion:nil];
  }
}

/*
 在js获取的object对象的解析和取值的方式有两种，一种类似OC的方法（上面HTML中写的方法: arguments['iosContent']），另一种是用eval()方法，如
 document.getElementById('iosParame').innerHTML = eval("arguments."+'iosContent');
 */

@end
