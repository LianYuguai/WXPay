//
//  ViewController.m
//  WeiXinPay
//
//  Created by yulong on 2017/8/22.
//  Copyright © 2017年 com.YL. All rights reserved.
//

#import "ViewController.h"
#import "CommonUtil.h"
#import <AFNetworking.h>
#import <WXApi.h>
@interface ViewController (){
    NSString *_nonceStr;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    _nonceStr = [self genNonceStr];
    _nonceStr = [self genNonceStr];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)payAction:(id)sender {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
    [dic setObject:@"自己的appid" forKey:@"appid"];
    [dic setObject:@"自己的商户id" forKey:@"mch_id"];
    [dic setObject:_nonceStr forKey:@"nonce_str"];
    [dic setObject:@"麦侯-测试" forKey:@"body"];
    [dic setObject:[self genTimeStamp] forKey:@"out_trade_no"];
    [dic setObject:@"1" forKey:@"total_fee"];
    [dic setObject:@"127.0.0.1" forKey:@"spbill_create_ip"];
    [dic setObject:@"http://www.weixin.qq.com/wxpay/pay.php" forKey:@"notify_url"];
    [dic setObject:@"APP" forKey:@"trade_type"];
    [dic setObject:[self getSign:dic] forKey:@"sign"];
    
    NSMutableString *paramStr = [NSMutableString string];
    [paramStr appendString:@"<xml>"];
    NSArray *keys = [dic allKeys];
    for (NSString *key in keys) {
        [paramStr appendFormat:@"<%@>",key];
        [paramStr appendString:[dic objectForKey:key]];
        [paramStr appendFormat:@"</%@>",key];
    }
    [paramStr appendString:@"</xml>"];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json",@"text/plain", nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.mch.weixin.qq.com/pay/unifiedorder"]];
    [request setHTTPBody:[paramStr dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"response=%@",response);
        NSLog(@"responseObject=%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        NSLog(@"error=%@",error);
        if (!error) {
            NSString *respondStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSRange locRange = [respondStr rangeOfString:@"<prepay_id><![CDATA["];
            NSInteger loc = locRange.location + locRange.length;
            NSRange range = NSMakeRange(loc, 36);
            NSString *prepayIdStr = [respondStr substringWithRange:range];
            PayReq *request = [[PayReq alloc] init];
            request.partnerId = @"自己的商户id";
            request.prepayId= prepayIdStr;
            request.package = @"Sign=WXPay";
            request.nonceStr= _nonceStr;
            NSString *timeStr = [self genTimeStamp];
            UInt32 time =  [timeStr intValue];
            request.timeStamp= time;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
            [dic setObject:@"自己的appid" forKey:@"appid"];
            [dic setObject:@"自己的商户id" forKey:@"partnerid"];
            [dic setObject:_nonceStr forKey:@"noncestr"];
            [dic setObject:prepayIdStr forKey:@"prepayid"];
            [dic setObject:@"Sign=WXPay" forKey:@"package"];//iOS必须用Sign=WXPay
            [dic setObject:timeStr forKey:@"timestamp"];
            //        [dic setObject:[self getSign:dic] forKey:@"sign"];
            NSString *signStr = [self getSign:dic];
            request.sign= signStr;
            [WXApi sendReq:request];
        }
    }];
    
    [dataTask resume];
}
#pragma mark 时间戳 生成
- (NSString *)genTimeStamp
{
    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
}
- (NSString *)genNonceStr
{
    return [CommonUtil md5:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
}
- (NSString *)getSign:(NSDictionary *)params{
    NSArray *keys = [params allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    // 生成 packageSign
    NSMutableString *package = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        [package appendString:key];
        [package appendString:@"="];
        [package appendString:[params objectForKey:key]];
        [package appendString:@"&"];
    }
    
    [package appendString:@"key="];
    [package appendString:@"自己生成的API key"]; // 注意:不能hardcode在客户端,建议genPackage这个过程都由服务器端完成
    // 进行md5摘要前,params内容为原始内容,未经过url encode处理
    NSString *packageSign = [[CommonUtil md5:[package copy]] uppercaseString];
    return packageSign;
}
@end
