//
//  Mapper.h
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/16.
//

#import "HPDecoder.h"

@interface Mapper : HPDecoder {
    NSMutableArray * _reactions;
    NSMutableArray * _actions;
    NSMutableArray * _keyPaths;
    char _fetching;
}
@property (nonatomic,getter=isFetching) char fetching;
- (id)reactions;
- (id)actions;
- (id)keyPaths;
- (id)init;
- (void)commonInit;
- (char)keyPathExisted:(id)v1;
- (void)addKeyPath:(id)v1;
- (void)removeKeyPath:(id)v1;
- (id)getReactionsOfProperty:(id)v1 onEvent:(long long)v2;
- (id)getReactionsOfProperty:(id)v1;
- (id)getActionsOfProperty:(id)v1 target:(id)v2 selector:(SEL)v3 onEvent:(long long)v4;
- (id)getActionsOfProperty:(id)v1 target:(id)v2 selector:(SEL)v3;
- (id)getActionsOfProperty:(id)v1 target:(id)v2;
- (id)getActionsOfProperty:(id)v1 onEvent:(long long)v2;
- (id)getActionsOfProperty:(id)v1;
- (void)registerObserverForKeyPath:(id)v1;
- (void)removeObserverForKeyPath:(id)v1;
- (void)removeAllObservers;
- (void)removeActions:(id)v1 observerForKeyPath:(id)v2;
- (void)removeReactions:(id)v1 observerForKeyPath:(id)v2;
- (void)property:(id)v1 onEvent:(long long)v2 reaction:(void (^ /* unknown block signature */)(void))v3;
- (void)property:(id)v1 target:(id)v2 selector:(SEL)v3 onEvent:(long long)v4;
- (void)properties:(id)v1 onEvent:(long long)v2 reaction:(void (^ /* unknown block signature */)(void))v3;
- (void)properties:(id)v1 target:(id)v2 selector:(SEL)v3 onEvent:(long long)v4;
- (void)removeReactionsForProperty:(id)v1 onEvent:(long long)v2;
- (void)removeReactionsForProperty:(id)v1;
- (void)removeReactionsForProperties:(id)v1 onEvent:(long long)v2;
- (void)removeReactionsForProperties:(id)v1;
- (void)removeAllReactions;
- (void)removeActionsForProperty:(id)v1 target:(id)v2 selector:(SEL)v3 onEvent:(long long)v4;
- (void)removeActionsForProperty:(id)v1 target:(id)v2;
- (void)removeActionsForProperty:(id)v1;
- (void)removeActionsForProperties:(id)v1 target:(id)v2 selector:(SEL)v3 onEvent:(long long)v4;
- (void)removeActionsForProperties:(id)v1 target:(id)v2;
- (void)removeActionsForProperties:(id)v1;
- (void)removeAllActions;
- (void)observeValueForKeyPath:(id)v1 ofObject:(id)v2 change:(id)v3 context:(void *)v4;
- (void)fetchInBackground;
- (void)fetchInBackground:(void (^ /* unknown block signature */)(void))v1;
- (id)getSourceKeyPath;
- (id)getSourceUrl;
- (id)getSourceMethod;
- (id)getSourceParameters;
- (id)getSourceHeader;
- (void)dealloc;
//- (void).cxx_destruct;
@end
