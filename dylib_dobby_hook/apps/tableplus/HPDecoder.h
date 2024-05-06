//
//  HPDecoder .h
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/16.
//
@interface HPDecoder : NSObject {
    char _initiated;
}
@property (nonatomic,getter=isInitiated) char initiated;
+ (id)attributesForClass:(Class)v1;
+ (void)setAttributes:(id)v1 forClass:(Class)v2;
+ (id)getAttributeForClass:(Class)v1;
+ (id)getPropertyNameStrippedUnderscore:(id)v1;
- (id)init;
- (id)initWithDictionary:(id)v1;
- (id)attributes;
- (void)initData:(id)v1;
- (void)setProperty:(id)v1 propertyType:(id)v2 value:(id)v3;
- (id)toDictionary;
- (id)toArray:(id)v1;
- (id)toValue:(id)v1 key:(id)v2 type:(id)v3;
@end
