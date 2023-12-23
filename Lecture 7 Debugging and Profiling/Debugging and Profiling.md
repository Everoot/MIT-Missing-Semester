# Debugging and Profiling

https://youtu.be/l812pUnKxME

A golden rule in programming is that code does not do what you expect it to do, but what you tell it to do. Bridging that gap can sometimes be a quite difficult feat. In this lecture we are going to cover useful techniques for dealing with buggy and resource hungry code: debugging and profiling.

> 代码不能完全按照您的想法运行，它只能完全按照您的写法运行，这是编程界的一条金科玉律。让您的写法符合您的想法是非常困难的。在这节课中，我们会传授给您一些非常有用技术，帮您处理代码中的 bug 和程序性能问题。

# Debugging

## Printf debugging and Logging

“The most effective debugging tool is still careful thought, coupled with judiciously placed print statements” — Brian Kernighan, *Unix for Beginners*.

> “最有效的 debug 工具就是细致的分析，配合恰当位置的打印语句” — Brian Kernighan, *Unix 新手入门*。

A first approach to debug a program is to add print statements around where you have detected the problem, and keep iterating until you have extracted enough information to understand what is responsible for the issue.

> 调试代码的第一种方法往往是在您发现问题的地方添加一些打印语句，然后不断重复此过程直到您获取了足够的信息并找到问题的根本原因。

A second approach is to use logging in your program, instead of ad hoc print statements. Logging is better than regular print statements for several reasons:

> 另外一个方法是使用日志，而不是临时添加打印语句。日志较普通的打印语句有如下的一些优势：

- You can log to files, sockets or even remote servers instead of standard output.

  > 您可以将日志写入文件、socket 或者甚至是发送到远端服务器而不仅仅是标准输出；

- Logging supports severity levels (such as INFO, DEBUG, WARN, ERROR, &c), that allow you to filter the output accordingly.

  > 日志可以支持严重等级（例如 INFO, DEBUG, WARN, ERROR等)，这使您可以根据需要过滤日志；

- For new issues, there’s a fair chance that your logs will contain enough information to detect what is going wrong.

  > 对于新发现的问题，很可能您的日志中已经包含了可以帮助您定位问题的足够的信息。

[Here](https://missing.csail.mit.edu/static/files/logger.py) is an example code that logs messages:

```shell
$ python logger.py
# Raw output as with just prints
$ python logger.py log
# Log formatted output
$ python logger.py log ERROR
# Print only ERROR levels and above
$ python logger.py color
# Color formatted output
```

><img src="./Debugging and Profiling/Screenshot 2023-12-18 at 03.07.43.png" alt="Screenshot 2023-12-18 at 03.07.43" />

One of my favorite tips for making logs more readable is to color code them. By now you probably have realized that your terminal uses colors to make things more readable. But how does it do it? Programs like `ls` or `grep` are using [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code), which are special sequences of characters to indicate your shell to change the color of the output. For example, executing `echo -e "\e[38;2;255;0;0mThis is red\e[0m"` prints the message `This is red` in red on your terminal, as long as it supports [true color](https://github.com/termstandard/colors#truecolor-support-in-output-devices). If your terminal doesn’t support this (e.g. macOS’s Terminal.app), you can use the more universally supported escape codes for 16 color choices, for example `echo -e "\e[31;1mThis is red\e[0m"`.

> 有很多技巧可以使日志的可读性变得更好，我最喜欢的一个是技巧是对其进行着色。到目前为止，您应该已经知道，以彩色文本显示终端信息时可读性更好。但是应该如何设置呢？`ls` 和 `grep` 这样的程序会使用 [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code)，它是一系列的特殊字符，可以使您的 shell 改变输出结果的颜色。例如，执行 `echo -e "\e[38;2;255;0;0mThis is red\e[0m"` 会打印红色的字符串：`This is red` 。只要您的终端支持[真彩色](https://gist.github.com/XVilka/8346728#terminals--true-color)。如果您的终端不支持真彩色（例如 MacOS 的 Terminal.app），您可以使用支持更加广泛的 16 色，例如：”\e[31;1mThis is red\e[0m”。

The following script shows how to print many RGB colors into your terminal (again, as long as it supports true color).

> 下面这个脚本向您展示了如何在终端中打印多种颜色（只要您的终端支持真彩色）

```shell
#!/usr/bin/env bash
for R in $(seq 0 20 255); do
    for G in $(seq 0 20 255); do
        for B in $(seq 0 20 255); do
            printf "\e[38;2;${R};${G};${B}m█\e[0m";
        done
    done
done
```

<img src="./Debugging and Profiling/Screenshot 2023-12-18 at 03.14.09.png" alt="Screenshot 2023-12-18 at 03.14.09" />

<img src="./Debugging and Profiling/Screenshot 2023-12-18 at 03.13.24.png" alt="Screenshot 2023-12-18 at 03.13.24" />







## Third party logs

As you start building larger software systems you will most probably run into dependencies that run as separate programs. Web servers, databases or message brokers are common examples of this kind of dependencies. When interacting with these systems it is often necessary to read their logs, since client side error messages might not suffice.

> 如果您正在构建大型软件系统，您很可能会使用到一些依赖，有些依赖会作为程序单独运行。如 Web 服务器、数据库或消息代理都是此类常见的第三方依赖。和这些系统交互的时候，阅读它们的日志是非常必要的，因为仅靠客户端侧的错误信息可能并不足以定位问题。

Luckily, most programs write their own logs somewhere in your system. In UNIX systems, it is commonplace for programs to write their logs under `/var/log`. For instance, the [NGINX](https://www.nginx.com/) webserver places its logs under `/var/log/nginx`. More recently, systems have started using a **system log**, which is increasingly where all of your log messages go. Most (but not all) Linux systems use `systemd`, a system daemon that controls many things in your system such as which services are enabled and running. `systemd` places the logs under `/var/log/journal` in a specialized format and you can use the [`journalctl`](https://www.man7.org/linux/man-pages/man1/journalctl.1.html) command to display the messages. Similarly, on macOS there is still `/var/log/system.log` but an increasing number of tools use the system log, that can be displayed with [`log show`](https://www.manpagez.com/man/1/log/). On most UNIX systems you can also use the [`dmesg`](https://www.man7.org/linux/man-pages/man1/dmesg.1.html) command to access the kernel log.

> 幸运的是，大多数的程序都会将日志保存在您的系统中的某个地方。对于 UNIX 系统来说，程序的日志通常存放在 `/var/log`。例如， [NGINX](https://www.nginx.com/) web 服务器就将其日志存放于`/var/log/nginx`。目前，系统开始使用 **system log**，您所有的日志都会保存在这里。大多数（但不是全部的）Linux 系统都会使用 `systemd`，这是一个系统守护进程，它会控制您系统中的很多东西，例如哪些服务应该启动并运行。`systemd` 会将日志以某种特殊格式存放于`/var/log/journal`，您可以使用 [`journalctl`](http://man7.org/linux/man-pages/man1/journalctl.1.html) 命令显示这些消息。类似地，在 macOS 系统中是 `/var/log/system.log`，但是有更多的工具会使用系统日志，它的内容可以使用 [`log show`](https://www.manpagez.com/man/1/log/) 显示。

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 12.44.33.png" alt="Screenshot 2023-12-18 at 12.44.33" />
>
> `brew install lnav`
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 12.46.42.png" alt="Screenshot 2023-12-18 at 12.46.42" />

For logging under the system logs you can use the [`logger`](https://www.man7.org/linux/man-pages/man1/logger.1.html) shell program. Here’s an example of using `logger` and how to check that the entry made it to the system logs. Moreover, most programming languages have bindings logging to the system log.

> 对于大多数的 UNIX 系统，您也可以使用[`dmesg`](http://man7.org/linux/man-pages/man1/dmesg.1.html) 命令来读取内核的日志。如果您希望将日志加入到系统日志中，您可以使用 [`logger`](http://man7.org/linux/man-pages/man1/logger.1.html) 这个 shell 程序。下面这个例子显示了如何使用 `logger`并且如何找到能够将其存入系统日志的条目。不仅如此，大多数的编程语言都支持向系统日志中写日志。

```shell
logger "Hello Logs"
# On macOS
log show --last 1m | grep Hello
# On Linux
journalctl --since "1m ago" | grep Hello
```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 12.55.45.png" alt="Screenshot 2023-12-18 at 12.55.45" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 12.55.54.png" alt="Screenshot 2023-12-18 at 12.55.54" />

As we saw in the data wrangling lecture, logs can be quite verbose and they require some level of processing and filtering to get the information you want. If you find yourself heavily filtering through `journalctl` and `log show` you can consider using their flags, which can perform a first pass of filtering of their output. There are also some tools like [`lnav`](http://lnav.org/), that provide an improved presentation and navigation for log files.

> 正如我们在数据整理那节课上看到的那样，日志的内容可以非常的多，我们需要对其进行处理和过滤才能得到我们想要的信息。如果您发现您需要对 `journalctl` 和 `log show` 的结果进行大量的过滤，那么此时可以考虑使用它们自带的选项对其结果先过滤一遍再输出。还有一些像 [`lnav`](http://lnav.org/) 这样的工具，它为日志文件提供了更好的展现和浏览方式。

## Debuggers

When printf debugging is not enough you should use a debugger. Debuggers are programs that let you interact with the execution of a program, allowing the following:

> 当通过打印已经不能满足您的调试需求时，您应该使用调试器。调试器是一种可以允许我们和正在执行的程序进行交互的程序，它可以做到：

- Halt execution of the program when it reaches a certain line.

  > 当到达某一行时将程序暂停；

- Step through the program one instruction at a time.

  > 一次一条指令地逐步执行程序

- Inspect values of variables after the program crashed.

  > 程序崩溃后查看变量的值

- Conditionally halt the execution when a given condition is met.

  > 满足特定条件时暂停程序

- And many more advanced features

  > 其他高级功能。

Many programming languages come with some form of debugger. In Python this is the Python Debugger [`pdb`](https://docs.python.org/3/library/pdb.html).

> 很多编程语言都有自己的调试器。Python 的调试器是[`pdb`](https://docs.python.org/3/library/pdb.html).

Here is a brief description of some of the commands `pdb` supports:

> 下面对`pdb` 支持的命令进行简单的介绍：

- **l**(ist) - Displays 11 lines around the current line or continue the previous listing.
- **s**(tep) - Execute the current line, stop at the first possible occasion.
- **n**(ext) - Continue execution until the next line in the current function is reached or it returns.
- **b**(reak) - Set a breakpoint (depending on the argument provided).
- **p**(rint) - Evaluate the expression in the current context and print its value. There’s also **pp** to display using [`pprint`](https://docs.python.org/3/library/pprint.html) instead.
- **r**(eturn) - Continue execution until the current function returns.
- **q**(uit) - Quit the debugger.

> - **l**(ist) - 显示当前行附近的11行或继续执行之前的显示；
> - **s**(tep) - 执行当前行，并在第一个可能的地方停止；
> - **n**(ext) - 继续执行直到当前函数的下一条语句或者 return 语句；
> - **b**(reak) - 设置断点（基于传入的参数）；
> - **p**(rint) - 在当前上下文对表达式求值并打印结果。还有一个命令是**pp** ，它使用 [`pprint`](https://docs.python.org/3/library/pprint.html) 打印；
> - **r**(eturn) - 继续执行直到当前函数返回；
> - **q**(uit) - 退出调试器。

Let’s go through an example of using `pdb` to fix the following buggy python code. (See the lecture video).

> 让我们使用`pdb` 来修复下面的 Python 代码（参考讲座视频）

```python
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(n):
            if arr[j] > arr[j+1]:
                arr[j] = arr[j+1]
                arr[j+1] = arr[j]
    return arr

print(bubble_sort([4, 2, 1, 8, 7, 6]))
```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.11.58.png" alt="Screenshot 2023-12-18 at 13.11.58" />

Note that since Python is an interpreted language we can use the `pdb` shell to execute commands and to execute instructions. [`ipdb`](https://pypi.org/project/ipdb/) is an improved `pdb` that uses the [`IPython`](https://ipython.org/) REPL enabling tab completion, syntax highlighting, better tracebacks, and better introspection while retaining the same interface as the `pdb` module.

> 注意，因为 Python 是一种解释型语言，所以我们可以通过 `pdb` shell 执行命令。 [`ipdb`](https://pypi.org/project/ipdb/) 是一种增强型的 `pdb` ，它使用[`IPython`](https://ipython.org/) 作为 REPL并开启了 tab 补全、语法高亮、更好的回溯和更好的内省，同时还保留了`pdb` 模块相同的接口。

> `pip3 install ipdb`
>
> 不可运行的话, 由于我有多个版本的python. 如下是成功安装后可运行的方式之一.
>
> ```shell
> $ which python3
> $ /opt/homebrew/bin/pip3 install ipdb
> ```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.21.22.png" alt="Screenshot 2023-12-18 at 13.21.22" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.22.58.png" alt="Screenshot 2023-12-18 at 13.22.58" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.23.33.png" alt="Screenshot 2023-12-18 at 13.23.33" />
>
> [1,1,1,6,6,6] 这不是我们想要的, 在交换的过程中肯定有什么地方又错了.
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.31.14.png" alt="Screenshot 2023-12-18 at 13.31.14" />
>
> 不能同时交换, 需要有个记录旧值, 然后再进行交换,不然就是会产生覆盖值的情况.

For more low level programming you will probably want to look into [`gdb`](https://www.gnu.org/software/gdb/) (and its quality of life modification [`pwndbg`](https://github.com/pwndbg/pwndbg)) and [`lldb`](https://lldb.llvm.org/). They are optimized for C-like language debugging but will let you probe pretty much any process and get its current machine state: registers, stack, program counter, &c.

> 对于更底层的编程语言，您可能需要了解一下 [`gdb`](https://www.gnu.org/software/gdb/) ( 以及它的改进版 [`pwndbg`](https://github.com/pwndbg/pwndbg)) 和 [`lldb`](https://lldb.llvm.org/)。它们都对类 C 语言的调试进行了优化，它允许您探索任意进程及其机器状态：寄存器、堆栈、程序计数器等。

> gdb mac 下不可用, 此处使用虚拟机ubuntu.
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.36.11.png" alt="Screenshot 2023-12-18 at 13.36.11" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.55.41.png" alt="Screenshot 2023-12-18 at 13.55.41" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 13.55.50.png" alt="Screenshot 2023-12-18 at 13.55.50" />
>
> 



## Specialized Tools

Even if what you are trying to debug is a black box binary there are tools that can help you with that. Whenever programs need to perform actions that only the kernel can, they use [System Calls](https://en.wikipedia.org/wiki/System_call). There are commands that let you trace the syscalls your program makes. In Linux there’s [`strace`](https://www.man7.org/linux/man-pages/man1/strace.1.html) and macOS and BSD have [`dtrace`](http://dtrace.org/blogs/about/). `dtrace` can be tricky to use because it uses its own `D` language, but there is a wrapper called [`dtruss`](https://www.manpagez.com/man/1/dtruss/) that provides an interface more similar to `strace` (more details [here](https://8thlight.com/blog/colin-jones/2015/11/06/dtrace-even-better-than-strace-for-osx.html)).

> 即使您需要调试的程序是一个二进制的黑盒程序，仍然有一些工具可以帮助到您。当您的程序需要执行一些只有操作系统内核才能完成的操作时，它需要使用 [系统调用](https://en.wikipedia.org/wiki/System_call)。有一些命令可以帮助您追踪您的程序执行的系统调用。在 Linux 中可以使用[`strace`](http://man7.org/linux/man-pages/man1/strace.1.html) ，在 macOS 和 BSD 中可以使用 [`dtrace`](http://dtrace.org/blogs/about/)。`dtrace` 用起来可能有些别扭，因为它使用的是它自有的 `D` 语言，但是我们可以使用一个叫做 [`dtruss`](https://www.manpagez.com/man/1/dtruss/) 的封装使其具有和 `strace` (更多信息参考 [这里](https://8thlight.com/blog/colin-jones/2015/11/06/dtrace-even-better-than-strace-for-osx.html))类似的接口

Below are some examples of using `strace` or `dtruss` to show [`stat`](https://www.man7.org/linux/man-pages/man2/stat.2.html) syscall traces for an execution of `ls`. For a deeper dive into `strace`, [this article](https://blogs.oracle.com/linux/strace-the-sysadmins-microscope-v2) and [this zine](https://jvns.ca/strace-zine-unfolded.pdf) are good reads.

> 下面的例子展现来如何使用 `strace` 或 `dtruss` 来显示`ls` 执行时，对[`stat`](http://man7.org/linux/man-pages/man2/stat.2.html) 系统调用进行追踪对结果。若需要深入了解 `strace`，[这篇文章](https://blogs.oracle.com/linux/strace-the-sysadmins-microscope-v2) 值得一读。

```shell
# On Linux
sudo strace -e lstat ls -l > /dev/null
# On macOS
sudo dtruss -t lstat64_extended ls -l > /dev/null
```

Under some circumstances, you may need to look at the network packets to figure out the issue in your program. Tools like [`tcpdump`](https://www.man7.org/linux/man-pages/man1/tcpdump.1.html) and [Wireshark](https://www.wireshark.org/) are network packet analyzers that let you read the contents of network packets and filter them based on different criteria.

> 有些情况下，我们需要查看网络数据包才能定位问题。像 [`tcpdump`](http://man7.org/linux/man-pages/man1/tcpdump.1.html) 和 [Wireshark](https://www.wireshark.org/) 这样的网络数据包分析工具可以帮助您获取网络数据包的内容并基于不同的条件进行过滤。

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 15.35.30.png" alt="Screenshot 2023-12-18 at 15.35.30" />
>
> `sudo strace -e lstat ls -l > /dev/null`
>
> `lstat` 是用来查看文件的属性
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 16.01.16.png" alt="Screenshot 2023-12-18 at 16.01.16" />

For web development, the Chrome/Firefox developer tools are quite handy. They feature a large number of tools, including:

> 对于 web 开发， Chrome/Firefox 的开发者工具非常方便，功能也很强大：

- Source code - Inspect the HTML/CSS/JS source code of any website.
- Live HTML, CSS, JS modification - Change the website content, styles and behavior to test (you can see for yourself that website screenshots are not valid proofs).
- Javascript shell - Execute commands in the JS REPL.
- Network - Analyze the requests timeline.
- Storage - Look into the Cookies and local application storage.

> - 源码 -查看任意站点的 HTML/CSS/JS 源码；
> - 实时地修改 HTML, CSS, JS 代码 - 修改网站的内容、样式和行为用于测试（从这一点您也能看出来，网页截图是不可靠的）；
> - Javascript shell - 在 JS REPL中执行命令；
> - 网络 - 分析请求的时间线；
> - 存储 - 查看 Cookies 和本地应用存储。



## Static Analysis

For some issues you do not need to run any code. For example, just by carefully looking at a piece of code you could realize that your loop variable is shadowing an already existing variable or function name; or that a program reads a variable before defining it. Here is where [static analysis](https://en.wikipedia.org/wiki/Static_program_analysis) tools come into play. Static analysis programs take source code as input and analyze it using coding rules to reason about its correctness.

> 有些问题是您不需要执行代码就能发现的。例如，仔细观察一段代码，您就能发现某个循环变量覆盖了某个已经存在的变量或函数名；或是有个变量在被读取之前并没有被定义。 这种情况下 [静态分析](https://en.wikipedia.org/wiki/Static_program_analysis) 工具就可以帮我们找到问题。静态分析会将程序的源码作为输入然后基于编码规则对其进行分析并对代码的正确性进行推理。

In the following Python snippet there are several mistakes. First, our loop variable `foo` shadows the previous definition of the function `foo`. We also wrote `baz` instead of `bar` in the last line, so the program will crash after completing the `sleep` call (which will take one minute).

> 下面这段 Python 代码中存在几个问题。 首先，我们的循环变量`foo` 覆盖了之前定义的函数`foo`。最后一行，我们还把 `bar` 错写成了`baz`，因此当程序完成`sleep` (一分钟)后，执行到这一行的时候便会崩溃。

```python
import time
def foo():
    return 42

for foo in range(5):
    print(foo)
bar = 1
bar *= 0.2
time.sleep(60)
print(baz)
```

Static analysis tools can identify these kinds of issues. When we run [`pyflakes`](https://pypi.org/project/pyflakes) on the code we get the errors related to both bugs. [`mypy`](http://mypy-lang.org/) is another tool that can detect type checking issues. Here, `mypy` will warn us that `bar` is initially an `int` and is then casted to a `float`. Again, note that all these issues were detected without having to run the code.

> 静态分析工具可以发现此类的问题。当我们使用[`pyflakes`](https://pypi.org/project/pyflakes) 分析代码的时候，我们会得到与这两处 bug 相关的错误信息。[`mypy`](http://mypy-lang.org/) 则是另外一个工具，它可以对代码进行类型检查。这里，`mypy` 会经过我们`bar` 起初是一个 `int` ，然后变成了 `float`。这些问题都可以在不运行代码的情况下被发现。

```shell
$ pyflakes foobar.py
foobar.py:6: redefinition of unused 'foo' from line 3
foobar.py:11: undefined name 'baz'

$ mypy foobar.py
foobar.py:6: error: Incompatible types in assignment (expression has type "int", variable has type "Callable[[], Any]")
foobar.py:9: error: Incompatible types in assignment (expression has type "float", variable has type "int")
foobar.py:11: error: Name 'baz' is not defined
Found 3 errors in 1 file (checked 1 source file)
```

> `pip3 install pyflakes`
>
> `pip3 install mypy`
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 16.15.20.png" alt="Screenshot 2023-12-18 at 16.15.20" />

In the shell tools lecture we covered [`shellcheck`](https://www.shellcheck.net/), which is a similar tool for shell scripts.

> 在 shell 工具那一节课的时候，我们介绍了 [`shellcheck`](https://www.shellcheck.net/)，这是一个类似的工具，但它是应用于 shell 脚本的。

Most editors and IDEs support displaying the output of these tools within the editor itself, highlighting the locations of warnings and errors. This is often called **code linting** and it can also be used to display other types of issues such as stylistic violations or insecure constructs.

> 大多数的编辑器和 IDE 都支持在编辑界面显示这些工具的分析结果、高亮有警告和错误的位置。 这个过程通常称为 **code linting** 。风格检查或安全检查的结果同样也可以进行相应的显示。

In vim, the plugins [`ale`](https://vimawesome.com/plugin/ale) or [`syntastic`](https://vimawesome.com/plugin/syntastic) will let you do that. For Python, [`pylint`](https://github.com/PyCQA/pylint) and [`pep8`](https://pypi.org/project/pep8/) are examples of stylistic linters and [`bandit`](https://pypi.org/project/bandit/) is a tool designed to find common security issues. For other languages people have compiled comprehensive lists of useful static analysis tools, such as [Awesome Static Analysis](https://github.com/mre/awesome-static-analysis) (you may want to take a look at the *Writing* section) and for linters there is [Awesome Linters](https://github.com/caramelomartins/awesome-linters).

> 在 vim 中，有 [`ale`](https://vimawesome.com/plugin/ale) 或 [`syntastic`](https://vimawesome.com/plugin/syntastic) 可以帮助您做同样的事情。 在 Python 中， [`pylint`](https://www.pylint.org/) 和 [`pep8`](https://pypi.org/project/pep8/) 是两种用于进行风格检查的工具，而 [`bandit`](https://pypi.org/project/bandit/) 工具则用于检查安全相关的问题。对于其他语言的开发者来说，静态分析工具可以参考这个列表：[Awesome Static Analysis](https://github.com/mre/awesome-static-analysis) (您也许会对 *Writing* 一节感兴趣) 。对于 linters 则可以参考这个列表： [Awesome Linters](https://github.com/caramelomartins/awesome-linters)。

A complementary tool to stylistic linting are code formatters such as [`black`](https://github.com/psf/black) for Python, `gofmt` for Go, `rustfmt` for Rust or [`prettier`](https://prettier.io/) for JavaScript, HTML and CSS. These tools autoformat your code so that it’s consistent with common stylistic patterns for the given programming language. Although you might be unwilling to give stylistic control about your code, standardizing code format will help other people read your code and will make you better at reading other people’s (stylistically standardized) code.

> 对于风格检查和代码格式化，还有以下一些工具可以作为补充：用于 Python 的 [`black`](https://github.com/psf/black)、用于 Go 语言的 `gofmt`、用于 Rust 的 `rustfmt` 或是用于 JavaScript, HTML 和 CSS 的 [`prettier`](https://prettier.io/) 。这些工具可以自动格式化您的代码，这样代码风格就可以与常见的风格保持一致。 尽管您可能并不想对代码进行风格控制，标准的代码风格有助于方便别人阅读您的代码，也可以方便您阅读它的代码。

<img src="./Debugging and Profiling/Screenshot 2023-12-18 at 16.35.57.png" alt="Screenshot 2023-12-18 at 16.35.57" />



# Profiling

Even if your code functionally behaves as you would expect, that might not be good enough if it takes all your CPU or memory in the process. Algorithms classes often teach big *O* notation but not how to find hot spots in your programs. Since [premature optimization is the root of all evil](http://wiki.c2.com/?PrematureOptimization), you should learn about profilers and monitoring tools. They will help you understand which parts of your program are taking most of the time and/or resources so you can focus on optimizing those parts.

> 即使您的代码能够像您期望的一样运行，但是如果它消耗了您全部的 CPU 和内存，那么它显然也不是个好程序。算法课上我们通常会介绍大O标记法，但却没教给我们如何找到程序中的热点。 鉴于 [过早的优化是万恶之源](http://wiki.c2.com/?PrematureOptimization)，您需要学习性能分析和监控工具，它们会帮助您找到程序中最耗时、最耗资源的部分，这样您就可以有针对性的进行性能优化。



## Timing

Similarly to the debugging case, in many scenarios it can be enough to just print the time it took your code between two points. Here is an example in Python using the [`time`](https://docs.python.org/3/library/time.html) module.

> 和调试代码类似，大多数情况下我们只需要打印两处代码之间的时间即可发现问题。下面这个例子中，我们使用了 Python 的 [`time`](https://docs.python.org/3/library/time.html)模块。

```python
import time, random
n = random.randint(1, 10) * 100

# Get current time
start = time.time()

# Do some work
print("Sleeping for {} ms".format(n))
time.sleep(n/1000)

# Compute time between start and now
print(time.time() - start)

# Output
# Sleeping for 500 ms
# 0.5713930130004883
```

However, wall clock time can be misleading since your computer might be running other processes at the same time or waiting for events to happen. It is common for tools to make a distinction between *Real*, *User* and *Sys* time. In general, *User* + *Sys* tells you how much time your process actually spent in the CPU (more detailed explanation [here](https://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1)).

> 不过，执行时间（wall clock time）也可能会误导您，因为您的电脑可能也在同时运行其他进程，也可能在此期间发生了等待。 对于工具来说，需要区分真实时间、用户时间和系统时间。通常来说，用户时间+系统时间代表了您的进程所消耗的实际 CPU （更详细的解释可以参照[这篇文章](https://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1)）。

- *Real* - Wall clock elapsed time from start to finish of the program, including the time taken by other processes and time taken while blocked (e.g. waiting for I/O or network)
- *User* - Amount of time spent in the CPU running user code
- *Sys* - Amount of time spent in the CPU running kernel code

> - 真实时间 - 从程序开始到结束流失掉的真实时间，包括其他进程的执行时间以及阻塞消耗的时间（例如等待 I/O或网络）；
> - *User* - CPU 执行用户代码所花费的时间；
> - *Sys* - CPU 执行系统内核代码所花费的时间。

For example, try running a command that performs an HTTP request and prefixing it with [`time`](https://www.man7.org/linux/man-pages/man1/time.1.html). Under a slow connection you might get an output like the one below. Here it took over 2 seconds for the request to complete but the process only took 15ms of CPU user time and 12ms of kernel CPU time.

> 例如，试着执行一个用于发起 HTTP 请求的命令并在其前面添加 [`time`](http://man7.org/linux/man-pages/man1/time.1.html) 前缀。网络不好的情况下您可能会看到下面的输出结果。请求花费了 2s 才完成，但是进程仅花费了 15ms 的 CPU 用户时间和 12ms 的 CPU 内核时间。

```
$ time curl https://missing.csail.mit.edu &> /dev/null
real    0m2.561s
user    0m0.015s
sys     0m0.012s
```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 18.11.31.png" alt="Screenshot 2023-12-18 at 18.11.31" />
>
> 



## Profilers

### CPU

Most of the time when people refer to *profilers* they actually mean *CPU profilers*, which are the most common. There are two main types of CPU profilers: *tracing* and *sampling* profilers. Tracing profilers keep a record of every function call your program makes whereas sampling profilers probe your program periodically (commonly every millisecond) and record the program’s stack. They use these records to present aggregate statistics of what your program spent the most time doing. [Here](https://jvns.ca/blog/2017/12/17/how-do-ruby---python-profilers-work-) is a good intro article if you want more detail on this topic.

> 大多数情况下，当人们提及性能分析工具的时候，通常指的是 CPU 性能分析工具。 CPU 性能分析工具有两种： 追踪分析器（*tracing*）及采样分析器（*sampling*）。 追踪分析器 会记录程序的每一次函数调用，而采样分析器则只会周期性的监测（通常为每毫秒）您的程序并记录程序堆栈。它们使用这些记录来生成统计信息，显示程序在哪些事情上花费了最多的时间。如果您希望了解更多相关信息，可以参考[这篇](https://jvns.ca/blog/2017/12/17/how-do-ruby---python-profilers-work-) 介绍性的文章。

Most programming languages have some sort of command line profiler that you can use to analyze your code. They often integrate with full fledged IDEs but for this lecture we are going to focus on the command line tools themselves.

> 大多数的编程语言都有一些基于命令行的分析器，我们可以使用它们来分析代码。它们通常可以集成在 IDE 中，但是本节课我们会专注于这些命令行工具本身。

In Python we can use the `cProfile` module to profile time per function call. Here is a simple example that implements a rudimentary grep in Python:

> 在 Python 中，我们使用 `cProfile` 模块来分析每次函数调用所消耗的时间。 在下面的例子中，我们实现了一个基础的 grep 命令：

```python 
#!/usr/bin/env python

import sys, re

def grep(pattern, file):
    with open(file, 'r') as f:
        print(file)
        for i, line in enumerate(f.readlines()):
            pattern = re.compile(pattern)
            match = pattern.search(line)
            if match is not None:
                print("{}: {}".format(i, line), end="")

if __name__ == '__main__':
    times = int(sys.argv[1])
    pattern = sys.argv[2]
    for i in range(times):
        for file in sys.argv[3:]:
            grep(pattern, file)
```

We can profile this code using the following command. Analyzing the output we can see that IO is taking most of the time and that compiling the regex takes a fair amount of time as well. Since the regex only needs to be compiled once, we can factor it out of the for.

> 我们可以使用下面的命令来对这段代码进行分析。通过它的输出我们可以知道，IO 消耗了大量的时间，编译正则表达式也比较耗费时间。因为正则表达式只需要编译一次，我们可以将其移动到 for 循环外面来改进性能。

```python
$ python -m cProfile -s tottime grep.py 1000 '^(import|\s*def)[^,]*$' *.py

[omitted program output]

 ncalls  tottime  percall  cumtime  percall filename:lineno(function)
     8000    0.266    0.000    0.292    0.000 {built-in method io.open}
     8000    0.153    0.000    0.894    0.000 grep.py:5(grep)
    17000    0.101    0.000    0.101    0.000 {built-in method builtins.print}
     8000    0.100    0.000    0.129    0.000 {method 'readlines' of '_io._IOBase' objects}
    93000    0.097    0.000    0.111    0.000 re.py:286(_compile)
    93000    0.069    0.000    0.069    0.000 {method 'search' of '_sre.SRE_Pattern' objects}
    93000    0.030    0.000    0.141    0.000 re.py:231(compile)
    17000    0.019    0.000    0.029    0.000 codecs.py:318(decode)
        1    0.017    0.017    0.911    0.911 grep.py:3(<module>)

[omitted lines]
```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 18.24.34.png" alt="Screenshot 2023-12-18 at 18.24.34" />

A caveat of Python’s `cProfile` profiler (and many profilers for that matter) is that they display time per function call. That can become unintuitive really fast, especially if you are using third party libraries in your code since internal function calls are also accounted for. A more intuitive way of displaying profiling information is to include the time taken per line of code, which is what *line profilers* do.

> 关于 Python 的 `cProfile` 分析器（以及其他一些类似的分析器），需要注意的是它显示的是每次函数调用的时间。看上去可能快到反直觉，尤其是如果您在代码里面使用了第三方的函数库，因为内部函数调用也会被看作函数调用。

For instance, the following piece of Python code performs a request to the class website and parses the response to get all URLs in the page:

> 更加符合直觉的显示分析信息的方式是包括每行代码的执行时间，这也是*行分析器*的工作。例如，下面这段 Python 代码会向本课程的网站发起一个请求，然后解析响应返回的页面中的全部 URL：

```python
#!/usr/bin/env python
import requests
from bs4 import BeautifulSoup

# This is a decorator that tells line_profiler
# that we want to analyze this function
@profile
def get_urls():
    response = requests.get('https://missing.csail.mit.edu')
    s = BeautifulSoup(response.content, 'lxml')
    urls = []
    for url in s.find_all('a'):
        urls.append(url['href'])

if __name__ == '__main__':
    get_urls()
```

If we used Python’s `cProfile` profiler we’d get over 2500 lines of output, and even with sorting it’d be hard to understand where the time is being spent. A quick run with [`line_profiler`](https://github.com/pyutils/line_profiler) shows the time taken per line:

> 如果我们使用 Python 的 `cProfile` 分析器，我们会得到超过2500行的输出结果，即使对其进行排序，我仍然搞不懂时间到底都花在哪了。如果我们使用 [`line_profiler`](https://github.com/pyutils/line_profiler)，它会基于行来显示时间：

```
$ kernprof -l -v a.py
Wrote profile results to urls.py.lprof
Timer unit: 1e-06 s

Total time: 0.636188 s
File: a.py
Function: get_urls at line 5

Line #  Hits         Time  Per Hit   % Time  Line Contents
==============================================================
 5                                           @profile
 6                                           def get_urls():
 7         1     613909.0 613909.0     96.5      response = requests.get('https://missing.csail.mit.edu')
 8         1      21559.0  21559.0      3.4      s = BeautifulSoup(response.content, 'lxml')
 9         1          2.0      2.0      0.0      urls = []
10        25        685.0     27.4      0.1      for url in s.find_all('a'):
11        24         33.0      1.4      0.0          urls.append(url['href'])
```

> `pip3 install line_profiler`
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 18.33.38.png" alt="Screenshot 2023-12-18 at 18.33.38" />

### Memory

In languages like C or C++ memory leaks can cause your program to never release memory that it doesn’t need anymore. To help in the process of memory debugging you can use tools like [Valgrind](https://valgrind.org/) that will help you identify memory leaks.

> 像 C 或者 C++ 这样的语言，内存泄漏会导致您的程序在使用完内存后不去释放它。为了应对内存类的 Bug，我们可以使用类似 [Valgrind](https://valgrind.org/) 这样的工具来检查内存泄漏问题。

In garbage collected languages like Python it is still useful to use a memory profiler because as long as you have pointers to objects in memory they won’t be garbage collected. Here’s an example program and its associated output when running it with [memory-profiler](https://pypi.org/project/memory-profiler/) (note the decorator like in `line-profiler`).

> 对于 Python 这类具有垃圾回收机制的语言，内存分析器也是很有用的，因为对于某个对象来说，只要有指针还指向它，那它就不会被回收。下面这个例子及其输出，展示了 [memory-profiler](https://pypi.org/project/memory-profiler/) 是如何工作的（注意装饰器和 `line-profiler` 类似）。

```python
@profile
def my_func():
    a = [1] * (10 ** 6)
    b = [2] * (2 * 10 ** 7)
    del b
    return a

if __name__ == '__main__':
    my_func()
$ python -m memory_profiler example.py
Line #    Mem usage  Increment   Line Contents
==============================================
     3                           @profile
     4      5.97 MB    0.00 MB   def my_func():
     5     13.61 MB    7.64 MB       a = [1] * (10 ** 6)
     6    166.20 MB  152.59 MB       b = [2] * (2 * 10 ** 7)
     7     13.61 MB -152.59 MB       del b
     8     13.61 MB    0.00 MB       return a
```

> <img src="./Debugging and Profiling/Screenshot 2023-12-18 at 18.37.54.png" alt="Screenshot 2023-12-18 at 18.37.54" />
>
> 



### Event Profiling

As it was the case for `strace` for debugging, you might want to ignore the specifics of the code that you are running and treat it like a black box when profiling. The [`perf`](https://www.man7.org/linux/man-pages/man1/perf.1.html) command abstracts CPU differences away and does not report time or memory, but instead it reports system events related to your programs. For example, `perf` can easily report poor cache locality, high amounts of page faults or livelocks. Here is an overview of the command:

> 在我们使用`strace`调试代码的时候，您可能会希望忽略一些特殊的代码并希望在分析时将其当作黑盒处理。[`perf`](http://man7.org/linux/man-pages/man1/perf.1.html) 命令将 CPU 的区别进行了抽象，它不会报告时间和内存的消耗，而是报告与您的程序相关的系统事件。例如，`perf` 可以报告不佳的缓存局部性（poor cache locality）、大量的页错误（page faults）或活锁（livelocks）。下面是关于常见命令的简介：

- `perf list` - List the events that can be traced with perf
- `perf stat COMMAND ARG1 ARG2` - Gets counts of different events related to a process or command
- `perf record COMMAND ARG1 ARG2` - Records the run of a command and saves the statistical data into a file called `perf.data`
- `perf report` - Formats and prints the data collected in `perf.data`

> - `perf list` - 列出可以被 pref 追踪的事件；
> - `perf stat COMMAND ARG1 ARG2` - 收集与某个进程或指令相关的事件；
> - `perf record COMMAND ARG1 ARG2` - 记录命令执行的采样信息并将统计数据储存在`perf.data`中；
> - `perf report` - 格式化并打印 `perf.data` 中的数据。

> The `perf` command, which is commonly used in Linux for performance analysis
>
> ```
> sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`
> sudo apt-get install stress
> ```
>
> 

> `sudo perf stat stress -c 1`
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.06.30.png" alt="Screenshot 2023-12-19 at 00.06.30" />
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.05.59.png" alt="Screenshot 2023-12-19 at 00.05.59" />
>
> 

### Visualization

Profiler output for real world programs will contain large amounts of information because of the inherent complexity of software projects. Humans are visual creatures and are quite terrible at reading large amounts of numbers and making sense of them. Thus there are many tools for displaying profiler’s output in an easier to parse way.

> 使用分析器来分析真实的程序时，由于软件的复杂性，其输出结果中将包含大量的信息。人类是一种视觉动物，非常不善于阅读大量的文字。因此很多工具都提供了可视化分析器输出结果的功能。

One common way to display CPU profiling information for sampling profilers is to use a [Flame Graph](http://www.brendangregg.com/flamegraphs.html), which will display a hierarchy of function calls across the Y axis and time taken proportional to the X axis. They are also interactive, letting you zoom into specific parts of the program and get their stack traces (try clicking in the image below).

> 对于采样分析器来说，常见的显示 CPU 分析数据的形式是 [火焰图](http://www.brendangregg.com/flamegraphs.html)，火焰图会在 Y 轴显示函数调用关系，并在 X 轴显示其耗时的比例。火焰图同时还是可交互的，您可以深入程序的某一具体部分，并查看其栈追踪（您可以尝试点击下面的图片）。

[<img src="./Debugging and Profiling/cpu-bash-flamegraph.svg" alt="FlameGraph" />](http://www.brendangregg.com/FlameGraphs/cpu-bash-flamegraph.svg)

Call graphs or control flow graphs display the relationships between subroutines within a program by including functions as nodes and functions calls between them as directed edges. When coupled with profiling information such as the number of calls and time taken, call graphs can be quite useful for interpreting the flow of a program. In Python you can use the [`pycallgraph`](https://pycallgraph.readthedocs.io/) library to generate them.

> 调用图和控制流图可以显示子程序之间的关系，它将函数作为节点并把函数调用作为边。将它们和分析器的信息（例如调用次数、耗时等）放在一起使用时，调用图会变得非常有用，它可以帮助我们分析程序的流程。 在 Python 中您可以使用 [`pycallgraph`](http://pycallgraph.slowchop.com/en/master/) 来生成这些图片。

<img src="./Debugging and Profiling/A_Call_Graph_generated_by_pycallgraph.png" alt="Call Graph" />



## Resource Monitoring

Sometimes, the first step towards analyzing the performance of your program is to understand what its actual resource consumption is. Programs often run slowly when they are resource constrained, e.g. without enough memory or on a slow network connection. There are a myriad of command line tools for probing and displaying different system resources like CPU usage, memory usage, network, disk usage and so on.

> 有时候，分析程序性能的第一步是搞清楚它所消耗的资源。程序变慢通常是因为它所需要的资源不够了。例如，没有足够的内存或者网络连接变慢的时候。有很多很多的工具可以被用来显示不同的系统资源，例如 CPU 占用、内存使用、网络、磁盘使用等。

- **General Monitoring** - Probably the most popular is [`htop`](https://htop.dev/), which is an improved version of [`top`](https://www.man7.org/linux/man-pages/man1/top.1.html). `htop` presents various statistics for the currently running processes on the system. `htop` has a myriad of options and keybinds, some useful ones are: `<F6>` to sort processes, `t` to show tree hierarchy and `h` to toggle threads. See also [`glances`](https://nicolargo.github.io/glances/) for similar implementation with a great UI. For getting aggregate measures across all processes, [`dstat`](http://dag.wiee.rs/home-made/dstat/) is another nifty tool that computes real-time resource metrics for lots of different subsystems like I/O, networking, CPU utilization, context switches, &c.

  > **通用监控** - 最流行的工具要数 [`htop`](https://htop.dev/),了，它是 [`top`](http://man7.org/linux/man-pages/man1/top.1.html)的改进版。`htop` 可以显示当前运行进程的多种统计信息。`htop` 有很多选项和快捷键，常见的有：`<F6>` 进程排序、 `t` 显示树状结构和 `h` 打开或折叠线程。 还可以留意一下 [`glances`](https://nicolargo.github.io/glances/) ，它的实现类似但是用户界面更好。如果需要合并测量全部的进程， [`dstat`](http://dag.wiee.rs/home-made/dstat/) 是也是一个非常好用的工具，它可以实时地计算不同子系统资源的度量数据，例如 I/O、网络、 CPU 利用率、上下文切换等等；
  >
  > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.19.43.png" alt="Screenshot 2023-12-19 at 00.19.43" />
  >
  > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.22.17.png" alt="Screenshot 2023-12-19 at 00.22.17" />

- **I/O operations** - [`iotop`](https://www.man7.org/linux/man-pages/man8/iotop.8.html) displays live I/O usage information and is handy to check if a process is doing heavy I/O disk operations

  > **I/O 操作** - [`iotop`](http://man7.org/linux/man-pages/man8/iotop.8.html) 可以显示实时 I/O 占用信息而且可以非常方便地检查某个进程是否正在执行大量的磁盘读写操作；

- **Disk Usage** - [`df`](https://www.man7.org/linux/man-pages/man1/df.1.html) displays metrics per partitions and [`du`](http://man7.org/linux/man-pages/man1/du.1.html) displays **d**isk **u**sage per file for the current directory. In these tools the `-h` flag tells the program to print with **h**uman readable format. A more interactive version of `du` is [`ncdu`](https://dev.yorhel.nl/ncdu) which lets you navigate folders and delete files and folders as you navigate.

  > **磁盘使用** - [`df`](http://man7.org/linux/man-pages/man1/df.1.html) 可以显示每个分区的信息，而 [`du`](http://man7.org/linux/man-pages/man1/du.1.html) 则可以显示当前目录下每个文件的磁盘使用情况（ **d**isk **u**sage）。`-h` 选项可以使命令以对人类（**h**uman）更加友好的格式显示数据；[`ncdu`](https://dev.yorhel.nl/ncdu)是一个交互性更好的 `du` ，它可以让您在不同目录下导航、删除文件和文件夹；
  >
  > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.27.13.png" alt="Screenshot 2023-12-19 at 00.27.13" />
  >
  > `brew install ncdu`

  > ```
  > $ cd Movies
  > $ ncdu .
  > ```
  >
  > 
  >
  > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.30.08.png" alt="Screenshot 2023-12-19 at 00.30.08" />

- **Memory Usage** - [`free`](https://www.man7.org/linux/man-pages/man1/free.1.html) displays the total amount of free and used memory in the system. Memory is also displayed in tools like `htop`.

  > **内存使用** - [`free`](http://man7.org/linux/man-pages/man1/free.1.html) 可以显示系统当前空闲的内存。内存也可以使用 `htop` 这样的工具来显示；

- **Open Files** - [`lsof`](https://www.man7.org/linux/man-pages/man8/lsof.8.html) lists file information about files opened by processes. It can be quite useful for checking which process has opened a specific file.

  > **打开文件** - [`lsof`](http://man7.org/linux/man-pages/man8/lsof.8.html) 可以列出被进程打开的文件信息。 当我们需要查看某个文件是被哪个进程打开的时候，这个命令非常有用；
  >
  > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.36.53.png" alt="Screenshot 2023-12-19 at 00.36.53" />

- **Network Connections and Config** - [`ss`](https://www.man7.org/linux/man-pages/man8/ss.8.html) lets you monitor incoming and outgoing network packets statistics as well as interface statistics. A common use case of `ss` is figuring out what process is using a given port in a machine. For displaying routing, network devices and interfaces you can use [`ip`](http://man7.org/linux/man-pages/man8/ip.8.html). Note that `netstat` and `ifconfig` have been deprecated in favor of the former tools respectively.

  > **网络连接和配置** - [`ss`](http://man7.org/linux/man-pages/man8/ss.8.html) 能帮助我们监控网络包的收发情况以及网络接口的显示信息。`ss` 常见的一个使用场景是找到端口被进程占用的信息。如果要显示路由、网络设备和接口信息，您可以使用 [`ip`](http://man7.org/linux/man-pages/man8/ip.8.html) 命令。注意，`netstat` 和 `ifconfig` 这两个命令已经被前面那些工具所代替了。

- **Network Usage** - [`nethogs`](https://github.com/raboof/nethogs) and [`iftop`](http://www.ex-parrot.com/pdw/iftop/) are good interactive CLI tools for monitoring network usage.

  > **网络使用** - [`nethogs`](https://github.com/raboof/nethogs) 和 [`iftop`](http://www.ex-parrot.com/pdw/iftop/) 是非常好的用于对网络占用进行监控的交互式命令行工具。

If you want to test these tools you can also artificially impose loads on the machine using the [`stress`](https://linux.die.net/man/1/stress) command.

> 如果您希望测试一下这些工具，您可以使用 [`stress`](https://linux.die.net/man/1/stress) 命令来为系统人为地增加负载。

### Specialized tools

Sometimes, black box benchmarking is all you need to determine what software to use. Tools like [`hyperfine`](https://github.com/sharkdp/hyperfine) let you quickly benchmark command line programs. For instance, in the shell tools and scripting lecture we recommended `fd` over `find`. We can use `hyperfine` to compare them in tasks we run often. E.g. in the example below `fd` was 20x faster than `find` in my machine.

> 有时候，您只需要对黑盒程序进行基准测试，并依此对软件选择进行评估。 类似 [`hyperfine`](https://github.com/sharkdp/hyperfine) 这样的命令行可以帮您快速进行基准测试。例如，我们在 shell 工具和脚本那一节课中我们推荐使用 `fd` 来代替 `find`。我们这里可以用`hyperfine`来比较一下它们。例如，下面的例子中，我们可以看到`fd` 比 `find` 要快20倍。

```python
$ hyperfine --warmup 3 'fd -e jpg' 'find . -iname "*.jpg"'
Benchmark #1: fd -e jpg
  Time (mean ± σ):      51.4 ms ±   2.9 ms    [User: 121.0 ms, System: 160.5 ms]
  Range (min … max):    44.2 ms …  60.1 ms    56 runs

Benchmark #2: find . -iname "*.jpg"
  Time (mean ± σ):      1.126 s ±  0.101 s    [User: 141.1 ms, System: 956.1 ms]
  Range (min … max):    0.975 s …  1.287 s    10 runs

Summary
  'fd -e jpg' ran
   21.89 ± 2.33 times faster than 'find . -iname "*.jpg"'
```

As it was the case for debugging, browsers also come with a fantastic set of tools for profiling webpage loading, letting you figure out where time is being spent (loading, rendering, scripting, &c). More info for [Firefox](https://profiler.firefox.com/docs/) and [Chrome](https://developers.google.com/web/tools/chrome-devtools/rendering-tools).

> 和 debug 一样，浏览器也包含了很多不错的性能分析工具，可以用来分析页面加载，让我们可以搞清楚时间都消耗在什么地方（加载、渲染、脚本等等）。 更多关于 [Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Performance/Profiling_with_the_Built-in_Profiler) 和 [Chrome](https://developers.google.com/web/tools/chrome-devtools/rendering-tools)的信息可以点击链接。

> `brew install hyperfine`
>
> <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.46.11.png" alt="Screenshot 2023-12-19 at 00.46.11" />



# Exercises

## Debugging

1. Use `journalctl` on Linux or `log show` on macOS to get the super user accesses and commands in the last day. If there aren’t any you can execute some harmless commands such as `sudo ls` and check again.

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.50.45.png" alt="Screenshot 2023-12-19 at 00.50.45" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.51.30.png" alt="Screenshot 2023-12-19 at 00.51.30" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 00.52.11.png" alt="Screenshot 2023-12-19 at 00.52.11" />

2. Do [this](https://github.com/spiside/pdb-tutorial) hands on `pdb` tutorial to familiarize yourself with the commands. For a more in depth tutorial read [this](https://realpython.com/python-debugging-pdb).

3. Install [`shellcheck`](https://www.shellcheck.net/) and try checking the following script. What is wrong with the code? Fix it. Install a linter plugin in your editor so you can get your warnings automatically.

   ```shell
   #!/bin/sh
   ## Example: a typical script with several problems
   for f in $(ls *.m3u)
   do
     grep -qi hq.*mp3 $f \
       && echo -e 'Playlist $f contains a HQ file in mp3 format'
   done
   ```

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.41.45.png" alt="Screenshot 2023-12-19 at 01.41.45" />

   ```
   Plug 'dense-analysis/ale'
   ```

   ```
   " Set ALE to use shellcheck for shell script linting
   let g:ale_linters = {
   \   'sh': ['shellcheck'],
   \}
   
   " Enable linting on file open and save
   let g:ale_lint_on_enter = 1
   let g:ale_lint_on_save = 1
   ```

   

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.46.15.png" alt="Screenshot 2023-12-19 at 01.46.15" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.45.55.png" alt="Screenshot 2023-12-19 at 01.45.55" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.48.13.png" alt="Screenshot 2023-12-19 at 01.48.13" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.51.35.png" alt="Screenshot 2023-12-19 at 01.51.35" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 01.53.14.png" alt="Screenshot 2023-12-19 at 01.53.14" style="zoom: 67%;" />

4. (Advanced) Read about [reversible debugging](https://undo.io/resources/reverse-debugging-whitepaper/) and get a simple example working using [`rr`](https://rr-project.org/) or [`RevPDB`](https://morepypy.blogspot.com/2016/07/reverse-debugging-for-python.html).

   > M2 Macbook Air I cannot work successfully.

   ## Profiling

5. [Here](https://missing.csail.mit.edu/static/files/sorts.py) are some sorting algorithm implementations. Use [`cProfile`](https://docs.python.org/3/library/profile.html) and [`line_profiler`](https://github.com/pyutils/line_profiler) to compare the runtime of insertion sort and quicksort. What is the bottleneck of each algorithm? Use then `memory_profiler` to check the memory consumption, why is insertion sort better? Check now the inplace version of quicksort. Challenge: Use `perf` to look at the cycle counts and cache hits and misses of each algorithm.

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.45.03.png" alt="Screenshot 2023-12-19 at 14.45.03" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.45.40.png" alt="Screenshot 2023-12-19 at 14.45.40" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.51.33.png" alt="Screenshot 2023-12-19 at 14.51.33" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.54.58.png" alt="Screenshot 2023-12-19 at 14.54.58" />

   `pip3 install memory_profiler`

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 15.09.33.png" alt="Screenshot 2023-12-19 at 15.09.33" />

   > MacOS cannot use perf
   >
   > <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 15.43.05.png" alt="Screenshot 2023-12-19 at 15.43.05" />
   >
   > VM will show `not supported` 

6. Here’s some (arguably convoluted) Python code for computing Fibonacci numbers using a function for each number.

   ```python
   #!/usr/bin/env python
   def fib0(): return 0
   
   def fib1(): return 1
   
   s = """def fib{}(): return fib{}() + fib{}()"""
   
   if __name__ == '__main__':
   
       for n in range(2, 10):
           exec(s.format(n, n-1, n-2))
       # from functools import lru_cache
       # for n in range(10):
       #     exec("fib{} = lru_cache(1)(fib{})".format(n, n))
       print(eval("fib9()"))
   ```

   Put the code into a file and make it executable. Install prerequisites: [`pycallgraph`](https://pycallgraph.readthedocs.io/) and [`graphviz`](http://graphviz.org/). (If you can run `dot`, you already have GraphViz.) Run the code as is with `pycallgraph graphviz -- ./fib.py` and check the `pycallgraph.png` file. How many times is `fib0` called?. We can do better than that by memoizing the functions. Uncomment the commented lines and regenerate the images. How many times are we calling each `fibN` function now?

   ```
   $ pip3 install "setuptools<58.0.0"
   $ pip3 install pycallgraph
   $ pip3 install graphviz
   $ brew install graphviz
   $ dot -v
   ```

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 13.27.57.png" alt="Screenshot 2023-12-19 at 13.27.57" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 13.35.09.png" alt="Screenshot 2023-12-19 at 13.35.09" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 13.38.35.png" alt="Screenshot 2023-12-19 at 13.38.35" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 13.57.30.png" alt="Screenshot 2023-12-19 at 13.57.30" />

7. A common issue is that a port you want to listen on is already taken by another process. Let’s learn how to discover that process pid. First execute `python -m http.server 4444` to start a minimal web server listening on port `4444`. On a separate terminal run `lsof | grep LISTEN` to print all listening processes and ports. Find that process pid and terminate it by running `kill <PID>`.

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 02.16.44.png" alt="Screenshot 2023-12-19 at 02.16.44" />

8. Limiting a process’s resources can be another handy tool in your toolbox. Try running `stress -c 3` and visualize the CPU consumption with `htop`. Now, execute `taskset --cpu-list 0,2 stress -c 3` and visualize it. Is `stress` taking three CPUs? Why not? Read [`man taskset`](https://www.man7.org/linux/man-pages/man1/taskset.1.html). Challenge: achieve the same using [`cgroups`](https://www.man7.org/linux/man-pages/man7/cgroups.7.html). Try limiting the memory consumption of `stress -m`.

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.05.42.png" alt="Screenshot 2023-12-19 at 14.05.42" />

   

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.06.21.png" alt="Screenshot 2023-12-19 at 14.06.21" />

   

   > On macOS, the `taskset` command from Linux is not available, as macOS uses a different method for handling CPU affinity and process management. macOS does not provide as straightforward a tool as `taskset` for setting CPU affinity

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.12.48.png" alt="Screenshot 2023-12-19 at 14.12.48" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 14.13.40.png" alt="Screenshot 2023-12-19 at 14.13.40" />

   `sudo apt-get install cgroup-tools`

   > Not finish this problem.

9. (Advanced) The command `curl ipinfo.io` performs a HTTP request and fetches information about your public IP. Open [Wireshark](https://www.wireshark.org/) and try to sniff the request and reply packets that `curl` sent and received. (Hint: Use the `http` filter to just watch HTTP packets).

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 12.04.30.png" alt="Screenshot 2023-12-19 at 12.04.30" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 12.04.01.png" alt="Screenshot 2023-12-19 at 12.04.01" />

   <img src="./Debugging and Profiling/Screenshot 2023-12-19 at 12.04.19.png" alt="Screenshot 2023-12-19 at 12.04.19" />

   

   