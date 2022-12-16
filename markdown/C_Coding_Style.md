# C语言编码规范说明文档

- *Author: Gao Lei*

## 1. Basics

- 单行字符数不宜太多, 太多时使用`\`换行。

## 2. Naming

- 变量/函数名应表明变量/函数的意图。
- 使用下划线分隔多个字母。
  eg. `multi_word_name`
- 大小写问题  
  (1) 变量/函数名使用小写字母；
  (2) 宏定义、枚举变量成员使用大写字母;
- 数组名应为**复数**名词。
- 长度相关变量的命名
  (1) 命名长度相关变量时，size表示字节数，length表示字符数;
  (2) 通常buffer对应size，string对应length;
  (3) string的长度不包括末尾的 ‘\0’ 终结符在内，但存储string的buffer包括。

## 3. Macros

- 除了用于log的函数以外，  
  尽量使用static inline来代替用宏定义的函数。
- 当宏定义包含多条语句时，使用`do { ... } while (0)`进行包裹；
  当宏定义包含运算时，使用 `()` 进行包裹。

eg.

```C
#define ngx_seaep_debug_enabled 0
#define NGX_SEAEP_DEBUG(format, ...)                                         \
    do {                                                                     \
        if (ngx_seaep_debug_enabled) {                                       \
            printf("[seaep] ");                                              \
            printf(format, ##__VA_ARGS__);                                   \
            printf("  |__ in [function]: %s, [line]: %d, by [process:%d] \n",\
                    __func__, __LINE__, getpid());                           \
        }                                                                    \
    } while (0)
```

## 4. Comments

- 使用`/* */`来添加说明性注释, 使用`//`来注释代码行;
- 代码文件里应尽量使用英文注释，避免使用中文;
  且注释尽量为完整的英文句子;
- 变量注释:
  (1) 重要的变量、结构体(struct)、共用体(union)都应在其前加以解释;
  (2) 结构体、共用体成员变量，都应在其右侧加以注释;
  (3) 结构体、共用体内属于不同处理逻辑的成员变量，应添加代码块区分。
eg.

```C
/* An event that will wake the following call to poll_block(). */
struct poll_waiter {
    /* Set when the waiter is created. */
    struct ovs_list node;       /* Element in global waiters list. */
    int fd;                     /* File descriptor. */
    short int events;           /* Events to wait for (POLLIN, POLLOUT). */
    poll_fd_func *function;     /* Callback function, if any, or null. */
    void *aux;                  /* Argument to callback function. */
    struct backtrace *backtrace; /* Event that created waiter, or null. */

    /* Set only when poll_block() is called. */
    struct pollfd *pollfd;      /* Pointer to element of the pollfds array
                                   (null if added from a callback). */
};
```

- 函数注释:
(1) 函数前的注释应表明函数的主要意图等核心要点;
    函数前的注释一般不需要说明函数的处理逻辑，对处理逻辑的说明主要依靠函数内部的注释。
(2) static定义的内部链接性的简单函数一般不需要注释，尽量通过函数名来表明此类函数意图;
(3) 对外接口类函数或叫复杂的函数, 其前的注释应包括对返回值、形参的说明;

## 5. Funtions

- 原型声明
(1) 所有non-static funtion都应在对应的.h文件中给出原型声明;
(2) static-funtion也应给出声明, 声明位置在.c文件**最前面**, 函数具体定义放在.c文件**最后面**。
(3) 函数原型声明中的参数名如果不起提示作用，应当删除。
eg.

```C
int netdev_get_mtu(const struct netdev *, int *mtup)
```

- 组织顺序
(1) static function 写在最下方
(2) non-static function应以top-down的逻辑顺序排序，
    low-level/fine-grained排在 high-level/coarse-grained函数的上方
(3) 函数的书写顺序应与原型声明顺序一致。

- 函数参数
(1) 函数参数的书写顺序按照如下组织:

> i. 主要的操作对象
> ii. 输入参数
> iii.输出参数
> iv.状态参数

(2)返回值

- 返回值及修饰符与函数名在声明时可同行, 定义时应换行
- 0用来表示成功处理; 正数用来设置errno
