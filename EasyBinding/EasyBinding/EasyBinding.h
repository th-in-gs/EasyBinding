/*
 Copyright (c) 2011, copyright z.easy zeasy@qq.com
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met: 
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer. 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution. 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies, 
 either expressed or implied, of the FreeBSD Project.
*/

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

