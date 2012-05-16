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

#import "EasyBinding.h"

@protocol ESBBinder,ESBBounder,ESBChangeTransformer,ESBBounderKey,ESBChangeInfo;

FOUNDATION_EXPORT NSString * const ESBindingContext;
FOUNDATION_EXPORT NSKeyValueObservingOptions const ESBindingOptions;


@protocol ESBBinder <NSObject>
@required
-(id) bindObject;

-(NSArray *) bounders;
-(id<ESBBounder>) bounderForObject:(id) object forKeyPath:(NSString *) keyPath;
-(NSUInteger) countOfBounders;

-(void) bind:(id) bounderObject forKeyPath:(NSString *) keyPath transformer:(id<ESBChangeTransformer>) transformer;
-(void) unbind:(id) bounderObject forKeyPath:(NSString *) keyPath transformer:(id<ESBChangeTransformer>) transformer;
-(void) unbind:(id) bounderObject forKeyPath:(NSString *) keyPath;
-(void) unbindAll;

@end


@interface ESBBinder : NSObject <ESBBinder>{
	id bindObject_;
	NSMutableDictionary *bounderDictionary_;
}
@property (nonatomic, retain, readonly) NSDictionary *bounderDictionary;
@property (nonatomic, assign, readonly) id bindObject;


-(id) initWithObject:(id) object;
+(id) binderWithObject:(id) object;
@end

@protocol ESBBounderKey <NSObject,NSCopying>
@end

@protocol ESBBounder <NSObject>
@required
-(id) boundObject;
-(NSString *) boundKeyPath;

-(id<ESBBinder>) binder;
-(NSMutableArray *) transformers;

-(void) bound;
-(void) unbound;
-(BOOL) isBounded;
@end


@interface ESBBounder : NSObject <ESBBounder> {
	id boundObject_;
	NSString *boundKeyPath_;
	id<ESBBinder> binder_;
	NSMutableArray *transformers_;
	BOOL bounded_;
}
+(id) bounderWithBinder:(id<ESBBinder>) binder 
			boundObject:(id) boundObject 
		   boundKeyPath:(NSString *) boundKeyPath;
-(id) initWithBinder:(id<ESBBinder>) binder 
		 boundObject:(id) boundObject 
		boundKeyPath:(NSString *) boundKeyPath;

@property (nonatomic,assign,readonly) id boundObject;
@property (nonatomic,copy,readonly) NSString *boundKeyPath;
@property (nonatomic,assign,readonly) id<ESBBinder> binder;
@property (nonatomic,retain,readonly) NSMutableArray *transformers;
@property (nonatomic,assign,readonly,getter=isBounded) BOOL bounded;
@end


@interface ESBBounderKey : NSObject <ESBBounderKey>{
	id boundObject_;
	NSString *boundKeyPath_;
}
@property (nonatomic, assign, readonly) id boundObject;
@property (nonatomic, copy, readonly) NSString *boundKeyPath;
-(id) initWithObject:(id) object withKeyPath:(NSString *) keyPath;
+(id) keyWithObject:(id) object withKeyPath:(NSString *) keyPath;
-(id) initWithBounder:(id<ESBBounder>) bounder;
+(id) keyWithBounder:(id<ESBBounder>) bounder;
@end

@interface ESBChangeInfo : NSObject <ESBChangeInfo>{
	NSKeyValueChange kind_;
	id valueOld_;
	id valueNew_;
	NSIndexSet *indexes_;
}
@property (nonatomic, readonly) NSKeyValueChange kind;
@property (nonatomic, retain, readonly) id valueOld;
@property (nonatomic, retain, readonly) id valueNew;
@property (nonatomic, retain, readonly) NSIndexSet *indexes;
-(id) initWithKind:(NSKeyValueChange) kind valueOld:(id) valueOld valueNew:(id) valueNew indexes:(NSIndexSet *) indexes;
+(id) infoWithChange:(NSDictionary *) change;
@end

@implementation ESBChangeInfo
@synthesize kind = kind_;
@synthesize valueOld = valueOld_;
@synthesize valueNew = valueNew_;
@synthesize indexes = indexes_;

-(NSString *) description{
	return [NSString stringWithFormat:@"(valueOld:%@,valueNew:%@,indexes:%@,kind:%d)",
			[self valueOld],[self valueNew],[self indexes],[self kind]];
}

-(void) dealloc{
	[self->valueOld_ release],self->valueOld_ = nil;
	[self->valueNew_ release],self->valueNew_ = nil;
	[self->indexes_ release], self->indexes_ = nil;
	[super dealloc];
}

-(id) initWithKind:(NSKeyValueChange) kind valueOld:(id) valueOld valueNew:(id) valueNew indexes:(NSIndexSet *) indexes{
	self = [super init];
	if (self != nil) {
		if (kind < NSKeyValueChangeSetting || kind > NSKeyValueChangeReplacement) {
			[self release];
			self = nil;
		}else {
			self->kind_ = kind;
			self->valueOld_ = [valueOld retain];
			self->valueNew_ = [valueNew retain];
			self->indexes_ = [indexes retain];
		}
	}
	return self;
}
+(id) infoWithChange:(NSDictionary *) change{
	if (change == nil) {
		return nil;
	}
	NSKeyValueChange kind = [[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
	id valueOld = [change objectForKey:NSKeyValueChangeOldKey];
	if (valueOld == [NSNull null]) {	//change at 11.11.04
		valueOld = nil;
	}
	id valueNew = [change objectForKey:NSKeyValueChangeNewKey];
	if (valueNew == [NSNull null]) {	//change at 11.11.04
		valueNew = nil;
	}
	NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
	
	return [[[ESBChangeInfo alloc] initWithKind:kind valueOld:valueOld valueNew:valueNew indexes:indexes] autorelease];
}
@end
NSString * const ESBindingContext = @"ESBindingContext";
NSKeyValueObservingOptions const ESBindingOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;


@implementation ESBBounder
@synthesize boundObject = boundObject_;
@synthesize boundKeyPath = boundKeyPath_;
@synthesize binder = binder_;
@synthesize transformers = transformers_;
@synthesize bounded = bounded_;

-(void) dealloc{
	[self unbound];
	[self->transformers_ release],self->transformers_ = nil;
	self->binder_ = nil;
	self->boundObject_ = nil;
	[self->boundKeyPath_ release],self->boundKeyPath_ = nil;
	
	[super dealloc];
}
+(id) bounderWithBinder:(id<ESBBinder>) binder 
			boundObject:(id) boundObject 
		   boundKeyPath:(NSString *) boundKeyPath{
	return [[[self alloc] initWithBinder:binder boundObject:boundObject boundKeyPath:boundKeyPath] autorelease];
}
-(id) initWithBinder:(id<ESBBinder>) binder 
		 boundObject:(id) boundObject 
		boundKeyPath:(NSString *) boundKeyPath{
	self = [super init];
	if (self != nil) {
		if (binder == nil || boundObject == nil || boundKeyPath == nil) {
			[self release];
			self = nil;
		}else {
			self->binder_ = binder;
			self->boundObject_ = boundObject;
			self->boundKeyPath_ = [boundKeyPath copy];
		}
	}
	return self;
}

-(NSMutableArray *) transformers{
	if (self->transformers_ == nil) {
		self->transformers_ = [[NSMutableArray array] retain];
	}
	return self->transformers_;
}

-(void) bound{
	if (!self.bounded) {
		[self.boundObject addObserver:self forKeyPath:self.boundKeyPath options:ESBindingOptions context:ESBindingContext];
		self->bounded_ = YES;
	}
}
-(void) unbound{
	if (self.bounded) {
		[self.boundObject removeObserver:self forKeyPath:self.boundKeyPath];
		self->bounded_ = NO;
	}
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	
	if (context == nil || ![ESBindingContext isEqual:context]) {
		return;
	}
	if (object != self.boundObject || ![keyPath isEqualToString:self.boundKeyPath]) {
		return;
	}

	for (id<ESBChangeTransformer> transformer in self.transformers) {
		if ([self.binder bindObject] != nil && self.boundObject != nil && self.boundKeyPath != nil) {
			[transformer transform:[self.binder bindObject] 
						 didObject:self.boundObject
							change:[ESBChangeInfo infoWithChange:change] 
						forKeyPath:self.boundKeyPath];
		}
	}
}

@end

@implementation ESBBounderKey

@synthesize boundObject = boundObject_;
@synthesize boundKeyPath = boundKeyPath_;
-(void) dealloc{
	self->boundObject_ = nil;
	[self->boundKeyPath_ release], self->boundKeyPath_ = nil;
	[super dealloc];
}
-(id) initWithObject:(id) object withKeyPath:(NSString *) keyPath{
	self = [super init];
	if (self != nil) {
		if (object == nil || keyPath == nil) {
			[self release];
			self = nil;
		}else {
			self->boundObject_ = object;
			self->boundKeyPath_ = [keyPath copy];
		}
	}
	return self;
}

+(id) keyWithObject:(id) object withKeyPath:(NSString *) keyPath{
	return [[[self alloc] initWithObject:object withKeyPath:keyPath] autorelease];
}
-(id) initWithBounder:(id<ESBBounder>) bounder{
	return [self initWithObject:[bounder boundObject] withKeyPath:[bounder boundKeyPath]];
}

+(id) keyWithBounder:(id<ESBBounder>) bounder{
	return [[[self alloc] initWithBounder:bounder] autorelease];
}

- (id)copyWithZone:(NSZone *)zone{
	return [self retain];
}

-(NSUInteger) hash{
	
	
	NSUInteger hash = 7;
	hash = 83 * hash + (self.boundObject != nil ? [self.boundObject hash] : 0);
	hash = 83 * hash + (self.boundKeyPath != nil ? [self.boundKeyPath hash] : 0);
	
	return hash;
}

-(BOOL) isEqual:(id)object{
	if (object == nil) {
		return NO;
	}
	if ([self class] != [object class]) {
		return NO;
	}
	const ESBBounderKey *other = (ESBBounderKey *) object;
	
	if (self.boundObject != other.boundObject && (self.boundObject != nil && ![self.boundObject isEqual:other.boundObject])) {
		return NO;
	}
	
	if ((self.boundKeyPath == nil) ? (other.boundKeyPath != nil) : ![self.boundKeyPath isEqualToString:other.boundKeyPath]) {
		return NO;
	}
	
	return YES;
}

@end
@implementation ESBBinder
@synthesize bindObject = bindObject_;
@synthesize bounderDictionary = bounderDictionary_;

-(void) dealloc{
	[self unbindAll];
	[self->bounderDictionary_ release], self->bounderDictionary_ = nil;
	self->bindObject_ = nil;
	[super dealloc];
}

-(id) initWithObject:(id) object{
	self = [super init];
	if (self != nil) {
		if (object == nil) {
			[self release];
			self = nil;
		}else {
			self->bindObject_ = object;
		}
	}
	return self;
}

+(id) binderWithObject:(id) object{
	return [[[self alloc] initWithObject:object] autorelease];
}

-(NSDictionary *) bounderDictionary{
	if (self->bounderDictionary_ == nil) {
		self->bounderDictionary_ = [[NSMutableDictionary dictionary] retain];
	}
	return self->bounderDictionary_;
}

-(NSArray *) bounders{
	return [self.bounderDictionary allValues];
}

-(id<ESBBounder>) bounderForObject:(id) object forKeyPath:(NSString *) keyPath{
	ESBBounderKey *key = [ESBBounderKey keyWithObject:object withKeyPath:keyPath];
	return key != nil ? [self.bounderDictionary objectForKey:key] : nil;
}
-(NSUInteger) countOfBounders{
	return [self.bounderDictionary count];
}

-(void) bind:(id) bounderObject forKeyPath:(NSString *) keyPath transformer:(id<ESBChangeTransformer>) transformer{
	if (bounderObject != nil && keyPath != nil && transformer != nil) {
		id<ESBBounder> bounder = [self bounderForObject:bounderObject forKeyPath:keyPath];
		if (bounder == nil) {
			bounder = [ESBBounder bounderWithBinder:self boundObject:bounderObject boundKeyPath:keyPath];
			ESBBounderKey *key = [ESBBounderKey keyWithBounder:bounder];
			if (key != nil) {
				[(NSMutableDictionary *)self.bounderDictionary setObject:bounder forKey:key];
				[bounder bound];
			}
		}
		[[bounder transformers] addObject:transformer];
	}
}

-(void) unbind:(id) bounderObject forKeyPath:(NSString *) keyPath{
	if (bounderObject != nil && keyPath != nil) {
		id<ESBBounder> bounder = [self bounderForObject:bounderObject forKeyPath:keyPath];
		[bounder unbound];
		ESBBounderKey *key = [ESBBounderKey keyWithBounder:bounder];
		[(NSMutableDictionary *)self.bounderDictionary removeObjectForKey:key];
	}
}

-(void) unbind:(id) bounderObject forKeyPath:(NSString *) keyPath transformer:(id<ESBChangeTransformer>) transformer{
	if (bounderObject != nil && keyPath != nil && transformer != nil) {
		id<ESBBounder> bounder = [self bounderForObject:bounderObject forKeyPath:keyPath];
		if (bounder != nil) {
			[[bounder transformers] removeObject:transformer];
			if ([[bounder transformers] count] == 0) {
				[bounder unbound];
				ESBBounderKey *key = [ESBBounderKey keyWithBounder:bounder];
				[(NSMutableDictionary *)self.bounderDictionary removeObjectForKey:key];
			}
		}
	}
}
-(void) unbindAll{
	if ([self countOfBounders] > 0) {
		NSArray *bounders = [self bounders];
		for (id<ESBBounder> bounder in bounders) {
			[bounder unbound];
		}
		[(NSMutableDictionary *)self.bounderDictionary removeAllObjects];
	}
}
@end

@interface ESBBindingCenter : NSObject {
	NSMutableDictionary *bindings_;
}
@property (nonatomic, readonly) NSDictionary *bindings;

+(id) defaultCenter;

-(void) bindObject:(id) bindObject 
		  toObject:(id) boundObject 
		forKeyPath:(NSString *) keyPath 
   withTransformer:(id<ESBChangeTransformer>) transformer;

-(void) unbindObject:(id) bindObject 
			toObject:(id) boundObject 
		  forKeyPath:(NSString *) keyPath 
	 withTransformer:(id<ESBChangeTransformer>) transformer;

-(void) unbindObject:(id) bindObject 
			toObject:(id) boundObject 
		  forKeyPath:(NSString *) keyPath;

-(void) unbindObject:(id) bindObject;

-(void) unbindAll;

@end

@implementation ESBBindingCenter
-(void) dealloc{
	[self unbindAll];
	[self->bindings_ release], self->bindings_ = nil;
	[super dealloc];
}

+(id) defaultCenter{
	static id defaultCenter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		defaultCenter = [[self alloc] init];
	});
	return defaultCenter;
}

-(NSDictionary *) bindings{
	if (self->bindings_ == nil) {
		self->bindings_ = [[NSMutableDictionary dictionary] retain];
	}
	return self->bindings_;
}

-(id) nonretainObjectWithObject:(id) object{
	return object != nil ? [NSValue valueWithNonretainedObject:object] : nil;
}

-(id) objectWithNonretainObject:(id) object{
	return object != nil && [object isKindOfClass:[NSValue class]] ? [(NSValue *)object nonretainedObjectValue] : nil;
}

-(void) bindObject:(id) bindObject toObject:(id) boundObject forKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer{
	if (bindObject == nil || boundObject == nil || keyPath == nil || transformer == nil) {
		return;
	}
	id key = [self nonretainObjectWithObject:bindObject];
	if (key != nil) {
		id<ESBBinder> binder = [self.bindings objectForKey:key];
		if (binder == nil) {
			binder = [ESBBinder binderWithObject:bindObject];
			[(NSMutableDictionary *) self.bindings setObject:binder forKey:key]; 
		}
		[binder bind:boundObject forKeyPath:keyPath transformer:transformer];
	}
}


-(void) unbindObject:(id) bindObject 
			toObject:(id) boundObject 
		  forKeyPath:(NSString *) keyPath 
	 withTransformer:(id<ESBChangeTransformer>) transformer{
	if (bindObject == nil || boundObject == nil || keyPath == nil || transformer == nil) {
		return;
	}
	
	id key = [self nonretainObjectWithObject:bindObject];
	if (key != nil) {
		id<ESBBinder> binder = [self.bindings objectForKey:key];
		if (binder != nil) { 
			[binder unbind:boundObject forKeyPath:keyPath transformer:transformer];
			if ([binder countOfBounders] == 0) {
				[(NSMutableDictionary *)self.bindings removeObjectForKey:key];
			}
		}
	}
}

-(void) unbindObject:(id) bindObject 
			toObject:(id) boundObject 
		  forKeyPath:(NSString *) keyPath{
	if (bindObject == nil || boundObject == nil || keyPath == nil) {
		return;
	}
	
	id key = [self nonretainObjectWithObject:bindObject];
	if (key != nil) {
		id<ESBBinder> binder = [self.bindings objectForKey:key];
		if (binder != nil) {
			[binder unbind:boundObject forKeyPath:keyPath];
			if ([binder countOfBounders] == 0) {
				[(NSMutableDictionary *)self.bindings removeObjectForKey:key];
			}
		}
	}
}

-(void) unbindObject:(id) bindObject{
	if (bindObject == nil) {
		return;
	}
	
	id key = [self nonretainObjectWithObject:bindObject];
	if (key != nil) {
		id<ESBBinder> binder = [self.bindings objectForKey:key];
		if (binder != nil) {
			[binder unbindAll];
			[(NSMutableDictionary *)self.bindings removeObjectForKey:key];
		}
	}
}

-(void) unbindAll{
	NSArray *binders = [self.bindings allValues];
	for (id<ESBBinder> binder in binders) {
		[binder unbindAll];
	}
	[(NSMutableDictionary *)self.bindings removeAllObjects];
}
@end

@interface ESBSelectorChangeTransformer : NSObject <ESBChangeTransformer>{
	SEL selector_;
}
@property (nonatomic, readonly) SEL selector;

-(id) initWithSelector:(SEL) selector;
+(id) transformerWithSelector:(SEL) selector;

@end

@implementation ESBSelectorChangeTransformer
@synthesize selector = selector_;

-(void) dealloc{
	self->selector_ = nil;
	[super dealloc];
}

-(id) initWithSelector:(SEL) selector{
	self = [super init];
	if (self != nil) {
		if (selector != nil) {
			self->selector_ = selector;
		}else {
			[self release], self = nil;
		}
	}
	return self;
}

+(id) transformerWithSelector:(SEL) selector{
	return [[[self alloc] initWithSelector:selector] autorelease];
}

-(void) transform:(id)bindObject didObject:(id)boundObject  
		   change:(id <ESBChangeInfo>)changeInfo forKeyPath:(NSString *)keyPath{
	if (bindObject == nil || boundObject == nil || changeInfo == nil || keyPath == nil) {
		return;
	}
	
	NSMethodSignature *signature = [bindObject methodSignatureForSelector:self.selector];
	if (signature != nil) {
		NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:signature];
		if (invoke != nil) {
			NSUInteger numberOfArgs = [signature numberOfArguments];
			[invoke setSelector:self.selector];
			switch (numberOfArgs - 2) {
				case 0:
					[invoke invokeWithTarget:bindObject];
					break;
				case 1:
					[invoke setArgument:&changeInfo atIndex:2];
					[invoke invokeWithTarget:bindObject];
					break;
				default:
					[invoke setArgument:&bindObject atIndex:2];
					[invoke setArgument:&boundObject atIndex:3];
					[invoke setArgument:&changeInfo atIndex:4];
					[invoke setArgument:&keyPath atIndex:5];
					[invoke invokeWithTarget:bindObject];
					break;
			}
		}
	}else {
		NSLog(@"%@:selector(%@) not responds",bindObject,NSStringFromSelector(self.selector));
	}
    
}
@end

@implementation NSObject(ESBBindingCenter)
-(void) bind:(id) object forKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer{
	[[ESBBindingCenter defaultCenter] bindObject:self 
										toObject:object
									  forKeyPath:keyPath
								 withTransformer:transformer];
}
-(void) unbind:(id) object forKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer{
	[[ESBBindingCenter defaultCenter] unbindObject:self
										  toObject:object
										forKeyPath:keyPath
								   withTransformer:transformer];
}
-(void) unbind:(id) object forKeyPath:(NSString *) keyPath{
	[[ESBBindingCenter defaultCenter] unbindObject:self
										  toObject:object
										forKeyPath:keyPath];
}
-(void) unbindAll{
	[[ESBBindingCenter defaultCenter] unbindObject:self];
}

-(void) bindKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer{
	[self bind:self forKeyPath:keyPath withTransformer:transformer];
}
-(void) unbindKeyPath:(NSString *) keyPath withTransformer:(id<ESBChangeTransformer>) transformer{
	[self unbind:self forKeyPath:keyPath withTransformer:transformer];
}
-(void) unbindKeyPath:(NSString *) keyPath{
	[self unbind:self forKeyPath:keyPath];
}
@end

@implementation NSObject(ESBSelectorChangeTransformer)
-(id<ESBChangeTransformer>) bind:(id) object forKeyPath:(NSString *) keyPath withAction:(SEL) action{
	ESBSelectorChangeTransformer *trans = [ESBSelectorChangeTransformer transformerWithSelector:action];
	[self bind:object forKeyPath:keyPath withTransformer:trans];
	return trans;
}
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath withAction:(SEL) action{
	ESBSelectorChangeTransformer *trans = [ESBSelectorChangeTransformer transformerWithSelector:action];
	[self bindKeyPath:keyPath withTransformer:trans];
	return trans;
}
@end

// 未使用 NSValueTransformer 做值转换，这里直接赋值，需要保证双方类型相同
@interface ESBValueChangeTransformer : NSObject <ESBChangeTransformer>{
	NSString *keyPath_;
}
@property (nonatomic, copy, readonly) NSString *keyPath;

-(id) initWithKeyPath:(NSString *) keyPath;
+(id) transformerWithKeyPath:(NSString *) keyPath;
@end

@implementation ESBValueChangeTransformer
@synthesize keyPath = keyPath_;
-(void) dealloc{
	[keyPath_ release], keyPath_ = nil;
	[super dealloc];
}

+(id) transformerWithKeyPath:(NSString *) keyPath{
	return [[[self alloc] initWithKeyPath:keyPath] autorelease];
}

-(id) initWithKeyPath:(NSString *) keyPath{
	self = [super init];
	if (self != nil) {
		if (keyPath == nil) {
			[self release];
			self = nil;
		}else {
			keyPath_ = [keyPath copy];
		}
        
	}
	return self;
}

-(void) transform:(id)bindObject didObject:(id)boundObject 
		   change:(id <ESBChangeInfo>)changeInfo forKeyPath:(NSString *)keyPath{
	if (bindObject == nil || boundObject == nil || changeInfo == nil || keyPath == nil) {
		return;
	}
	if ([changeInfo kind] < NSKeyValueChangeSetting || [changeInfo kind] > NSKeyValueChangeReplacement) {
		return;
	}
	
	switch ([changeInfo kind]) {
		case NSKeyValueChangeSetting://NSKeyValueUnionSetMutation
			[bindObject setValue:[changeInfo valueNew] forKeyPath:self.keyPath];
			break;
		case NSKeyValueChangeInsertion:
			if ([changeInfo indexes] != nil) {
				NSMutableArray * array = [bindObject mutableArrayValueForKeyPath:self.keyPath];
				[array insertObjects:[changeInfo valueNew] atIndexes:[changeInfo indexes]];
			}else {//NSKeyValueMinusSetMutation
				NSMutableSet *set = [bindObject mutableSetValueForKeyPath:self.keyPath];
				[set unionSet:[changeInfo valueNew]];
			}
			break;
		case NSKeyValueChangeRemoval:
			if ([changeInfo indexes] != nil) {
				NSMutableArray * array = [bindObject mutableArrayValueForKeyPath:self.keyPath];
				[array removeObjectsAtIndexes:[changeInfo indexes]];
			}else {//NSKeyValueIntersectSetMutation
				NSMutableSet *set = [bindObject mutableSetValueForKeyPath:self.keyPath];
				[set minusSet:[changeInfo valueOld]];
			}
			break;
		case NSKeyValueChangeReplacement:
			if ([changeInfo indexes] != nil) {
				NSMutableArray * array = [bindObject mutableArrayValueForKeyPath:self.keyPath];
				[array replaceObjectsAtIndexes:[changeInfo indexes] withObjects:[changeInfo valueNew]];
			}else {//NSKeyValueSetSetMutation
				NSMutableSet *set = [bindObject mutableSetValueForKeyPath:self.keyPath];
				//[set setSet:[changeInfo valueNew]];
				
				[set minusSet:[changeInfo valueOld]];
				[set unionSet:[changeInfo valueNew]];
				
			}
			break;
	}
}

@end

@implementation NSObject(ESBValueChangeTransformer)
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath toObject:(id)object forKeyPath:(NSString *) objectKeyPath{
	id<ESBChangeTransformer> transformer = [ESBValueChangeTransformer transformerWithKeyPath:keyPath];
	[self bind:object forKeyPath:objectKeyPath withTransformer:transformer];
	return transformer;
}
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *) keyPath forKeyPath:(NSString *) objectKeyPath{
	id<ESBChangeTransformer> transformer = [ESBValueChangeTransformer transformerWithKeyPath:keyPath];
	[self bind:self forKeyPath:objectKeyPath withTransformer:transformer];
	return transformer;
}
@end

@interface ESBBlockChangeTransformer : NSObject <ESBChangeTransformer>{
	ESBChangeTransformerBlock block_;
}
@property (nonatomic, copy, readonly) ESBChangeTransformerBlock block;
-(id) initWithBlock:(ESBChangeTransformerBlock) block;
+(id) transformerWithBlock:(ESBChangeTransformerBlock) block;
@end

@implementation ESBBlockChangeTransformer
@synthesize block = block_;
-(void) dealloc{
	[block_ release], block_ = nil;
	[super dealloc];
}
+(id) transformerWithBlock:(ESBChangeTransformerBlock) block{
	return [[[self alloc] initWithBlock:block] autorelease];
}
-(id) initWithBlock:(ESBChangeTransformerBlock) block{
	self = [super init];
	if (self != nil) {
		if (block == nil) {
			[self release];
			self = nil;
		}else {
			block_ = [block copy];
		}
	}
	return self;
}
-(void) transform:(id)bindObject didObject:(id)boundObject 
		   change:(id <ESBChangeInfo>)changeInfo forKeyPath:(NSString *)keyPath{
	if (self.block != nil && bindObject != nil && boundObject != nil && changeInfo != nil && keyPath != nil) {
		self.block(bindObject,boundObject,changeInfo,keyPath);
	}
}

@end

@implementation NSObject(ESBBlockChangeTransformer)
-(id<ESBChangeTransformer>) bind:(id)object forKeyPath:(NSString *)keyPath transformerBlock:(ESBChangeTransformerBlock) block{
	id<ESBChangeTransformer> transformer = [ESBBlockChangeTransformer transformerWithBlock:block];
	[self bind:object forKeyPath:keyPath withTransformer:transformer];
	return transformer;
}
-(id<ESBChangeTransformer>) bindKeyPath:(NSString *)keyPath transformerBlock:(ESBChangeTransformerBlock) block{
	id<ESBChangeTransformer> transformer = [ESBBlockChangeTransformer transformerWithBlock:block];
	[self bindKeyPath:keyPath withTransformer:transformer];
	return transformer;
}
@end

FOUNDATION_EXPORT NSString * const ESBMethodChangeObjectNameDefaultValue;		//object

FOUNDATION_EXPORT NSString * const ESBMethodChangeSettingNameDefaultValue;		//set
FOUNDATION_EXPORT NSString * const ESBMethodChangeInsertionNameDefaultValue;	//insert
FOUNDATION_EXPORT NSString * const ESBMethodChangeRemovalNameDefaultValue;		//remove
FOUNDATION_EXPORT NSString * const ESBMethodChangeReplacementNameDefaultValue;	//replace

FOUNDATION_EXPORT NSString * const ESBMethodChangeUnionSetNameDefaultValue;	//unionSet
FOUNDATION_EXPORT NSString * const ESBMethodChangeMinusSetNameDefaultValue;	//minusSet
//FOUNDATION_EXPORT NSString * const ESBMethodChangeIntersectSetNameDefaultValue;	//intersectSet
//FOUNDATION_EXPORT NSString * const ESBMethodChangeSetSetNameDefaultValue;	//setSet


@interface ESBMethodChangeTransformer : NSObject <ESBChangeTransformer> {
	NSString *settingName_;			//NSKeyValueChangeSetting		if nil then default
	NSString *insertionName_;		//NSKeyValueChangeInsertion		if nil then default
	NSString *removalName_;			//NSKeyValueChangeRemoval		if nil then default
	NSString *replacementName_;		//NSKeyValueChangeReplacement	if nil then default
	
	NSString *unionName_;		//NSKeyValueUnionSetMutation		if nil then default
	NSString *minusName_;		//NSKeyValueMinusSetMutation		if nil then default
    //	NSString *intersectName_;	//NSKeyValueIntersectSetMutation	if nil then default
    //	NSString *setName_;			//NSKeyValueSetSetMutation			if nil then default
	
	NSString *objectName_;			//if nil then default
    
}

@property (nonatomic, copy) NSString *settingName;
@property (nonatomic, copy) NSString *insertionName;
@property (nonatomic, copy) NSString *removalName;
@property (nonatomic, copy) NSString *replacementName;

@property (nonatomic, copy) NSString *unionName;
@property (nonatomic, copy) NSString *minusName;
//@property (nonatomic, copy) NSString *intersectName;
//@property (nonatomic, copy) NSString *setName;

@property (nonatomic, copy) NSString *objectName;

+(id) transformer; 
//默认驼峰式 exp: user.name -> UserName
-(NSString *) nameForKeyPath:(NSString *) keyPath;

//默认 -> <objectName>:(boundObject) did<keyPath>ChangeInfo:(id<ESBChangeInfo>) info
//exp: object:didUserNameChange:
-(NSString *) defaultMethodForKeyPath:(NSString *) keyPath;	//未找到匹配的kind方法时调用

//默认 -> <objectName>:(boundObject) did<SettingName><keyPath>:(valueOld) with<SettingName>:(valueNew)
//exp: object:didSetUserName:withUserName:
-(NSString *) settingMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<InsertionName><keyPath>:(valueNew) atIndexes:(indexes)
//exp: object:didInsertUserName:atIndexes:
-(NSString *) insertionMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<RemovalName><keyPath>:(valueNew) atIndexes:(indexes)
//exp: object:didRemoveUserName:atIndexes:
-(NSString *) removalMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<ReplacementName><keyPath>:(valueOld) atIndexes:(indexes) with<keyPath>:(valueNew)
//exp: object:didReplaceUserName:atIndexes:withUserName:
-(NSString *) replacementMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<MinusName><keyPath>:(valueOld)
//exp: object:didMinusUserName:
-(NSString *) minusMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<UnionName><keyPath>:(valueNew)
//exp: object:didUnionUserName:
-(NSString *) unionMethodNameForKeyPath:(NSString *) keyPath;
//默认 -> <objectName>:(boundObject) did<MinusName><keyPath>:(valueOld) with<UnionName><keyPath>:(valueNew)
-(NSString *) minusAndUnionMethodNameForKeyPath:(NSString *) keyPath;

-(BOOL) invokDefaultMethod:(NSString *) method /*defaultMethodForKeyPath:*/
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				changeInfo:(id<ESBChangeInfo>) changeInfo;

-(BOOL) invokSettingMethod:(NSString *) method /*settingMethodNameForKeyPath:*/
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				  valueOld:(id) valueOld 
				  valueNew:(id) valueNew;

-(BOOL) invokInsertionMethod:(NSString *) method /*insertionMethodNameForKeyPath:*/
				  bindObject:(id) bindObject 
				 boundObject:(id) boundObject 
					valueNew:(id) valueNew
					 indexes:(NSIndexSet *) indexes;

-(BOOL) invokRemovalMethod:(NSString *) method /*removalMethodNameForKeyPath:*/
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				  valueOld:(id) valueOld
				   indexes:(NSIndexSet *) indexes;

-(BOOL) invokReplacementMethod:(NSString *) method /*replacementMethodNameForKeyPath:*/
					bindObject:(id) bindObject 
				   boundObject:(id) boundObject 
					  valueOld:(id) valueOld
					  valueNew:(id) valueNew
					   indexes:(NSIndexSet *) indexes;

-(BOOL) invokMinusMethod:(NSString *) method	/*minusMethodNameForKeyPath:*/
			  bindObject:(id) bindObject 
			 boundObject:(id) boundObject 
				valueOld:(id) valueOld;

-(BOOL) invokUnionMethod:(NSString *) method	/*unionMethodNameForKeyPath:*/
			  bindObject:(id) bindObject 
			 boundObject:(id) boundObject 
				valueNew:(id) valueNew;

-(BOOL) invokMinusAndUnionMethod:(NSString *) method /*minusAndUnionMethodNameForKeyPath:*/
					  bindObject:(id) bindObject 
					 boundObject:(id) boundObject 
						valueOld:(id) valueOld
						valueNew:(id) valueNew;
@end

NSString * const ESBMethodChangeObjectNameDefaultValue		= @"object";

NSString * const ESBMethodChangeSettingNameDefaultValue		= @"set";
NSString * const ESBMethodChangeInsertionNameDefaultValue	= @"insert";
NSString * const ESBMethodChangeRemovalNameDefaultValue		= @"remove";
NSString * const ESBMethodChangeReplacementNameDefaultValue = @"replace";

NSString * const ESBMethodChangeUnionSetNameDefaultValue	= @"union";
NSString * const ESBMethodChangeMinusSetNameDefaultValue	= @"minus";
//NSString * const ESBMethodChangeIntersectSetNameDefaultValue= @"intersect";
//NSString * const ESBMethodChangeSetSetNameDefaultValue		= @"set";

@implementation ESBMethodChangeTransformer
@synthesize settingName = settingName_;
@synthesize insertionName = insertionName_;
@synthesize removalName = removalName_;
@synthesize replacementName = replacementName_;

@synthesize unionName = unionName_;
@synthesize minusName = minusName_;
//@synthesize intersectName = intersectName_;
//@synthesize setName = setName_;

@synthesize objectName = objectName_;

-(void) dealloc{
	[settingName_ release],settingName_ = nil;
	[insertionName_ release],insertionName_ = nil;
	[removalName_ release],removalName_ = nil;
	[replacementName_ release],replacementName_ = nil;
	
	[unionName_ release],unionName_ = nil;
	[minusName_ release],minusName_ = nil;
	//[intersectName_ release],intersectName_= nil;
	//[setName_ release],setName_ = nil;
	
	[objectName_ release],objectName_= nil;
	[super dealloc];
}
+(id) transformer{
	return [[[self alloc] init] autorelease];
}
-(NSString *) settingName{
	return settingName_ != nil ? settingName_ : ESBMethodChangeSettingNameDefaultValue;
}
-(NSString *) insertionName{
	return insertionName_ != nil ? insertionName_ : ESBMethodChangeInsertionNameDefaultValue;
}
-(NSString *) removalName{
	return removalName_ != nil ? removalName_ : ESBMethodChangeRemovalNameDefaultValue;
}
-(NSString *) replacementName{
	return replacementName_ != nil ? replacementName_ : ESBMethodChangeReplacementNameDefaultValue;
}
-(NSString *) unionName{
	return unionName_ != nil ? unionName_ : ESBMethodChangeUnionSetNameDefaultValue;
}
-(NSString *) minusName{
	return minusName_ != nil ? minusName_ : ESBMethodChangeMinusSetNameDefaultValue;
}
//-(NSString *) intersectName{
//	return intersectName_ != nil ? intersectName_ : ESBMethodChangeIntersectSetNameDefaultValue;
//}
//-(NSString *) setName{
//	return setName_ != nil ? setName_ : ESBMethodChangeSetSetNameDefaultValue;
//}
-(NSString *) objectName{
	return objectName_ != nil ? objectName_ : ESBMethodChangeObjectNameDefaultValue;
}


-(NSString *) nameForKeyPath:(NSString *) keyPath{
	return [[keyPath capitalizedString] stringByReplacingOccurrencesOfString:@"." withString:@""];
}

-(NSString *) defaultMethodForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@"ChangeInfo:"];
	return methodName;
}

-(NSString *) settingMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.settingName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":with"];
	[methodName appendString:keyPathName];
	[methodName appendString:@":"];
	return methodName;
}

-(NSString *) insertionMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.insertionName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":atIndexes:"];
	return methodName;
}

-(NSString *) removalMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.removalName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":atIndexes:"];
	return methodName;
}

-(NSString *) replacementMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.replacementName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":atIndexes:with"];
	[methodName appendString:keyPathName];
	[methodName appendString:@":"];
	return methodName;
}

-(NSString *) minusMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.minusName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":"];
	return methodName;
}

-(NSString *) unionMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.unionName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":"];
	return methodName;
}

-(NSString *) minusAndUnionMethodNameForKeyPath:(NSString *) keyPath{
	NSMutableString *methodName = [NSMutableString stringWithString:self.objectName];
	[methodName appendString:@":did"];
	[methodName appendString:[self.minusName capitalizedString]];
	NSString *keyPathName = [self nameForKeyPath:keyPath];
	[methodName appendString:keyPathName];
	[methodName appendString:@":with"];
	[methodName appendString:[self.unionName capitalizedString]]; 
	[methodName appendString:keyPathName];
	[methodName appendString:@":"];
	return methodName;
}
-(BOOL) invokDefaultMethod:(NSString *) method /*defaultMethodForKeyPath:*/
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				changeInfo:(id<ESBChangeInfo>) changeInfo{
	if (method != nil && bindObject != nil && boundObject != nil && changeInfo != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 4) {//4-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&changeInfo atIndex:3];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
    
}
-(BOOL) invokSettingMethod:(NSString *) method 
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				  valueOld:(id) valueOld 
				  valueNew:(id) valueNew{
	
	if (method != nil && bindObject != nil && boundObject != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 5) {//5-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueOld atIndex:3];
				[invok setArgument:&valueNew atIndex:4];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokInsertionMethod:(NSString *) method 
				  bindObject:(id) bindObject 
				 boundObject:(id) boundObject 
					valueNew:(id) valueNew
					 indexes:(NSIndexSet *) indexes{
	if (method != nil && bindObject != nil && boundObject != nil && valueNew != nil && indexes != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 5) {//5-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueNew atIndex:3];
				[invok setArgument:&indexes atIndex:4];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokRemovalMethod:(NSString *) method 
				bindObject:(id) bindObject 
			   boundObject:(id) boundObject 
				  valueOld:(id) valueOld
				   indexes:(NSIndexSet *) indexes{
	if (method != nil && bindObject != nil && boundObject != nil && valueOld != nil & indexes != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 5) {//5-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueOld atIndex:3];
				[invok setArgument:&indexes atIndex:4];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokReplacementMethod:(NSString *) method 
					bindObject:(id) bindObject 
				   boundObject:(id) boundObject 
					  valueOld:(id) valueOld
					  valueNew:(id) valueNew
					   indexes:(NSIndexSet *) indexes{
	if (method != nil && bindObject != nil && boundObject != nil && valueOld != nil && valueNew != nil && indexes != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 6) {//6-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueOld atIndex:3];
				[invok setArgument:&indexes atIndex:4];
				[invok setArgument:&valueNew atIndex:5];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokMinusMethod:(NSString *) method 
			  bindObject:(id) bindObject 
			 boundObject:(id) boundObject 
				valueOld:(id) valueOld{
	if (method != nil && bindObject != nil && boundObject != nil && valueOld != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 4) {//4-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueOld atIndex:3];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokUnionMethod:(NSString *) method 
			  bindObject:(id) bindObject 
			 boundObject:(id) boundObject 
				valueNew:(id) valueNew{
	if (method != nil && bindObject != nil && boundObject != nil && valueNew != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 4) {//4-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueNew atIndex:3];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL) invokMinusAndUnionMethod:(NSString *) method 
					  bindObject:(id) bindObject 
					 boundObject:(id) boundObject 
						valueOld:(id) valueOld
						valueNew:(id) valueNew{
	if (method != nil && bindObject != nil && boundObject != nil && valueOld != nil && valueNew != nil) {
		SEL selector = NSSelectorFromString(method);
		if (selector != nil && [bindObject respondsToSelector:selector]) {
			NSMethodSignature *signature = [bindObject methodSignatureForSelector:selector];
			if (signature != nil && [signature numberOfArguments] == 5) {//5-2个参数
				NSInvocation *invok = [NSInvocation invocationWithMethodSignature:signature];
				[invok setSelector:selector];
				[invok setArgument:&boundObject atIndex:2];
				[invok setArgument:&valueOld atIndex:3];
				[invok setArgument:&valueNew atIndex:4];
				[invok invokeWithTarget:bindObject];
				return YES;
			}
		}
	}
	return NO;
}

-(void) transform:(id)bindObject didObject:(id)boundObject  
		   change:(id <ESBChangeInfo>)changeInfo forKeyPath:(NSString *)keyPath{
	if (bindObject == nil || boundObject == nil || changeInfo == nil || keyPath == nil) {
		return;
	}
	if ([changeInfo kind] < NSKeyValueChangeSetting || [changeInfo kind] > NSKeyValueChangeReplacement) {
		return;
	}
	
	BOOL invok = NO;
	
	NSKeyValueChange kind = [changeInfo kind];
	id valueNew = [changeInfo valueNew];
	id valueOld = [changeInfo valueOld];
	NSIndexSet *indexes = [changeInfo indexes];
	switch (kind) {
		case NSKeyValueChangeSetting:{
			NSString *settingMethod = [self settingMethodNameForKeyPath:keyPath];
			invok = [self invokSettingMethod:settingMethod
								  bindObject:bindObject
								 boundObject:boundObject
									valueOld:valueOld
									valueNew:valueNew];
			break;
		}
		case NSKeyValueChangeInsertion:{//NSKeyValueUnionSetMutation
			if (valueNew != nil) {
				if (indexes != nil) {		//有序 -> Array
					NSString *insertionMethod = [self insertionMethodNameForKeyPath:keyPath];
					invok = [self invokInsertionMethod:insertionMethod
											bindObject:bindObject
										   boundObject:boundObject
											  valueNew:valueNew
											   indexes:indexes];
				}else {		//无序 -> set
					NSString *unionMethod = [self unionMethodNameForKeyPath:keyPath];
					invok = [self invokUnionMethod:unionMethod
										bindObject:bindObject
									   boundObject:boundObject
										  valueNew:valueNew];
				}
				
				break;
			}
		}
		case NSKeyValueChangeRemoval:{//NSKeyValueMinusSetMutation,NSKeyValueIntersectSetMutation
			if (valueOld != nil) {
				if (indexes != nil) {
					NSString *removalMethod = [self removalMethodNameForKeyPath:keyPath];
					invok = [self invokRemovalMethod:removalMethod
										  bindObject:bindObject
										 boundObject:boundObject
											valueOld:valueOld
											 indexes:indexes];
				}else {
					NSString *minusMethod = [self minusMethodNameForKeyPath:keyPath];
					invok = [self invokMinusMethod:minusMethod
										bindObject:bindObject
									   boundObject:boundObject
										  valueOld:valueOld];
				}
			}
			break;
		}
			
		case NSKeyValueChangeReplacement:{//NSKeyValueSetSetMutation
			if (valueOld != nil && valueNew != nil) {
				if (indexes != nil) {
					NSString *replacementMethod = [self replacementMethodNameForKeyPath:keyPath];
					invok = [self invokReplacementMethod:replacementMethod
											  bindObject:bindObject
											 boundObject:boundObject
												valueOld:valueOld
												valueNew:valueNew
												 indexes:indexes];
				}else {
					NSString *minusAndUnionMethod = [self minusAndUnionMethodNameForKeyPath:keyPath];
					invok = [self invokMinusAndUnionMethod:minusAndUnionMethod
												bindObject:bindObject
											   boundObject:boundObject
												  valueOld:valueOld 
												  valueNew:valueNew];
				}
				
			}
			break;
		}
	}
	
	if (!invok) {
		NSString *defaultMethod = [self defaultMethodForKeyPath:keyPath];
		[self invokDefaultMethod:defaultMethod 
					  bindObject:bindObject 
					 boundObject:boundObject
					  changeInfo:changeInfo];
	}
	
	//	NSLog(@"-----------------------------------------------------------------");
	//	NSLog(@"kind:%d",[changeInfo kind]);
	//	NSLog(@"valueNew:%@",[changeInfo valueNew]);
	//	NSLog(@"valueOld:%@",[changeInfo valueOld]);
	//	NSLog(@"indexex:%@",[changeInfo indexes]);
	//	NSLog(@"-----------------------------------------------------------------");
	//	
	
}

@end

@implementation NSObject(ESBMethodChangeTransformer)
-(id<ESBChangeTransformer>) bindMethod:(NSString *) name toObject:(id) object forKeyPath:(NSString *) keyPath{
	ESBMethodChangeTransformer *transformer = [ESBMethodChangeTransformer transformer];
	if (name != nil) {
		transformer.objectName = name;
	}
	[self bind:object forKeyPath:keyPath withTransformer:transformer];
	return transformer;
}

-(id<ESBChangeTransformer>) bindMethodToObject:(id) object forKeyPath:(NSString *) keyPath{
	ESBMethodChangeTransformer *transformer = [ESBMethodChangeTransformer transformer];
	[self bind:object forKeyPath:keyPath withTransformer:transformer];
	return transformer;
}

-(id<ESBChangeTransformer>) bindMethod:(NSString *) name forKeyPath:(NSString *) keyPath{
	ESBMethodChangeTransformer *transformer = [ESBMethodChangeTransformer transformer];
	if (name != nil) {
		transformer.objectName = name;
	}
	[self bindKeyPath:keyPath withTransformer:transformer];
	return transformer;
}

-(id<ESBChangeTransformer>) bindMethodForKeyPath:(NSString *) keyPath{
	ESBMethodChangeTransformer *transformer = [ESBMethodChangeTransformer transformer];
	[self bindKeyPath:keyPath withTransformer:transformer];
	return transformer;
}
@end