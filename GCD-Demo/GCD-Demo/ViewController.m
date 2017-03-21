//
//  ViewController.m
//  GCD-Demo
//
//  Created by 张奇 on 2017/3/15.
//  Copyright © 2017年 ZoneLue. All rights reserved.
//

#import "ViewController.h"

typedef void(^Complete)(NSArray *dataArray,NSInteger index,BOOL isSuccess);
@interface ViewController ()

//@property (nonatomic ,strong) NSMutableArray *photosArray;//替换前
@property (nonatomic,strong,readonly) NSMutableArray *photosArray;//替换后
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    GCD基本使用
    
    /*
     *  描述说明
     queue      队列
     main       主队列
     global     全局队列
     dispatch_queue_t	描述队列
     dispatch_block_t	描述任务
     dispatch_once_t	描述一次性
     dispatch_time_t	描述时间
     dispatch_group_t	描述队列组
     dispatch_semaphore_t	描述信号量
     
     */
    
    /*
     *  函数说明
     dispatch_sync()	同步执行
     dispatch_async()	异步执行
     dispatch_after()	延时执行
     dispatch_once()	一次性执行
     dispatch_apply()	提交队列
     dispatch_queue_create()	创建队列
     dispatch_group_create()	创建队列组
     dispatch_group_async()     提交任务到队列组
     dispatch_group_enter() / dispatch_group_leave()  将队列组中的任务未执行完毕的任务数目加减1(两个函数要配合使用)
     dispatch_group_notify()	监听队列组执行完毕
     dispatch_group_wait()      设置等待时间(返回 0成功,1失败)

     */
    
    //获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    //使用dispatch_get_global_queue()获取全局并发队列,第一个参数是队列优先级,第二个参数传0
    dispatch_queue_t otherQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    /** 
      * 使用 dispatch_queue_create 初始化 concurrentQueue 为一个并发队列。
      * 第一个参数是队列标识；第二个参数指定你的队列是串行还是并发。设为NULL时默认是DISPATCH_QUEUE_SERIAL，将创建串行队列.
      * 在必要情况下，你可以将其设置为DISPATCH_QUEUE_CONCURRENT来创建自定义并行队列.
     */
    dispatch_queue_t myQueue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
    
    //同步函数,在当前线程执行(不开启新的线程)
    dispatch_sync(otherQueue, ^{
        NSLog(@"同步:%@",[NSThread currentThread]);
    });
    
    //异步函数,开启子线程执行
    dispatch_async(otherQueue, ^{
        NSLog(@"异步:%@",[NSThread currentThread]);
    });
    
}

#pragma mark 延时执行 dispatch_after()
/**
 * 延迟一段时间把一项任务提交到队列中执行，返回之后就不能取消
 * 常用来在在主队列上延迟执行一项任务
 */
- (IBAction)click_dispatch_after:(id)sender
{
    NSLog(@"当前线程 %@", [NSThread currentThread]);
    //GCD延时调用(主线程)(主队列)
    /**
     * 1.声明一个变量指定要延迟的时长
     * 2.等待 delayInSeconds 给定的时长，再异步地添加一个 Block 到主线程。
     */
    dispatch_time_t afterTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));//1
    
    dispatch_after(afterTime, dispatch_get_main_queue(), ^{//2
        NSLog(@"GCD延时调用(主线程):%@",[NSThread currentThread]);
    });
    
    //GCD延时调用(其他线程)(全局并发队列)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"GCD延时调用(其他线程):%@",[NSThread currentThread]);
    });
}

#pragma mark 队列
/**
 * 队列: 任务1,任务2依次执行,所有任务都执行成功后回到主线程,低效率
 * 把一项任务提交到队列中多次执行，具体是并行执行还是串行执行由队列本身决定.
 * dispatch_apply不会立刻返回，在执行完毕后才会返回，是同步的调用。
 */
- (IBAction)click_dispatch_queue:(id)sender
{
    //使用时注释其中之一使用
    NSLog(@"全局并发队列执行任务,当前线程:%@",[NSThread currentThread]);
    
    /*
     * 下面是一个关于在 dispatch_async 上如何以及何时使用不同的队列类型的快速指导：
    
     * 自定义串行队列：当你想串行执行后台任务并追踪它时就是一个好选择。这消除了资源争用，因为你知道一次只有一个任务在执行。注意若你需要来自某个方法的数据，你必须内联另一个 Block 来找回它或考虑使用 dispatch_sync。
     * 主队列（串行）：这是在一个并发队列上完成任务后更新 UI 的共同选择。要这样做，你将在一个 Block 内部编写另一个 Block 。以及，如果你在主队列调用 dispatch_async 到主队列，你能确保这个新任务将在当前方法完成后的某个时间执行。
     * 并发队列：这是在后台执行非 UI 工作的共同选择。
     */
    //全局并发队列
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0; i < 3; i++) {
            NSLog(@"任务1,线程:%@",[NSThread currentThread]);
        }
        
        for (int i = 0; i < 3; i++) {
            NSLog(@"任务2,线程:%@",[NSThread currentThread]);
        }
        
        for (int i = 0; i < 3; i++) {
            NSLog(@"任务3,线程:%@",[NSThread currentThread]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"任务全部完成,回到主线程操作:%@",[NSThread currentThread]);
        });
        
    });
    
    //队列组
    //任务1,任务2同时执行,所有任务都执行成功后回到主线程,高效率
    NSLog(@"队列组执行任务,当前线程:%@",[NSThread currentThread]);
    //1.创建队列组 dispatch_group_create()
    dispatch_group_t group = dispatch_group_create();
    
    //2.开启任务
    //开启任务1
    //提交任务到队列组 dispatch_group_async()
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 5; i++) {
            NSLog(@"任务1 :%@",[NSThread currentThread]);
        }
    });
    
    //开启任务2
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 5; i++) {
            NSLog(@"任务2 :%@",[NSThread currentThread]);
        }
    });
    
    //所有任务执行完毕,回到主线程进行操作
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"任务1,2执行完毕,回到主线程:%@",[NSThread currentThread]);
    });

}


#pragma mark 串行队列
/**
 *  一个任务执行完毕后，再执行下一个任务
 */
- (IBAction)click_dispatch_queue_creat:(id)sender
{
    // 1.使用 dispatch_queue_creat()创建串行队列
    
    /*
     创建串行队列

     @param label 队列名称
     @param attr  队列属性 一般传NULL
     @return dispatch_queue_t 队列
     */
    
    //dispatch_queue_create("serialQueue", NULL);
    
    dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", NULL);
    
    // 2.使用主队列
    // 主队列是GCD自带的一种特殊的串行队列,放在主队列中的任务,都会放到主线程中执行
    
    //异步函数,串行队列
    //开启新线程,串行执行任务
    NSLog(@"同步函数执行串行队列,当前线程:%@",[NSThread currentThread]);
    dispatch_async(serialQueue, ^{
        NSLog(@"任务1:%@",[NSThread currentThread]);
    });
    
    dispatch_async(serialQueue, ^{
        NSLog(@"任务2:%@",[NSThread currentThread]);
    });
    
    dispatch_async(serialQueue, ^{
        NSLog(@"任务3:%@",[NSThread currentThread]);
    });
    
    //同步函数,串行队列
    //不开启新线程,串行执行任务
    NSLog(@"异步函数执行串行队列,当前线程:%@",[NSThread currentThread]);
    
    dispatch_sync(serialQueue, ^{
        NSLog(@"任务1:%@",[NSThread currentThread]);
    });
    
    dispatch_sync(serialQueue, ^{
        NSLog(@"任务2:%@",[NSThread currentThread]);
    });
    
    dispatch_sync(serialQueue, ^{
        NSLog(@"任务3:%@",[NSThread currentThread]);
    });
    
}


#pragma mark 并发队列
/**
 *  多个任务并发执行（自动开启多个线程同时执行任务）
 *  并发功能只有在异步（dispatch_async）函数下才有效!!!
 */
- (IBAction)click_dispatch_get_global_queue:(id)sender
{
    // 1.使用dispatch_get_global_queue函数获得全局的并发队列
    
    
    /*
     获得全局并发队列

     @param identifier 优先级
     @param flags      无用参数 传0 
     @return dispatch_queue_t 队列
     */

    
    /* 
     * 优先级:
     * 高优先级   DISPATCH_QUEUE_PRIORITY_HIGH 2
     * 默认      DISPATCH_QUEUE_PRIORITY_DEFAULT 0
     * 低优先级   DISPATCH_QUEUE_PRIORITY_LOW (-2)
     * 后台      DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
     */
//    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //异步函数,并发队列
    //开启新线程,并发执行任务
    NSLog(@"异步函数执行并发队列,当前线程:%@",[NSThread currentThread]);
    dispatch_async(concurrentQueue, ^{
        NSLog(@"任务1:%@",[NSThread currentThread]);
    });
    
    dispatch_async(concurrentQueue, ^{
        NSLog(@"任务2:%@",[NSThread currentThread]);
    });
    
    dispatch_async(concurrentQueue, ^{
       NSLog(@"任务3:%@",[NSThread currentThread]);
    });
    
    //同步函数,并发队列
    //不会开启新线程,并发执行任务
    NSLog(@"同步函数执行并发队列,当前线程:%@",[NSThread currentThread]);
    dispatch_sync(concurrentQueue, ^{
        NSLog(@"任务1:%@",[NSThread currentThread]);
    });
    
    dispatch_sync(concurrentQueue, ^{
        NSLog(@"任务2:%@",[NSThread currentThread]);
    });
    
    dispatch_sync(concurrentQueue, ^{
        NSLog(@"任务3:%@",[NSThread currentThread]);
    });
    
}


#pragma mark 一次性执行:dispatch_once()
/**
 * 整个程序运行中,代码只会执行一次,适用于单例
 */
- (IBAction)click_dispatch_once:(id)sender
{
    /**
     * dispatch_once() 以线程安全的方式执行且仅执行其代码块一次。试图访问临界区（即传递给 dispatch_once 的代码）的不同的线程会在临界区已有一个线程的情况下被阻塞，直到临界区完成为止。
     * 但这只是让访问共享实例线程安全。它绝对没有让类本身线程安全。类中可能还有其它竞态条件，例如任何操纵内部数据的情况。
     */
    for (int i = 0 ; i < 100; i++) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"执行一次:%d",i);
        });
    }
}

#pragma mark 读者写者锁 dispatch_barrier_async()
/**
 * 读者写者锁（栅栏函数）
 * 在进程管理中起到一个栅栏的作用,它等待所有位于barrier函数之前的操作执行完毕后执行
 * 在barrier函数执行之后,barrier函数之后的操作才会得到执行
 */
- (IBAction)click_dispatch_barrier_async:(id)sender
{
    /**
     * 如果单例属性表示一个可变对象，那么你就需要考虑是否那个对象自身线程安全。
     * 如果问题中的这个对象是一个 Foundation 容器类，那么就很可能不安全！Apple 维护一个有用且有些心寒的列表：https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html，众多的 Foundation 类都不是线程安全的。
     * 常适用在自定义并发队列：这对于原子或临界区代码来说是极佳的选择。任何你在设置或实例化的需要线程安全的事物都是使用障碍的最佳候选。
     */
    
    //dispatch_barrier_async函数的作用
    // 1.实现高效率的数据库访问和文件访问
    // 2.避免数据竞争
    
    //该函数需要同dispatch_queue_create函数生成的concurrent Dispatch Queue队列一起使用
    dispatch_queue_t queue = dispatch_queue_create("barrier", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"任务1:%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务2:%@",[NSThread currentThread]);
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"---barrier---:%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务3:%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务4:%@",[NSThread currentThread]);
    });
    
}


#pragma mark - 这是一个 dispatch_once()和 dispatch_barrier_async()函数的使用场景
+ (instancetype)sharedManager
{
    static ViewController *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ViewController alloc] init];
        sharedManager->_photosArray = [NSMutableArray array];
        //使用 dispatch_queue_create 初始化 concurrentQueue 为一个并发队列。第一个参数是队列名；第二个参数指定你的队列是串行还是并发。
        sharedManager->_concurrentQueue = dispatch_queue_create("concurrentQueue",DISPATCH_QUEUE_CONCURRENT);
    });
    return sharedManager;
}

- (NSArray *)photos
{
    /**
     * 关于在何时以及何处使用 dispatch_sync ：
     
     * 自定义串行队列：在这个状况下要非常小心！如果你正运行在一个队列并调用 dispatch_sync 放在同一个队列，那就百分百地创建了一个死锁。
     * 主队列（串行）：同上面的理由一样，必须非常小心！这个状况同样有潜在的导致死锁的情况。
     * 并发队列：这才是做同步工作的最佳选择，不论是通过调度障碍，或者需要等待一个任务完成才能执行进一步处理的情况。
     */
    
    __block NSArray *array;
    //在 concurrentPhotoQueue 上同步调度来执行读操作。
    dispatch_sync(self.concurrentQueue, ^{
        array = [NSArray arrayWithArray:_photosArray];
    });
    return array;
}

- (void)addPhoto:(NSString *)photo
{
    /**
     * 1.添加写操作到你的自定义队列。当临界区在稍后执行时，这将是你队列中唯一执行的条目。
     * 2.障碍Block，这个Block永远不会同时和其它Block一起在 concurrentPhotoQueue 中执行
     * 3.发送一个通知说明完成了障碍操作。这个通知将在主线程被发送做一些UI处理，所以在此为了通知，异步地调度另一个任务到主线程。
     */
    if (photo) {
        dispatch_barrier_async(self.concurrentQueue, ^{//1
            [_photosArray addObject:photo];//2
            
            dispatch_async(dispatch_get_main_queue(), ^{//3
                NSLog(@"主线程更新UI：%@",photo);
            });
        });
    }
}


#pragma mark - Dispatch Groups(调度组)
/**
 * 解决对多个异步任务的完成进行监控的问题(同时发起多个网络请求等...)
 */
- (IBAction)requestForData:(id)sender
{
    /**
     * 1.创建一个新的 Dispatch Group，它相当于一个用来记录未完成任务的计数器。
     * 2.dispatch_group_enter,手动通知 Dispatch Group 任务已经开始
     * 3.dispatch_group_leave,手动通知 Dispatch Group 任务已经完成
     * 4.dispatch_group_notify 以异步的方式工作。当 Dispatch Group 中没有任何任务时，它就会执行。
     * 必须保证 dispatch_group_enter 和 dispatch_group_leave 成对出现，确保进入 Group 的次数和离开 Group 的次数相等。
     */

    __block NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:0];
    __block NSMutableDictionary *successDic = [NSMutableDictionary dictionaryWithCapacity:0];

    dispatch_group_t requestGroup = dispatch_group_create();//1
    
    for(NSInteger i=1 ; i<4 ;i++)
    {
        dispatch_group_enter(requestGroup);//2
        [self requestForDataWithIndex:i block:^(NSArray *dataArray, NSInteger index, BOOL isSuccess) {
            if (isSuccess) {
                NSLog(@"第%ld个网络请求成功，返回参数是:%@",(long)index,dataArray);
                [successDic setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
            }else{
                NSLog(@"第%ld个网络请求失败，返回参数是:%@",(long)index,dataArray);
                [errDict setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
            }
            dispatch_group_leave(requestGroup);//3
        }];
        
    }
    dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{//4
        //请求完成，主线程操作
        NSLog(@"请求全部完成，成功数据:%@,失败数据:%@",successDic,errDict);
    });
    
}

#pragma mark - dispatch_apply()
//用dispatch_apply()提交队列
- (IBAction)requestForData_Dispatch_apply:(id)sender
{
    /**
     dispatch_apply() 适用于并发循环

     @param iterations 迭代的次数
     @param queue 指定任务运行的队列
     @param size_t Block
     */
//    dispatch_apply(size_t iterations, dispatch_queue_t  _Nonnull queue, ^(size_t) {})

    __block NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:0];
    __block NSMutableDictionary *successDic = [NSMutableDictionary dictionaryWithCapacity:0];
    dispatch_group_t requestGroup = dispatch_group_create();
    dispatch_apply(3, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        dispatch_group_enter(requestGroup);
        [self requestForDataWithIndex:i block:^(NSArray *dataArray, NSInteger index, BOOL isSuccess) {
            if (isSuccess) {
                NSLog(@"第%ld个网络请求成功，返回参数是:%@",(long)index,dataArray);
                [successDic setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
            }
            else
            {
                NSLog(@"第%ld个网络请求失败，返回参数是:%@",(long)index,dataArray);
                [errDict setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
            }
            dispatch_group_leave(requestGroup);
        }];

    });
    dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
        //请求完成，主线程操作
        NSLog(@"请求全部完成，成功数据:%@,失败数据:%@",successDic,errDict);
    });
    
}

#pragma mark - dispatch_semaphore_t  信号量
- (IBAction)requestForData_Dispatch_semaphore_t:(id)sender
{
 
    /**
     * 信号量
     * 相当于一个停车场,创建时的参数相当于提供多少个车位,如果你有两个车位,有4辆车要停,那么,只能让先进来的两个车子停下,后面的两个车子等待,开走一个,才能停入下一个.dispatch_semaphore_wait函数就相当于来了一辆车,调用一次,车位就-1.dispatch_semaphore_signal函数相当于走了一辆车,调用一次,车位就+1.
     */
    
    /**
     * 信号量为0时 会阻塞线程，一直等待
     * 1.dispatch_semaphore_wait(信号量,等待时间)　这个函数会使传入的信号量的值-1;
     * 2.dispatch_semaphore_signal (信号量) 这个函数会使传入的信号量的值+1;
     * 正常的使用顺序是先降低然后再提高，这两个函数通常成对使用。
     */
    __block NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:0];
    __block NSMutableDictionary *successDic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    //创建一个信号量。参数指定信号量的起始值(必须大于0)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    for (NSInteger i=0; i<4; i++) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//-1
            [self requestForDataWithIndex:i block:^(NSArray *dataArray, NSInteger index, BOOL isSuccess) {
                if (isSuccess) {
                    NSLog(@"第%ld个网络请求成功，返回参数是:%@",(long)index,dataArray);
                    [successDic setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
                }
                else
                {
                    NSLog(@"第%ld个网络请求失败，返回参数是:%@",(long)index,dataArray);
                    [errDict setObject:dataArray forKey:[NSNumber numberWithInteger:index]];
                }
                dispatch_semaphore_signal(semaphore);//+1
            }];
            
        });
    }
}


//模拟网络请求
- (void)requestForDataWithIndex:(NSInteger)index block:(Complete)callback
{
    NSLog(@"发起第%ld个网络请求:%@",(long)index,[NSThread currentThread]);
    NSArray * successArray = [NSArray arrayWithObjects:@1, nil];
    NSArray * failureArray = [NSArray arrayWithObjects:@0, nil];
    if (index == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (callback) {
                callback(successArray,index,YES);
            }
        });
    }
    else if (index == 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (callback) {
                callback(successArray,index,YES);
            }
        });
    }
    else if (index == 2)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (callback) {
                callback(failureArray,index,NO);
            }
        });
    }
    else if (index == 3)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (callback) {
                callback(successArray,index,YES);
            }
        });
    }
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
