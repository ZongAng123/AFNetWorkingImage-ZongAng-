//
//  ViewController.m
//  AFNetWorkingImage(ZongAng)
//
//  Created by mac on 16/7/30.
//  Copyright © 2016年 纵昂. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()<UIActionSheetDelegate,UIGestureRecognizerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIImageView * imge;
}
@end

@implementation ViewController
//进入程序时从沙河拿去图片  后者去服务端下载
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    从沙盒中拿
    
    NSString * fullpath =[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"currentImage.png"];
    UIImage * savedImage =[[UIImage alloc] initWithContentsOfFile:fullpath];
    [imge setImage:savedImage];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self intUI];
    
}

-(void)intUI{

    imge =[[UIImageView alloc]initWithFrame:CGRectMake(5, 50, 400, 300)];
    imge.userInteractionEnabled = YES;
    imge.backgroundColor =[UIColor grayColor];
    [self.view addSubview:imge];
    
    UITapGestureRecognizer * top =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(ImageClick:)];
    [imge addGestureRecognizer:top];
    
}

-(void)ImageClick:(UITapGestureRecognizer *)gestureRecognnizer{
  
    //选取照片上传
    UIActionSheet *sheet;
    // 判断是否支持相机
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        
    {
        sheet  = [[UIActionSheet alloc] initWithTitle:@"选择" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"拍照",@"从相册选择", nil];
        
    }else {
        
        sheet = [[UIActionSheet alloc] initWithTitle:@"选择" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"从相册选择", nil];
        
    }
    
    sheet.tag = 255;
    
    [sheet showInView:self.view];
    
    
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag ==255) {
        NSUInteger sourceType =0;
        
//    判断是否支持相机
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            switch (buttonIndex) {
                case 0:
//                  取消
                    return;
                    case 1:
//                    相机
                    sourceType =UIImagePickerControllerSourceTypeCamera;
                    break;
                    case 2:
//                    相册
                    sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    break;
                    
                default:
                    break;
             }
            
        }else{
            if (buttonIndex == 0) {
                return;
            }else{
                sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            }
            
        }
//        跳转到相机或相册页面
        UIImagePickerController * imagePickerController =[[UIImagePickerController alloc] init];
        
        imagePickerController.delegate =self;
        
        imagePickerController.allowsEditing = YES;
        
        imagePickerController.sourceType =sourceType;
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
        
    }
}
// 图片选择结束之后，走这个方法，字典存放所有图片信息
#pragma mark - image picker delegte
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage * image =[info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSString * fullpath =[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"currentImage.png"];
    UIImage * savedImage =[[UIImage alloc] initWithContentsOfFile:fullpath];
    
    // 保存图片至本地，方法见下文
    [self saveImage:image withName:@"currentImage.png"];
    
//    图片赋值显示
    [imge setImage:savedImage];
    NSDictionary * dic =@{@"image":fullpath};
    
    [self UploadImage:dic];
    
}

#pragma mark - 保存图片至沙盒（应该是提交后再保存到沙盒,下次直接去沙盒取）
- (void) saveImage:(UIImage *)currentImage withName:(NSString *)imageName
{
    
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.5);
    // 获取沙盒目录
    
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    // 将图片写入文件
    
    [imageData writeToFile:fullPath atomically:NO];
}


//图频上传

-(void)UploadImage:(NSDictionary *)dic
{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //网址
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];

    [manager POST:@"http://112.74.67.161:8080/foodOrder/service/file/upload.do" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    
        //01.21 测试
        NSString * imgpath = [NSString stringWithFormat:@"%@",dic[@"image"]];
        
        UIImage *image = [UIImage imageWithContentsOfFile:imgpath];
        NSData *data = UIImageJPEGRepresentation(image,0.7);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
        
        [formData appendPartWithFileData:data name:@"Filedata" fileName:fileName mimeType:@"image/jpg"];
        
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
//     成功 后处理。
        NSLog(@"Success: %@", responseObject);
        NSString * str = [responseObject objectForKey:@"fileId"];
        if (str != nil) {
//        [self.delegate uploadImgFinish:str];
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //失败
        NSLog(@"Error: %@", error);
    }];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
