//
//  EasyBinding.h
//  EasyBinding
//
//  Created by easy on 11-11-16.
//  Copyright (c) 2011年 zeasy@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ESBChangeInfo <NSObject>
@required
-(NSKeyValueChange) kind;
-(id) valueOld;
-(id) valueNew;
-(NSIndexSet *) indexes;
@end

@protocol ESBChangeTransformer <NSObject>
@required
-(void) transform:(id) bindObject 
		didObject:(id) boundObject
		   change:(id<ESBChangeInfo>) changeInfo
	   forKeyPath:(NSString *) keyPath;
@end

@interface NSObject(ESBBindingCenter)
-(void) bind:(id) object forKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer;
-(void) unbind:(id) object forKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer;
-(void) unbind:(id) object forKeyPath:(NSString *) keyPath;
-(void) unbindAll;//call it dealloc always.

-(void) bindKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer;
-(void) unbindKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer;
-(void) unbindKeyPath:(NSString *) keyPath;
@end

@interface NSObject(ESBSelectorChangeTransformer)
-(id<ESBChangeTransformer>) bind:(id) object forKeyPath:(NSString *) keyPath withAction:(SEL) action;
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath withAction:(SEL) action;
@end

@interface NSObject(ESBValueChangeTransformer)
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath toObject:(id)object forKeyPath:(NSString *) objectKeyPath;
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath forKeyPath:(NSString *) objectKeyPath;
@end

#ifndef ESB_Change_Transformer_Block
#define ESB_Change_Transformer_Block
typedef void(^ESBChangeTransformerBlock)(id bindObject,id boundObject,id<ESBChangeInfo> changeInfo,NSString *keyPath);
#endif
@interface NSObject(ESBBlockChangeTransformer)
-(id<ESBChangeTransformer>) bind:(id)object forKeyPath:(NSString *)keyPath transformerBlock:(ESBChangeTransformerBlock) block;
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *)keyPath transformerBlock:(ESBChangeTransformerBlock) block;
@end

@interface NSObject(ESBMethodChangeTransformer)
-(id<ESBChangeTransformer>) bindMethod:(NSString *) name toObject:(id) object forKeyPath:(NSString *) keyPath;
-(id<ESBChangeTransformer>) bindMethodToObject:(id) object forKeyPath:(NSString *) keyPath;

-(id<ESBChangeTransformer>) bindMethod:(NSString *) name forKeyPath:(NSString *) keyPath;
-(id<ESBChangeTransformer>) bindMethodForKeyPath:(NSString *) keyPath;
@end

