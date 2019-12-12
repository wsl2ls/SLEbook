//
//  ViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/10.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "ViewController.h"
#import "ZipArchive.h"
#import "GDataXMLNode.h"
#import "SLChapterModel.h"
#import "SLViewController.h"

#define kDocuments NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

@interface ViewController ()<SSZipArchiveDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - Help Methods
//.opf文件包含电子书的标题、作者、描述、封面、时间等信息
//返回.opf文件的路径
- (NSString *)pathOfOpfWithFilePath:(NSString *)unzipPath {
    //通过解析container.xml文件获得.opf文件的路径，一般是在unzipPath/OPS/name.opf
    NSString *containerPath = [NSString stringWithFormat:@"%@/META-INF/container.xml",unzipPath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:containerPath]) {
        NSError *xmlerror = nil;
        //  GDataXML  https://www.jianshu.com/p/4354c865ecc7
        //  解析成文档
        GDataXMLDocument *xmlDocument = [[GDataXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:containerPath] options:0 error:&xmlerror];
        // 获取属性
        GDataXMLNode* opfPath = [[xmlDocument nodesForXPath:@"//@full-path" error:nil] firstObject];
        //  获取属性的值
        NSString *value=[opfPath stringValue];
        // xml文件中获取full-path属性的节点  full-path的属性值就是opf文件的绝对路径
        NSString *path = [NSString stringWithFormat:@"%@/%@",unzipPath,value];
        return path;
    }else {
        NSLog(@"ERROR：没有container.xml");
    }
    return nil;
}
//解析opf、ncx文件、
- (NSMutableArray *)parseOpf:(NSString *)opfPath {
    
    // 1.解析opf，找到存储目录章节信息的ncx文件
    
    NSError *xmlerror = nil;
    GDataXMLDocument *opfDocument = [[GDataXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:opfPath] options:0 error:&xmlerror];
    NSArray* itemsArray = [opfDocument nodesForXPath:@"//opf:item" namespaces:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]  error:nil];
    //opf文件的命名空间 xmlns="http://www.idpf.org/2007/opf" 需要取到某个节点设置命名空间的键为opf 用opf:节点来获取节点
    NSString *ncxName; //.ncx文件存储着书的目录信息
    //目录索引
    NSMutableDictionary* itemDictionary = [[NSMutableDictionary alloc] init];
    for (GDataXMLElement* element in itemsArray){
        [itemDictionary setValue:[[element attributeForName:@"href"] stringValue] forKey:[[element attributeForName:@"id"] stringValue]];
        if([[[element attributeForName:@"media-type"] stringValue] isEqualToString:@"application/x-dtbncx+xml"]){
            //获取ncx文件名称 根据ncx获取书的目录信息
            ncxName = [[element attributeForName:@"href"] stringValue];
        }
    }
    
    // 2.解析ncx，获取HTML章节文件和标题
    
    //OPS路径
    NSString *OPSPath = [opfPath stringByDeletingLastPathComponent];
    //.ncx和.opf同级目录,都在OPS路径下
    NSString *ncxPath = [NSString stringWithFormat:@"%@/%@",OPSPath,ncxName];
    GDataXMLDocument *ncxDocument = [[GDataXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:ncxPath] options:0 error:&xmlerror];
    //根据opf中的目录索引，查找并存储目录信息  HTML章节文件和标题
    NSMutableDictionary* titleDictionary = [[NSMutableDictionary alloc] init];
    for (GDataXMLElement* element in itemsArray){
        NSString* href = [[element attributeForName:@"href"] stringValue];
        NSString* xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
        //根据opf文件的href获取到ncx文件中的中对应的目录名称
        NSArray* navPoints = [ncxDocument nodesForXPath:xpath namespaces:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"] error:nil];
        if ([navPoints count] == 0) {
            NSString *contentpath = @"//ncx:content";
            NSArray *contents = [ncxDocument nodesForXPath:contentpath namespaces:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"] error:nil];
            for (GDataXMLElement *element in contents) {
                NSString *src = [[element attributeForName:@"src"] stringValue];
                if ([src hasPrefix:href]) {
                    xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", src];
                    navPoints = [ncxDocument nodesForXPath:xpath namespaces:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"] error:nil];
                    break;
                }
            }
        }
        if([navPoints count]!=0){
            GDataXMLElement* titleElement = navPoints.firstObject;
            [titleDictionary setValue:[titleElement stringValue] forKey:href];
        }
    }
    
    // 3. 解析opf，用章节数据模型保存每一章节的信息：标题、图片、
    
    NSArray* itemRefsArray = [opfDocument nodesForXPath:@"//opf:itemref" namespaces:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]  error:nil];
    NSMutableArray *chapters = [NSMutableArray array];
    for (GDataXMLElement* element in itemRefsArray){
        //HTML章节文件名ID
        NSString* chapterHref = [itemDictionary objectForKey:[[element attributeForName:@"idref"] stringValue]];
        //HTML章节路径
        NSString *chapterPath = [[opfPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:chapterHref];
        
        //        NSLog(@"HTML章节：%@  标题： %@  图片地址：%@ ", chapterPath, [titleDictionary objectForKey:chapterHref]  ,[chapterPath stringByDeletingLastPathComponent]);
        
        SLChapterModel *model = [SLChapterModel chapterWithEpub:chapterPath title:[titleDictionary objectForKey:chapterHref] imagePath:[chapterPath stringByDeletingLastPathComponent]];
        [chapters addObject:model];
    }
    return chapters;
    
}
#pragma mark - Event Handle
- (IBAction)readBook:(id)sender {
    //带解压的原始文件路径
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"中公开学APP" ofType:@"epub"];
    //解压后的文件路径
    NSString *unzipPath = [NSString stringWithFormat:@"%@/%@",kDocuments,@"中公开学APP"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:unzipPath]) {
        //已解压 解析
        SLViewController *vc = [[SLViewController alloc] init];
        vc.chapterArray = [self parseOpf:[self pathOfOpfWithFilePath:unzipPath]];
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        //未解压
        [SSZipArchive unzipFileAtPath:filepath toDestination:unzipPath delegate:self];
    }
}

#pragma mark - SSZipArchiveDelegate
//开始解压
- (void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo {
    NSLog(@"开始解压");
}
//解压进度
- (void)zipArchiveProgressEvent:(unsigned long long)loaded total:(unsigned long long)total {
    NSLog(@"解压进度%f", (float)loaded/(float)total);
}
//解压完成
- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    [self  pathOfOpfWithFilePath:unzippedPath];
    NSLog(@"解压完成 %@", unzippedPath);
}

@end
