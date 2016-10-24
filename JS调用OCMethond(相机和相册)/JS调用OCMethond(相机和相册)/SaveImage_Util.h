//
//  SaveImage_Util.h
//  JS调用OCMethond(相机和相册)
//
//  Created by Rookie_YX on 16/10/24.
//  Copyright © 2016年 Rookie_YX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface SaveImage_Util : NSObject

/**
 保存图片到document

 @param saveImage <#saveImage description#>
 @param imageName <#imageName description#>
 @param back      <#back description#>

 @return <#return value description#>
 */
+ (BOOL)saveImage:(UIImage *)saveImage ImageName:(NSString *)imageName back:(void(^)(NSString *imagePath))back;
@end
