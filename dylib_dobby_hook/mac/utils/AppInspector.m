#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>


// 窗口信息数据结构
@interface WindowInfo : NSObject
@property (nonatomic, strong) NSString* windowClass;
@property (nonatomic, strong) NSString* controllerClass;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) NSString* module;
@end

@implementation WindowInfo
@end

// 类信息数据结构
@interface ClassInfo : NSObject
@property (nonatomic, strong) NSString* className;
@property (nonatomic, strong) NSArray* properties;
@property (nonatomic, strong) NSArray* methods;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, strong) NSString* module;
- (NSString*)formattedDetailsString;
@end

@implementation ClassInfo
- (NSString*)formattedDetailsString
{
    NSMutableString* details = [NSMutableString string];

    [details appendString:@"属性:\n"];
    for (NSString* property in self.properties) {
        [details appendFormat:@"  %@\n", property];
    }

    [details appendString:@"\n方法:\n"];
    for (NSString* method in self.methods) {
        [details appendFormat:@"  %@\n", method];
    }
    return details;
}
@end



// 主控制器类声明
@interface AppInspectorWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSTabViewDelegate>
@property (nonatomic, strong) NSTabView* tabView;
@property (nonatomic, strong) NSTableView* windowTableView;
@property (nonatomic, strong) NSTableView* classTableView;
@property (nonatomic, strong) NSMutableArray* windowInfoData;
@property (nonatomic, strong) NSMutableArray* classInfoData;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong) NSTimer* refreshTimer;
@property (nonatomic, strong) NSSearchField* searchField;
@property (nonatomic, strong) NSMutableArray* filteredWindowData;
@property (nonatomic, strong) NSMutableArray* filteredClassData;
@property (nonatomic, strong) NSMenu* contextMenu;
@end

@implementation AppInspectorWindowController

- (instancetype)init
{
    NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 800, 600)
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];

    self = [super initWithWindow:window];
    if (self) {
        [self setupWindow];
        [self setupContextMenu];
        [self setupUI];
        [self loadData];
    }
    return self;
}

- (void)setupWindow
{
    self.window.title = @"App Inspector";
    self.window.minSize = NSMakeSize(600, 400);
    [self.window center];

    // 设置窗口层级，确保显示在最前面
    self.window.level = NSFloatingWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
}


- (void)formatSwiftClassName:(id)sender
{
    NSTableView* activeTableView = [self getActiveTableView];
    if (!activeTableView || activeTableView.selectedRow < 0) {
        [self showAlert:@"错误" message:@"请先选择要格式化的类名"];
        return;
    }

    NSInteger selectedRow = activeTableView.selectedRow;
    NSString* className = nil;
    
    if (activeTableView == self.windowTableView) {
        if (selectedRow < self.filteredWindowData.count) {
            WindowInfo* info = self.filteredWindowData[selectedRow];
            className = info.windowClass;
        }
    } else {
        if (selectedRow < self.filteredClassData.count) {
            ClassInfo* info = self.filteredClassData[selectedRow];
            className = info.className;
        }
    }
    
    if (!className) {
        [self showAlert:@"错误" message:@"无法获取类名"];
        return;
    }
    
    // 使用系统命令格式化
    [self demangleSwiftClassName:className];
}

- (void)demangleSwiftClassName:(NSString*)mangledName
{
    // 创建任务执行 swift-demangle 命令
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcrun";
    task.arguments = @[@"swift-demangle", mangledName];
    
    NSPipe* pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    NSFileHandle* file = [pipe fileHandleForReading];
    
    @try {
        [task launch];
        [task waitUntilExit];
        
        NSData* data = [file readDataToEndOfFile];
        NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (task.terminationStatus == 0 && result.length > 0) {
            // 成功格式化
            NSString* formattedName = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self showFormattedResult:mangledName formatted:formattedName];
        } else {
            // 格式化失败，尝试其他方法
            [self fallbackDemangle:mangledName];
        }
    } @catch (NSException* exception) {
        // 命令执行失败
        [self fallbackDemangle:mangledName];
    }
}

- (void)fallbackDemangle:(NSString*)mangledName
{
    // 备用方案：尝试使用 nm 命令
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/nm";
    task.arguments = @[@"-C", @"--demangle"];
    
    NSPipe* inputPipe = [NSPipe pipe];
    NSPipe* outputPipe = [NSPipe pipe];
    task.standardInput = inputPipe;
    task.standardOutput = outputPipe;
    task.standardError = outputPipe;
    
    NSFileHandle* inputFile = [inputPipe fileHandleForWriting];
    NSFileHandle* outputFile = [outputPipe fileHandleForReading];
    
    @try {
        [task launch];
        
        // 写入要格式化的类名
        NSData* inputData = [mangledName dataUsingEncoding:NSUTF8StringEncoding];
        [inputFile writeData:inputData];
        [inputFile closeFile];
        
        [task waitUntilExit];
        
        NSData* outputData = [outputFile readDataToEndOfFile];
        NSString* result = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        if (result.length > 0) {
            NSString* formattedName = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self showFormattedResult:mangledName formatted:formattedName];
        } else {
            [self showFormattedResult:mangledName formatted:@"无法格式化此类名"];
        }
    } @catch (NSException* exception) {
        [self showFormattedResult:mangledName formatted:@"格式化失败"];
    }
}

- (void)showFormattedResult:(NSString*)original formatted:(NSString*)formatted
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"Swift 类名格式化结果";
    
    // 提取格式化后的干净结果
    NSString* cleanFormatted = formatted;
    if ([formatted containsString:@" ---> "]) {
        NSArray* parts = [formatted componentsSeparatedByString:@" ---> "];
        if (parts.count > 1) {
            cleanFormatted = parts[1];
        }
    }
    
    // 去掉多余的空格和换行
    cleanFormatted = [cleanFormatted stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString* message;
    if ([cleanFormatted isEqualToString:original] || cleanFormatted.length == 0) {
        message = [NSString stringWithFormat:@"%@\n\n该类名可能不是 Swift mangled name", original];
    } else {
        message = cleanFormatted;
    }
    
    alert.informativeText = message;
    [alert addButtonWithTitle:@"复制"];
    [alert addButtonWithTitle:@"关闭"];
    
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertFirstButtonReturn) {
                          [self copyToClipboard:cleanFormatted];
                          [self showNotification:@"已复制格式化结果"];
                      }
                  }];
}

- (void)setupContextMenu
{
    self.contextMenu = [[NSMenu alloc] init];

    // 复制选中内容
    NSMenuItem* copyMenuItem = [[NSMenuItem alloc] initWithTitle:@"复制" action:@selector(copySelectedContent:) keyEquivalent:@""];
    copyMenuItem.target = self;
    [self.contextMenu addItem:copyMenuItem];

    [self.contextMenu addItem:[NSMenuItem separatorItem]];

    // 复制整行内容
    NSMenuItem* copyRowMenuItem = [[NSMenuItem alloc] initWithTitle:@"复制整行" action:@selector(copyRowContent:) keyEquivalent:@""];
    copyRowMenuItem.target = self;
    [self.contextMenu addItem:copyRowMenuItem];

    // 复制所有可见数据
    NSMenuItem* copyAllMenuItem = [[NSMenuItem alloc] initWithTitle:@"复制所有可见数据" action:@selector(copyAllContent:) keyEquivalent:@""];
    copyAllMenuItem.target = self;
    [self.contextMenu addItem:copyAllMenuItem];

    [self.contextMenu addItem:[NSMenuItem separatorItem]];
    
    // 格式化 Swift 类名 (新增)
    NSMenuItem* formatSwiftMenuItem = [[NSMenuItem alloc] initWithTitle:@"格式化 Swift 类名" action:@selector(formatSwiftClassName:) keyEquivalent:@""];
    formatSwiftMenuItem.target = self;
    [self.contextMenu addItem:formatSwiftMenuItem];
    [self.contextMenu addItem:[NSMenuItem separatorItem]];

    // 刷新数据
    NSMenuItem* refreshMenuItem = [[NSMenuItem alloc] initWithTitle:@"刷新" action:@selector(refreshData:) keyEquivalent:@""];
    refreshMenuItem.target = self;
    [self.contextMenu addItem:refreshMenuItem];
}

- (void)setupUI
{
    NSView* contentView = self.window.contentView;

    // 创建搜索框 (Moved to top)
    self.searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
    self.searchField.placeholderString = @"搜索类名或窗口...";
    self.searchField.target = self;
    self.searchField.action = @selector(searchTextChanged:);

    // 创建工具栏
    NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"InspectorToolbar"];
    toolbar.delegate = (id<NSToolbarDelegate>)self;
    toolbar.allowsUserCustomization = YES;
    toolbar.autosavesConfiguration = YES;
    self.window.toolbar = toolbar;

    // 创建Tab视图
    self.tabView = [[NSTabView alloc] init];
    self.tabView.delegate = self;
    self.tabView.translatesAutoresizingMaskIntoConstraints = NO;

    // 创建窗口信息Tab
    NSTabViewItem* windowTab = [[NSTabViewItem alloc] init];
    windowTab.label = @"窗口结构";
    windowTab.identifier = @"windows";

    // 窗口信息表格
    NSScrollView* windowScrollView = [[NSScrollView alloc] init];
    windowScrollView.hasVerticalScroller = YES;
    windowScrollView.autohidesScrollers = YES;

    self.windowTableView = [[NSTableView alloc] init];
    self.windowTableView.delegate = self;
    self.windowTableView.dataSource = self;
    self.windowTableView.usesAlternatingRowBackgroundColors = YES;
    // 设置右键菜单
    self.windowTableView.menu = self.contextMenu;

    // 添加窗口表格列
    NSTableColumn* windowClassColumn = [[NSTableColumn alloc] initWithIdentifier:@"windowClass"];
    windowClassColumn.title = @"窗口类";
    windowClassColumn.width = 200;
    [self.windowTableView addTableColumn:windowClassColumn];
    
    NSTableColumn* windowModuleColumn = [[NSTableColumn alloc] initWithIdentifier:@"module"];
    windowModuleColumn.title = @"模块";
    windowModuleColumn.width = 150;
    [self.windowTableView addTableColumn:windowModuleColumn];

    NSTableColumn* controllerColumn = [[NSTableColumn alloc] initWithIdentifier:@"controller"];
    controllerColumn.title = @"控制器";
    controllerColumn.width = 200;
    [self.windowTableView addTableColumn:controllerColumn];

    NSTableColumn* titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    titleColumn.title = @"标题";
    titleColumn.width = 150;
    [self.windowTableView addTableColumn:titleColumn];

//    NSTableColumn* frameColumn = [[NSTableColumn alloc] initWithIdentifier:@"frame"];
//    frameColumn.title = @"Frame";
//    frameColumn.width = 200;
//    [self.windowTableView addTableColumn:frameColumn];

    windowScrollView.documentView = self.windowTableView;
    windowTab.view = windowScrollView;
    [self.tabView addTabViewItem:windowTab];

    // 创建类信息Tab
    NSTabViewItem* classTab = [[NSTabViewItem alloc] init];
    classTab.label = @"类信息";
    classTab.identifier = @"classes";

    // 类信息表格
    NSScrollView* classScrollView = [[NSScrollView alloc] init];
    classScrollView.hasVerticalScroller = YES;
    classScrollView.autohidesScrollers = YES;

    self.classTableView = [[NSTableView alloc] init];
    self.classTableView.delegate = self;
    self.classTableView.dataSource = self;
    self.classTableView.usesAlternatingRowBackgroundColors = YES;
    // 设置右键菜单
    self.classTableView.menu = self.contextMenu;

    // 添加类表格列
    NSTableColumn* classNameColumn = [[NSTableColumn alloc] initWithIdentifier:@"className"];
    classNameColumn.title = @"类名";
    classNameColumn.width = 300;
    [self.classTableView addTableColumn:classNameColumn];
    
    NSTableColumn* classModuleColumn = [[NSTableColumn alloc] initWithIdentifier:@"module"];
    classModuleColumn.title = @"模块";
    classModuleColumn.width = 150;
    [self.classTableView addTableColumn:classModuleColumn];

    NSTableColumn* propertiesColumn = [[NSTableColumn alloc] initWithIdentifier:@"properties"];
    propertiesColumn.title = @"属性数量";
    propertiesColumn.width = 100;
    [self.classTableView addTableColumn:propertiesColumn];

    NSTableColumn* methodsColumn = [[NSTableColumn alloc] initWithIdentifier:@"methods"];
    methodsColumn.title = @"方法数量";
    methodsColumn.width = 100;
    [self.classTableView addTableColumn:methodsColumn];

    NSTableColumn* detailsColumn = [[NSTableColumn alloc] initWithIdentifier:@"details"];
    detailsColumn.title = @"详细信息";
    detailsColumn.width = 250;
    [self.classTableView addTableColumn:detailsColumn];

    classScrollView.documentView = self.classTableView;
    classTab.view = classScrollView;
    [self.tabView addTabViewItem:classTab];

    // 添加Tab视图到内容视图
    [contentView addSubview:self.tabView];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.tabView.topAnchor constraintEqualToAnchor:contentView.topAnchor
                                               constant:10],
        [self.tabView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor
                                                   constant:10],
        [self.tabView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor
                                                    constant:-10],
        [self.tabView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor
                                                  constant:-10]
    ]];

    // 初始化过滤数组
    self.filteredWindowData = [NSMutableArray array];
    self.filteredClassData = [NSMutableArray array];
}

#pragma mark - Context Menu Actions

- (void)copySelectedContent:(id)sender
{
    NSTableView* activeTableView = [self getActiveTableView];
    if (!activeTableView || activeTableView.selectedRow < 0) {
        [self showAlert:@"错误" message:@"请先选择要复制的内容"];
        return;
    }

    NSInteger selectedRow = activeTableView.selectedRow;
    NSInteger clickedColumn = activeTableView.clickedColumn;

    if (clickedColumn < 0) {
        clickedColumn = 0; // 默认复制第一列
    }

    NSString* content = [self getContentForTableView:activeTableView row:selectedRow column:clickedColumn];
    [self copyToClipboard:content];
    [self showNotification:[NSString stringWithFormat:@"已复制: %@", [content substringToIndex:MIN(20, content.length)]]];
}

- (void)copyRowContent:(id)sender
{
    NSTableView* activeTableView = [self getActiveTableView];
    if (!activeTableView || activeTableView.selectedRow < 0) {
        [self showAlert:@"错误" message:@"请先选择要复制的行"];
        return;
    }

    NSInteger selectedRow = activeTableView.selectedRow;
    NSMutableArray* rowContents = [NSMutableArray array];

    for (NSInteger col = 0; col < activeTableView.tableColumns.count; col++) {
        NSString* content = [self getContentForTableView:activeTableView row:selectedRow column:col];
        [rowContents addObject:content ?: @""];
    }

    NSString* rowContent = [rowContents componentsJoinedByString:@" | "];
    [self copyToClipboard:rowContent];
    [self showNotification:@"已复制整行内容"];
}

- (void)copyAllContent:(id)sender
{
    NSTableView* activeTableView = [self getActiveTableView];
    if (!activeTableView) {
        return;
    }

    NSMutableString* allContent = [NSMutableString string];
    NSArray* dataSource = [self getDataSourceForTableView:activeTableView];

    // 添加表头
    NSMutableArray* headers = [NSMutableArray array];
    for (NSTableColumn* column in activeTableView.tableColumns) {
        [headers addObject:column.title];
    }
    [allContent appendFormat:@"%@\n", [headers componentsJoinedByString:@" | "]];

    // 添加数据行
    for (NSInteger row = 0; row < dataSource.count; row++) {
        NSMutableArray* rowContents = [NSMutableArray array];
        for (NSInteger col = 0; col < activeTableView.tableColumns.count; col++) {
            NSString* content = [self getContentForTableView:activeTableView row:row column:col];
            [rowContents addObject:content ?: @""];
        }
        [allContent appendFormat:@"%@\n", [rowContents componentsJoinedByString:@" | "]];
    }

    [self copyToClipboard:allContent];
    [self showNotification:[NSString stringWithFormat:@"已复制所有数据 (%ld 行)", (long)dataSource.count]];
}

- (NSTableView*)getActiveTableView
{
    if ([self.tabView.selectedTabViewItem.identifier isEqualToString:@"windows"]) {
        return self.windowTableView;
    } else {
        return self.classTableView;
    }
}

- (NSArray*)getDataSourceForTableView:(NSTableView*)tableView
{
    if (tableView == self.windowTableView) {
        return self.filteredWindowData;
    } else {
        return self.filteredClassData;
    }
}

- (NSString*)getContentForTableView:(NSTableView*)tableView row:(NSInteger)row column:(NSInteger)column
{
    if (row < 0 || column < 0) {
        return @"";
    }

    NSTableColumn* tableColumn = tableView.tableColumns[column];
    NSString* identifier = tableColumn.identifier;

    if (tableView == self.windowTableView) {
        if (row >= self.filteredWindowData.count)
            return @"";
        WindowInfo* info = self.filteredWindowData[row];

        if ([identifier isEqualToString:@"windowClass"]) {
            return info.windowClass ?: @"";
        } else if ([identifier isEqualToString:@"controller"]) {
            return info.controllerClass ?: @"";
        } else if ([identifier isEqualToString:@"title"]) {
            return info.title ?: @"";
        } else if ([identifier isEqualToString:@"module"]) {
            return info.module ?: @"";
        }
    } else {
        if (row >= self.filteredClassData.count)
            return @"";
        ClassInfo* info = self.filteredClassData[row];

        if ([identifier isEqualToString:@"className"]) {
            return info.className ?: @"";
        } else if ([identifier isEqualToString:@"properties"]) {
            return [@(info.properties.count) stringValue];
        } else if ([identifier isEqualToString:@"methods"]) {
            return [@(info.methods.count) stringValue];
        } else if ([identifier isEqualToString:@"details"]) {
            return [info formattedDetailsString] ?: @"";
        } else if ([identifier isEqualToString:@"module"]) {
            return info.module ?: @"";
        }
    }

    return @"";
}

- (void)copyToClipboard:(NSString*)content
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:content forType:NSPasteboardTypeString];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier>*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ @"refresh", @"export", @"settings", @"search", @"clear", NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier ];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ @"search", NSToolbarFlexibleSpaceItemIdentifier, @"export", @"settings", NSToolbarSpaceItemIdentifier, @"refresh", @"clear" ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ([itemIdentifier isEqualToString:@"refresh"]) {
        item.label = @"刷新";
        item.paletteLabel = @"刷新数据";
        item.toolTip = @"刷新窗口和类信息";
        item.image = [NSImage imageWithSystemSymbolName:@"arrow.clockwise" accessibilityDescription:@"刷新"];
        item.target = self;
        item.action = @selector(refreshData:);

    } else if ([itemIdentifier isEqualToString:@"export"]) {
        item.label = @"导出";
        item.paletteLabel = @"导出数据";
        item.toolTip = @"导出当前数据到文件";
        item.image = [NSImage imageWithSystemSymbolName:@"square.and.arrow.up" accessibilityDescription:@"导出"];
        item.target = self;
        item.action = @selector(exportData:);

    } else if ([itemIdentifier isEqualToString:@"settings"]) {
        item.label = @"设置";
        item.paletteLabel = @"Inspector设置";
        item.toolTip = @"打开设置菜单";
        item.image = [NSImage imageWithSystemSymbolName:@"gear" accessibilityDescription:@"设置"];
        item.target = self;
        item.action = @selector(showSettings:);

    } else if ([itemIdentifier isEqualToString:@"search"]) {
        item.label = @"搜索";
        item.paletteLabel = @"搜索";
        item.view = self.searchField;

    } else if ([itemIdentifier isEqualToString:@"clear"]) {
        item.label = @"清空";
        item.paletteLabel = @"清空缓存";
        item.toolTip = @"清空已加载的数据";
        item.image = [NSImage imageWithSystemSymbolName:@"trash" accessibilityDescription:@"清空"];
        item.target = self;
        item.action = @selector(clearCache:);
    }

    return item;
}

#pragma mark - 数据加载

- (void)loadData
{
    [self loadWindowInfo];
    [self loadClassInfo];
    [self updateFilteredData];
}

- (void)loadWindowInfo
{
    self.windowInfoData = [NSMutableArray array];

    // 获取所有应用窗口
    NSArray* windows = [NSApp windows];

    for (NSWindow* window in windows) {
        if (window != self.window) { // 排除Inspector自己的窗口
            [self analyzeWindow:window level:0];
        }
    }
}

- (NSString*)getModuleForClass:(Class)cls
{
    if (!cls) return @"N/A";
    
    // 获取类的镜像信息
    const char* imageName = class_getImageName(cls);
    if (imageName) {
        NSString* imageNameStr = [NSString stringWithUTF8String:imageName];
        // 提取模块名（去除路径，只保留文件名）
        NSString* moduleName = [imageNameStr lastPathComponent];
        // 去除扩展名
        moduleName = [moduleName stringByDeletingPathExtension];
        return moduleName;
    }
    
    return @"N/A";
}
- (void)analyzeWindow:(NSWindow*)window level:(NSInteger)level
{
    if (!window)
        return;

    WindowInfo* info = [[WindowInfo alloc] init];
    info.windowClass = NSStringFromClass([window class]);
    info.level = level;
    info.title = window.title ?: @"";
    info.identifier = window.identifier ?: @"";
    info.module = [self getModuleForClass:[window class]]; // 新增


    // 获取窗口控制器信息
    if (window.windowController) {
        info.controllerClass = NSStringFromClass([window.windowController class]);
    } else {
        info.controllerClass = @"N/A";
    }

    [self.windowInfoData addObject:info];

    // 分析窗口的内容视图
    if (window.contentView) {
        [self analyzeView:window.contentView level:level + 1 windowInfo:info];
    }
}

- (void)analyzeView:(NSView*)view level:(NSInteger)level windowInfo:(WindowInfo*)windowInfo
{
    if (!view)
        return;

    WindowInfo* info = [[WindowInfo alloc] init];
    info.windowClass = NSStringFromClass([view class]);
    info.level = level;
    info.controllerClass = windowInfo.controllerClass;
    info.module = [self getModuleForClass:[view class]];

    // 获取视图标题信息
    if ([view respondsToSelector:@selector(stringValue)]) {
        NSString* stringValue = [view performSelector:@selector(stringValue)];
        info.title = stringValue ?: @"";
    } else if ([view respondsToSelector:@selector(title)]) {
        NSString* title = [view performSelector:@selector(title)];
        info.title = title ?: @"";
    } else {
        info.title = @"";
    }

    [self.windowInfoData addObject:info];

    // 递归分析子视图
    for (NSView* subview in view.subviews) {
        [self analyzeView:subview level:level + 1 windowInfo:windowInfo];
    }
}

- (void)loadClassInfo
{
    self.classInfoData = [NSMutableArray array];

    unsigned int classCount;
    Class* classes = objc_copyClassList(&classCount);

    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        const char* className = class_getName(cls);
        NSString* classNameString = [NSString stringWithUTF8String:className];

        // 过滤系统类
        if ([self isCustomClass:classNameString]) {
            ClassInfo* info = [[ClassInfo alloc] init];
            info.className = classNameString;
            info.properties = [self getPropertiesForClass:cls];
            info.methods = [self getMethodsForClass:cls];
            info.isExpanded = NO;
            info.module = [self getModuleForClass:cls];
            [self.classInfoData addObject:info];
        }
    }

    free(classes);

    // 按类名排序
    [self.classInfoData sortUsingComparator:^NSComparisonResult(ClassInfo* obj1, ClassInfo* obj2) {
        return [obj1.className compare:obj2.className];
    }];
}

- (BOOL)isCustomClass:(NSString*)className
{
    // 过滤明显的系统类
    NSArray* systemPrefixes = @[ @"NS", @"CF", @"CG", @"CA", @"_", @"__",
        @"Swift", @"Foundation", @"AppKit", @"CoreFoundation",
        @"WebKit", @"AVFoundation", @"QuartzCore" ];

    for (NSString* prefix in systemPrefixes) {
        if ([className hasPrefix:prefix]) {
            return NO;
        }
    }

    // 包含应用包名的类通常是自定义类
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier && [className containsString:bundleIdentifier]) {
        return YES;
    }

    // 其他启发式判断
    return ![className containsString:@"$"] && // Swift mangled names
        ![className hasPrefix:@"OS"] && ![className hasPrefix:@"_"];
}

- (NSArray*)getPropertiesForClass:(Class)cls
{
    NSMutableArray* properties = [NSMutableArray array];

    unsigned int propertyCount;
    objc_property_t* propertyList = class_copyPropertyList(cls, &propertyCount);

    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = propertyList[i];
        const char* propertyName = property_getName(property);
        const char* propertyAttributes = property_getAttributes(property);

        NSString* propertyInfo = [NSString stringWithFormat:@"%s (%s)",
            propertyName, propertyAttributes];
        [properties addObject:propertyInfo];
    }

    free(propertyList);
    return [properties copy];
}

- (NSArray*)getMethodsForClass:(Class)cls
{
    NSMutableArray* methods = [NSMutableArray array];

    unsigned int methodCount;
    Method* methodList = class_copyMethodList(cls, &methodCount);

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        SEL selector = method_getName(method);
        const char* methodName = sel_getName(selector);

        char* returnType = method_copyReturnType(method);
        unsigned int argumentCount = method_getNumberOfArguments(method);

        NSMutableString* methodSignature = [NSMutableString stringWithFormat:@"(%s) %s",
            returnType, methodName];

        // 添加参数类型信息
        for (unsigned int j = 2; j < argumentCount; j++) { // 跳过self和_cmd
            char* argumentType = method_copyArgumentType(method, j);
            [methodSignature appendFormat:@" arg%u:(%s)", j - 2, argumentType];
            free(argumentType);
        }

        [methods addObject:[methodSignature copy]];
        free(returnType);
    }

    free(methodList);
    return [methods copy];
}

- (void)updateFilteredData
{
    NSString* searchText = self.searchField.stringValue;

    if (searchText.length == 0) {
        self.filteredWindowData = [self.windowInfoData mutableCopy];
        self.filteredClassData = [self.classInfoData mutableCopy];
    } else {
        // 过滤窗口数据
        NSPredicate* windowPredicate = [NSPredicate predicateWithFormat:@"windowClass CONTAINS[cd] %@ OR controllerClass CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR module CONTAINS[cd] %@", searchText, searchText, searchText, searchText];
        self.filteredWindowData = [[self.windowInfoData filteredArrayUsingPredicate:windowPredicate] mutableCopy];

        // 过滤类数据
        NSPredicate* classPredicate = [NSPredicate predicateWithFormat:@"className CONTAINS[cd] %@ OR module CONTAINS[cd] %@", searchText, searchText];
        self.filteredClassData = [[self.classInfoData filteredArrayUsingPredicate:classPredicate] mutableCopy];
    }

    [self.windowTableView reloadData];
    [self.classTableView reloadData];
}

#pragma mark - Actions

- (void)refreshData:(id)sender
{
    [self loadData];
    [self showNotification:@"数据已刷新"];
}

- (void)exportData:(id)sender
{
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    NSString* defaultName;
    if ([self.tabView.selectedTabViewItem.identifier  isEqual: @"windows"]) {
        defaultName = @"窗口结构信息.txt";
    } else {
        defaultName = @"类信息.txt";
    }
    savePanel.nameFieldStringValue = defaultName;

    [savePanel beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse result) {
                          if (result == NSModalResponseOK) {
                              [self exportDataToURL:savePanel.URL];
                          }
                      }];
}

- (void)exportDataToURL:(NSURL*)url
{
    NSString* dataString;

    if ([self.tabView.selectedTabViewItem.identifier isEqualToString:@"windows"]) {
        // 导出窗口信息
        NSMutableString* windowData = [NSMutableString stringWithString:@"=== macOS 窗口结构信息 ===\n\n"];

        for (WindowInfo* info in self.filteredWindowData) {
            NSString* indent = [@"" stringByPaddingToLength:info.level * 2 withString:@" " startingAtIndex:0];
            [windowData appendFormat:@"%@%@\n", indent, info.windowClass];
            [windowData appendFormat:@"%@  Controller: %@\n", indent, info.controllerClass];
            [windowData appendFormat:@"%@  Title: %@\n", indent, info.title];
            if (info.identifier.length > 0) {
                [windowData appendFormat:@"%@  Identifier: %@\n", indent, info.identifier];
            }
            [windowData appendString:@"\n"];
        }

        dataString = windowData;
    } else {
        // 导出类信息
        NSMutableString* classData = [NSMutableString stringWithString:@"=== macOS 类信息 ===\n\n"];

        for (ClassInfo* info in self.filteredClassData) {
            [classData appendFormat:@"Class: %@\n", info.className];

            [classData appendString:@"Properties:\n"];
            for (NSString* property in info.properties) {
                [classData appendFormat:@"  %@\n", property];
            }

            [classData appendString:@"Methods:\n"];
            for (NSString* method in info.methods) {
                [classData appendFormat:@"  %@\n", method];
            }

            [classData appendString:@"\n---\n\n"];
        }

        dataString = classData;
    }

    NSError* error;
    [dataString writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        [self showAlert:@"导出失败" message:error.localizedDescription];
    } else {
        [self showNotification:@"数据导出成功"];
    }
}

- (void)showSettings:(id)sender
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"Inspector 设置";
    alert.informativeText = @"选择一个操作:";

    [alert addButtonWithTitle:self.autoRefreshEnabled ? @"关闭自动刷新" : @"开启自动刷新"];
    [alert addButtonWithTitle:@"清空"];
    [alert addButtonWithTitle:@"关于"];
    [alert addButtonWithTitle:@"取消"];

    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      switch (returnCode) {
                      case NSAlertFirstButtonReturn:
                          [self toggleAutoRefresh];
                          break;
                      case NSAlertSecondButtonReturn:
                          [self clearCache:nil];
                          break;
                      case NSAlertThirdButtonReturn:
                          [self showAbout];
                          break;
                      default:
                          break;
                      }
                  }];
}

- (void)toggleAutoRefresh
{
    self.autoRefreshEnabled = !self.autoRefreshEnabled;

    if (self.autoRefreshEnabled) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                             target:self
                                                           selector:@selector(autoRefreshData)
                                                           userInfo:nil
                                                            repeats:YES];
        [self showNotification:@"自动刷新已开启"];
    } else {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        [self showNotification:@"自动刷新已关闭"];
    }
}

- (void)autoRefreshData
{
    // 只刷新窗口信息
    if ([self.tabView.selectedTabViewItem.identifier isEqualToString:@"windows"]) {
        [self loadWindowInfo];
        [self updateFilteredData];
    }
}

- (void)clearCache:(id)sender
{
    [self.windowInfoData removeAllObjects];
    [self.classInfoData removeAllObjects];
    [self updateFilteredData];
    [self showNotification:@"缓存已清除"];
}

- (void)showAbout
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"关于 macOS App Inspector";
    alert.informativeText = @"macOS App Inspector v1.0\n\n"
                            @"功能特性:\n"
                            @"• macOS 窗口结构分析\n"
                            @"• 类信息查看\n"
                            @"• 实时搜索过滤\n"
                            @"• 数据导出\n"
                            @"• 自动刷新\n"
                            @"• 右键复制功能\n\n"
                            @"用于 macOS 应用逆向工程和调试";

    [alert addButtonWithTitle:@"确定"];
    [alert runModal];
}

- (void)searchTextChanged:(id)sender
{
    [self updateFilteredData];
}

- (void)showNotification:(NSString*)message
{
//    if (@available(macOS 10.14, *)) {
//            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
//            content.title = @"App Inspector";
//            content.body = message;
//
//            UNNotificationRequest *request =
//                [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
//                                                     content:content
//                                                     trigger:nil]; // 立即触发
//
//            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//            [center addNotificationRequest:request withCompletionHandler:nil];
//    } else {
//        // 兼容旧版本
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//        NSUserNotification *notification = [[NSUserNotification alloc] init];
//        notification.title = @"App Inspector";
//        notification.informativeText = message;
//        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
//#pragma clang diagnostic pop
//    }
}

- (void)showAlert:(NSString*)title message:(NSString*)message
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"确定"];
    [alert runModal];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    if (tableView == self.windowTableView) {
        return self.filteredWindowData.count;
    } else {
        return self.filteredClassData.count;
    }
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    if (tableView == self.windowTableView) {
        WindowInfo* info = self.filteredWindowData[row];
        NSString* identifier = tableColumn.identifier;

        if ([identifier isEqualToString:@"windowClass"]) {
            NSString* indent = [@"" stringByPaddingToLength:info.level * 2 withString:@"  " startingAtIndex:0];
            return [NSString stringWithFormat:@"%@%@", indent, info.windowClass];
        } else if ([identifier isEqualToString:@"controller"]) {
            return info.controllerClass;
        } else if ([identifier isEqualToString:@"title"]) {
            return info.title;
        } else if ([identifier isEqualToString:@"module"]) {
            return info.module;
        }

    } else {
        ClassInfo* info = self.filteredClassData[row];
        NSString* identifier = tableColumn.identifier;

        if ([identifier isEqualToString:@"className"]) {
            return info.className;
        } else if ([identifier isEqualToString:@"properties"]) {
            return @(info.properties.count);
        } else if ([identifier isEqualToString:@"methods"]) {
            return @(info.methods.count);
        } else if ([identifier isEqualToString:@"details"]) {
            return nil; // 将通过自定义视图提供内容
        } else if ([identifier isEqualToString:@"module"]) {
            return info.module;
        }
    }

    return @"";
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification*)notification
{
    NSTableView* tableView = notification.object;

    if (tableView == self.classTableView && tableView.selectedRow >= 0) {
        // 移除对 showClassDetails: 的调用
    }
}

- (NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    // For classTableView
    if (tableView == self.classTableView) {
        ClassInfo* info = self.filteredClassData[row];
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        if (!cellView) {
            cellView = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
            cellView.identifier = tableColumn.identifier;
            // Add a text field to the cellView for general content
            NSTextField* textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.editable = NO;
            textField.selectable = NO;
            textField.bordered = NO;
            textField.drawsBackground = NO;
            cellView.textField = textField; // Assign to textField property
            [cellView addSubview:textField];
            [NSLayoutConstraint activateConstraints:@[
                [textField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor
                                                        constant:5],
                [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor
                                                         constant:-5],
                [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
            ]];
        }

        if ([tableColumn.identifier isEqualToString:@"details"]) {
            // Clear existing subviews to prevent duplication on reuse
            for (NSView* subview in cellView.subviews) {
                if (subview != cellView.textField) { // Keep the main textField if it exists
                    [subview removeFromSuperview];
                }
            }
            // Ensure the text field is removed if this cellView was previously used for other columns
            if (cellView.textField.superview) {
                [cellView.textField removeFromSuperview];
            }

            // Add a button to toggle expansion
            NSButton* expandButton = [NSButton buttonWithTitle:(info.isExpanded ? @"点击收起" : @"点击展开查看详情") target:self action:@selector(toggleExpansion:)];
            expandButton.tag = row; // Use tag to identify the row
            expandButton.translatesAutoresizingMaskIntoConstraints = NO;
            [cellView addSubview:expandButton];

            [NSLayoutConstraint activateConstraints:@[
                [expandButton.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor
                                                           constant:5],
                [expandButton.topAnchor constraintEqualToAnchor:cellView.topAnchor
                                                       constant:2]
            ]];

            if (info.isExpanded) {
                NSTextField* detailsField = [[NSTextField alloc] initWithFrame:NSZeroRect];
                detailsField.editable = NO;
                detailsField.selectable = YES;
                detailsField.bordered = NO;
                detailsField.drawsBackground = NO;
                detailsField.font = [NSFont systemFontOfSize:11];
                detailsField.stringValue = [info formattedDetailsString];
                detailsField.translatesAutoresizingMaskIntoConstraints = NO;
                detailsField.maximumNumberOfLines = 0; // Allow multiple lines

                [cellView addSubview:detailsField];

                [NSLayoutConstraint activateConstraints:@[
                    [detailsField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor
                                                               constant:5],
                    [detailsField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor
                                                                constant:-5],
                    [detailsField.topAnchor constraintEqualToAnchor:expandButton.bottomAnchor
                                                           constant:5],
                    [detailsField.bottomAnchor constraintEqualToAnchor:cellView.bottomAnchor
                                                              constant:-5]
                ]];
            }
        } else {
            // For other columns, set the text field value
            if (!cellView.textField.superview) { // Ensure textField is added back if it was removed for 'details'
                [cellView addSubview:cellView.textField];
                [NSLayoutConstraint activateConstraints:@[
                    [cellView.textField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor
                                                                     constant:5],
                    [cellView.textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor
                                                                      constant:-5],
                    [cellView.textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
                ]];
            }
            if ([tableColumn.identifier isEqualToString:@"className"]) {
                cellView.textField.stringValue = info.className;
            } else if ([tableColumn.identifier isEqualToString:@"properties"]) {
                cellView.textField.stringValue = [@(info.properties.count) stringValue];
            } else if ([tableColumn.identifier isEqualToString:@"methods"]) {
                cellView.textField.stringValue = [@(info.methods.count) stringValue];
            } else if ([tableColumn.identifier isEqualToString:@"module"]) {
                cellView.textField.stringValue = info.module;
            }
            // Ensure the expandButton and detailsField are removed if this cellView was previously used for 'details'
            for (NSView* subview in cellView.subviews) {
                if (subview != cellView.textField) { // Keep the main textField
                    [subview removeFromSuperview];
                }
            }
        }
        return cellView;
    }
    // For windowTableView, use the default behavior
    else if (tableView == self.windowTableView) {
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        if (!cellView) {
            cellView = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
            cellView.identifier = tableColumn.identifier;
            NSTextField* textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.editable = NO;
            textField.selectable = NO;
            textField.bordered = NO;
            textField.drawsBackground = NO;
            cellView.textField = textField;
            [cellView addSubview:textField];
            [NSLayoutConstraint activateConstraints:@[
                [textField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor
                                                        constant:5],
                [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor
                                                         constant:-5],
                [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
            ]];
        }

        WindowInfo* info = self.filteredWindowData[row];
        NSString* identifier = tableColumn.identifier;

        if ([identifier isEqualToString:@"windowClass"]) {
            NSString* indent = [@"" stringByPaddingToLength:info.level * 2 withString:@"  " startingAtIndex:0];
            cellView.textField.stringValue = [NSString stringWithFormat:@"%@%@", indent, info.windowClass];
        } else if ([identifier isEqualToString:@"controller"]) {
            cellView.textField.stringValue = info.controllerClass;
        } else if ([identifier isEqualToString:@"title"]) {
            cellView.textField.stringValue = info.title;
        } else if ([identifier isEqualToString:@"module"]) {
            cellView.textField.stringValue = info.module;
        }
        return cellView;
    }
    return nil; // Should not reach here if all table views are handled
}

- (void)toggleExpansion:(NSButton*)sender
{
    NSInteger row = sender.tag;
    if (row >= 0 && row < self.filteredClassData.count) {
        ClassInfo* info = self.filteredClassData[row];
        info.isExpanded = !info.isExpanded;
        [self.classTableView reloadData]; // Reload to update row height and content
    }
}

- (CGFloat)tableView:(NSTableView*)tableView heightOfRow:(NSInteger)row
{
    if (tableView == self.classTableView) {
        ClassInfo* info = self.filteredClassData[row];
        if (info.isExpanded) {
            // Calculate height for expanded content
            NSString* detailsString = [info formattedDetailsString];
            NSFont* font = [NSFont systemFontOfSize:11];
            // Assuming a fixed width for the details text field (e.g., column width - padding)
            // The 'details' column width is 250, let's use 240 for text width
            CGFloat textWidth = 240;

            // Calculate the bounding box for the text
            NSRect textRect = [detailsString boundingRectWithSize:NSMakeSize(textWidth, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:@{ NSFontAttributeName : font }];

            // Base height for the button + padding + text height + bottom padding
            return 22 + 5 + textRect.size.height + 5; // Button height + padding + text height + bottom padding
        } else {
            // Default height for non-expanded row (just the button)
            return 22; // Standard row height for the button
        }
    }
    return [tableView rowHeight]; // Default row height for other tables
}

- (void)dealloc
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

@end

#pragma mark - Dylib Entry Point

static AppInspectorWindowController* inspectorController = nil;

@interface AppInspector : NSObject
+ (void)showInspector;
+ (void)hideInspector;
@end

@implementation AppInspector

+ (void)showInspector
{
    if (inspectorController)
        return;
    
    
    // 延迟启动以确保应用完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        inspectorController = [[AppInspectorWindowController alloc] init];
        [inspectorController showWindow:nil];

        // 确保窗口显示在最前面
        [inspectorController.window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    });

    
}

+ (void)hideInspector
{
    if (inspectorController) {
        [inspectorController close];
        inspectorController = nil;
    }
}


@end
