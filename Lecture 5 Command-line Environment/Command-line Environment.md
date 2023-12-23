# Command-line Environment

https://youtu.be/e8BO_dYxk5c

In this lecture we will go through several ways in which you can improve your workflow when using the shell. We have been working with the shell for a while now, but we have mainly focused on executing different commands. We will now see how to run several processes at the same time while keeping track of them, how to stop or pause a specific process and how to make a process run in the background.

> 当您使用 shell 进行工作时，可以使用一些方法改善您的工作流，本节课我们就来讨论这些方法。我们已经使用 shell 一段时间了，但是到目前为止我们的关注点主要集中在使用不同的命令上面。现在，我们将会学习如何同时执行多个不同的进程并追踪它们的状态、如何停止或暂停某个进程以及如何使进程在后台运行。

We will also learn about different ways to improve your shell and other tools, by defining aliases and configuring them using dotfiles. Both of these can help you save time, e.g. by using the same configurations in all your machines without having to type long commands. We will look at how to work with remote machines using SSH.

> 我们还将学习一些能够改善您的 shell 及其他工具的工作流的方法，这主要是通过定义别名或基于配置文件对其进行配置来实现的。这些方法都可以帮您节省大量的时间。例如，仅需要执行一些简单的命令，我们就可以在所有的主机上使用相同的配置。我们还会学习如何使用 SSH 操作远端机器。



# Job Control

In some cases you will need to interrupt a job while it is executing, for instance if a command is taking too long to complete (such as a `find` with a very large directory structure to search through). Most of the time, you can do `Ctrl-C` and the command will stop. But how does this actually work and why does it sometimes fail to stop the process? 

> 某些情况下我们需要中断正在执行的任务，比如当一个命令需要执行很长时间才能完成时（假设我们在使用 `find` 搜索一个非常大的目录结构）。大多数情况下，我们可以使用 `Ctrl-C` 来停止命令的执行。但是它的工作原理是什么呢？为什么有的时候会无法结束进程？



## Killing a process

Your shell is using a UNIX communication mechanism called a *signal* to communicate information to the process. When a process receives a signal it stops its execution, deals with the signal and potentially changes the flow of execution based on the information that the signal delivered. For this reason, signals are *software interrupts*.

> 您的 shell 会使用 UNIX 提供的信号机制执行进程间通信。当一个进程接收到信号时，它会停止执行、处理该信号并基于信号传递的信息来改变其执行。就这一点而言，信号是一种*软件中断*。

In our case, when typing `Ctrl-C` this prompts the shell to deliver a `SIGINT` signal to the process.

> 在上面的例子中，当我们输入 `Ctrl-C` 时，shell 会发送一个`SIGINT` 信号到进程。
>
> <img src="./Command-line Environment/Screenshot 2023-11-29 at 20.01.53-3323701.png" alt="Screenshot 2023-11-29 at 20.01.53" />

Here’s a minimal example of a Python program that captures `SIGINT` and ignores it, no longer stopping. To kill this program we can now use the `SIGQUIT` signal instead, by typing `Ctrl-\`.

> 下面这个 Python 程序向您展示了捕获信号`SIGINT` 并忽略它的基本操作，它并不会让程序停止。为了停止这个程序，我们需要使用`SIGQUIT` 信号，通过输入`Ctrl-\`可以发送该信号。

```python
#!/usr/bin/env python
import signal, time

def handler(signum, time):
    print("\nI got a SIGINT, but I am not stopping")

signal.signal(signal.SIGINT, handler)
i = 0
while True:
    time.sleep(.1)
    print("\r{}".format(i), end="")
    i += 1
```

Here’s what happens if we send `SIGINT` twice to this program, followed by `SIGQUIT`. Note that `^` is how `Ctrl` is displayed when typed in the terminal.

> 如果我们向这个程序发送两次 `SIGINT` ，然后再发送一次 `SIGQUIT`，程序会有什么反应？注意 `^` 是我们在终端输入`Ctrl` 时的表示形式：

```python
$ python sigint.py
24^C
I got a SIGINT, but I am not stopping
26^C
I got a SIGINT, but I am not stopping
30^\[1]    39913 quit       python sigint.py
```

While `SIGINT` and `SIGQUIT` are both usually associated with terminal related requests, a more generic signal for asking a process to exit gracefully is the `SIGTERM` signal. To send this signal we can use the [`kill`](https://www.man7.org/linux/man-pages/man1/kill.1.html) command, with the syntax `kill -TERM <PID>`.

> 尽管 `SIGINT` 和 `SIGQUIT` 都常常用来发出和终止程序相关的请求。`SIGTERM` 则是一个更加通用的、也更加优雅地退出信号。为了发出这个信号我们需要使用 [`kill`](https://www.man7.org/linux/man-pages/man1/kill.1.html) 命令, 它的语法是： `kill -TERM <PID>`。



> <img src="./Command-line Environment/Screenshot 2023-11-29 at 20.08.12-3323701.png" alt="Screenshot 2023-11-29 at 20.08.12" />

## Pausing and backgrounding processes

Signals can do other things beyond killing a process. For instance, `SIGSTOP` pauses a process. In the terminal, typing `Ctrl-Z` will prompt the shell to send a `SIGTSTP` signal, short for Terminal Stop (i.e. the terminal’s version of `SIGSTOP`).

> 信号可以让进程做其他的事情，而不仅仅是终止它们。例如，`SIGSTOP` 会让进程暂停。在终端中，键入 `Ctrl-Z` 会让 shell 发送 `SIGTSTP` 信号，`SIGTSTP`是 Terminal Stop 的缩写（即`terminal`版本的SIGSTOP）。

We can then continue the paused job in the foreground or in the background using [`fg`](https://www.man7.org/linux/man-pages/man1/fg.1p.html) or [`bg`](http://man7.org/linux/man-pages/man1/bg.1p.html), respectively.

> 我们可以使用 [`fg`](https://www.man7.org/linux/man-pages/man1/fg.1p.html) 或 [`bg`](http://man7.org/linux/man-pages/man1/bg.1p.html) 命令恢复暂停的工作。它们分别表示在前台继续或在后台继续。

The [`jobs`](https://www.man7.org/linux/man-pages/man1/jobs.1p.html) command lists the unfinished jobs associated with the current terminal session. You can refer to those jobs using their pid (you can use [`pgrep`](https://www.man7.org/linux/man-pages/man1/pgrep.1.html) to find that out). More intuitively, you can also refer to a process using the percent symbol followed by its job number (displayed by `jobs`). To refer to the last backgrounded job you can use the `$!` special parameter.

> [`jobs`](http://man7.org/linux/man-pages/man1/jobs.1p.html) 命令会列出当前终端会话中尚未完成的全部任务。您可以使用 pid 引用这些任务（也可以用 [`pgrep`](https://www.man7.org/linux/man-pages/man1/pgrep.1.html) 找出 pid）。更加符合直觉的操作是您可以使用百分号 + 任务编号（`jobs` 会打印任务编号）来选取该任务。如果要选择最近的一个任务，可以使用 `$!` 这一特殊参数。

One more thing to know is that the `&` suffix in a command will run the command in the background, giving you the prompt back, although it will still use the shell’s STDOUT which can be annoying (use shell redirections in that case).

> 还有一件事情需要掌握，那就是命令中的 `&` 后缀可以让命令在直接在后台运行，这使得您可以直接在 shell 中继续做其他操作，不过它此时还是会使用 shell 的标准输出，这一点有时会比较恼人（这种情况可以使用 shell 重定向处理）。

To background an already running program you can do `Ctrl-Z` followed by `bg`. Note that backgrounded processes are still children processes of your terminal and will die if you close the terminal (this will send yet another signal, `SIGHUP`). To prevent that from happening you can run the program with [`nohup`](https://www.man7.org/linux/man-pages/man1/nohup.1.html) (a wrapper to ignore `SIGHUP`), or use `disown` if the process has already been started. Alternatively, you can use a terminal multiplexer as we will see in the next section.

> 让已经在运行的进程转到后台运行，您可以键入`Ctrl-Z` ，然后紧接着再输入`bg`。注意，后台的进程仍然是您的终端进程的子进程，一旦您关闭终端（会发送另外一个信号`SIGHUP`），这些后台的进程也会终止。为了防止这种情况发生，您可以使用 [`nohup`](https://www.man7.org/linux/man-pages/man1/nohup.1.html) (一个用来忽略 `SIGHUP` 的封装) 来运行程序。针对已经运行的程序，可以使用`disown` 。除此之外，您可以使用终端多路复用器来实现，下一章节我们会进行详细地探讨。

Below is a sample session to showcase some of these concepts.

> 下面这个简单的会话中展示来了些概念的应用。

```
$ sleep 1000
^Z
[1]  + 18653 suspended  sleep 1000

$ nohup sleep 2000 &
[2] 18745
appending output to nohup.out

$ jobs
[1]  + suspended  sleep 1000
[2]  - running    nohup sleep 2000

$ bg %1
[1]  - 18653 continued  sleep 1000

$ jobs
[1]  - running    sleep 1000
[2]  + running    nohup sleep 2000

$ kill -STOP %1
[1]  + 18653 suspended (signal)  sleep 1000

$ jobs
[1]  + suspended (signal)  sleep 1000
[2]  - running    nohup sleep 2000

$ kill -SIGHUP %1
[1]  + 18653 hangup     sleep 1000

$ jobs
[2]  + running    nohup sleep 2000

$ kill -SIGHUP %2

$ jobs
[2]  + running    nohup sleep 2000

$ kill %2
[2]  + 18745 terminated  nohup sleep 2000

$ jobs
```

A special signal is `SIGKILL` since it cannot be captured by the process and it will always terminate it immediately. However, it can have bad side effects such as leaving orphaned children processes.

You can learn more about these and other signals [here](https://en.wikipedia.org/wiki/Signal_(IPC)) or typing [`man signal`](https://www.man7.org/linux/man-pages/man7/signal.7.html) or `kill -l`.

> `SIGKILL` 是一个特殊的信号，它不能被进程捕获并且它会马上结束该进程。不过这样做会有一些副作用，例如留下孤儿进程。
>
> 您可以在 [这里](https://en.wikipedia.org/wiki/Signal_(IPC)) 或输入 [`man signal`](https://www.man7.org/linux/man-pages/man7/signal.7.html) 或使用 `kill -l` 来获取更多关于信号的信息。

> <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.14.55-3323701.png" alt="Screenshot 2023-12-09 at 10.14.55" />

# Terminal Multiplexers

When using the command line interface you will often want to run more than one thing at once. For instance, you might want to run your editor and your program side by side. Although this can be achieved by opening new terminal windows, using a terminal multiplexer is a more versatile solution.

> 当您在使用命令行时，您通常会希望同时执行多个任务。举例来说，您可以想要同时运行您的编辑器，并在终端的另外一侧执行程序。尽管再打开一个新的终端窗口也能达到目的，使用终端多路复用器则是一种更好的办法。

Terminal multiplexers like [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html) allow you to multiplex terminal windows using panes and tabs so you can interact with multiple shell sessions. Moreover, terminal multiplexers let you detach a current terminal session and reattach at some point later in time. This can make your workflow much better when working with remote machines since it avoids the need to use `nohup` and similar tricks.

> 像 [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html) 这类的终端多路复用器可以允许我们基于面板和标签分割出多个终端窗口，这样您便可以同时与多个 shell 会话进行交互。不仅如此，终端多路复用使我们可以分离当前终端会话并在将来重新连接。这让您操作远端设备时的工作流大大改善，避免了 `nohup` 和其他类似技巧的使用。

The most popular terminal multiplexer these days is [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html). `tmux` is highly configurable and by using the associated keybindings you can create multiple tabs and panes and quickly navigate through them.

> 现在最流行的终端多路器是 [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html)。`tmux` 是一个高度可定制的工具，您可以使用相关快捷键创建多个标签页并在它们间导航。

`tmux` expects you to know its keybindings, and they all have the form `<C-b> x` where that means (1) press `Ctrl+b`, (2) release `Ctrl+b`, and then (3) press `x`. `tmux` has the following hierarchy of objects:

> `tmux` 的快捷键需要我们掌握，它们都是类似 `<C-b> x` 这样的组合，即需要先按下`Ctrl+b`，松开后再按下 `x`。`tmux` 中对象的继承结构如下：

- Sessions - a session is an independent workspace with one or more windows

  - `tmux` starts a new session.

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.19.22-3323701.png" alt="Screenshot 2023-12-09 at 10.19.22" />

    

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.29.24-3323701.png" alt="Screenshot 2023-12-09 at 10.29.24" />

  - `tmux new -s NAME` starts it with that name.

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.44.07-3323701.png" alt="Screenshot 2023-12-09 at 10.44.07" />

  - `tmux ls` lists the current sessions

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.46.02-3323701.png" alt="Screenshot 2023-12-09 at 10.46.02" />

  - Within `tmux` typing `<C-b> d` detaches the current session

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.32.40-3323701.png" alt="Screenshot 2023-12-09 at 10.32.40" />

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.36.11-3323701.png" alt="Screenshot 2023-12-09 at 10.36.11" />

  - `tmux a` attaches the last session. You can use `-t` flag to specify which

- Windows - Equivalent to tabs in editors or browsers, they are visually separate parts of the same session

  - `<C-b> c` Creates a new window. To close it you can just terminate the shells doing `<C-d>`

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.47.21-3323701.png" alt="Screenshot 2023-12-09 at 10.47.21" />

  - `<C-b> N` Go to the *N* th window. Note they are numbered

  - `<C-b> p` Goes to the previous window

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.49.37-3323701.png" alt="Screenshot 2023-12-09 at 10.49.37" />

  - `<C-b> n` Goes to the next window

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.49.57-3323701.png" alt="Screenshot 2023-12-09 at 10.49.57" />

    n also can be session numbers

  - `<C-b> ,` Rename the current window

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.52.30-3323701.png" alt="Screenshot 2023-12-09 at 10.52.30" />

  - `<C-b> w` List current windows

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.53.33-3323701.png" alt="Screenshot 2023-12-09 at 10.53.33" />

- Panes - Like vim splits, panes let you have multiple shells in the same visual display.

  - `<C-b> "` Split the current pane horizontally

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.53.55-3323701.png" alt="Screenshot 2023-12-09 at 10.53.55" />

  - `<C-b> %` Split the current pane vertically

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.54.07-3323701.png" alt="Screenshot 2023-12-09 at 10.54.07" />

  - `<C-b> <direction>` Move to the pane in the specified *direction*. Direction here means arrow keys.

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.55.21-3323701.png" alt="Screenshot 2023-12-09 at 10.55.21" />

  - `<C-b> z` Toggle zoom for the current pane

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.57.34-3323701.png" alt="Screenshot 2023-12-09 at 10.57.34" />

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.57.50-3323701.png" alt="Screenshot 2023-12-09 at 10.57.50" />

    `<C-b> z` again it will go back to the preview one.

  - `<C-b> [` Start scrollback. You can then press `<space>` to start a selection and `<enter>` to copy that selection.

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.04.31-3323701.png" alt="Screenshot 2023-12-09 at 11.04.31" />

  - `<C-b> <space>` Cycle through pane arrangements.

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.55.55-3323701.png" alt="Screenshot 2023-12-09 at 10.55.55" />

    <img src="./Command-line Environment/Screenshot 2023-12-09 at 10.56.48-3323701.png" alt="Screenshot 2023-12-09 at 10.56.48" />

For further reading, [here](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) is a quick tutorial on `tmux` and [this](http://linuxcommand.org/lc3_adv_termmux.php) has a more detailed explanation that covers the original `screen` command. You might also want to familiarize yourself with [`screen`](https://www.man7.org/linux/man-pages/man1/screen.1.html), since it comes installed in most UNIX systems.

> 扩展阅读： [这里](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) 是一份 `tmux` 快速入门教程， [而这一篇](http://linuxcommand.org/lc3_adv_termmux.php) 文章则更加详细，它包含了 `screen` 命令。您也许想要掌握 [`screen`](https://www.man7.org/linux/man-pages/man1/screen.1.html) 命令，因为在大多数 UNIX 系统中都默认安装有该程序。

> Sessions[Windows(Panes)] 

# Aliases

It can become tiresome typing long commands that involve many flags or verbose options. For this reason, most shells support *aliasing*. A shell alias is a short form for another command that your shell will replace automatically for you. For instance, an alias in bash has the following structure:

> 输入一长串包含许多选项的命令会非常麻烦。因此，大多数 shell 都支持设置别名。shell 的别名相当于一个长命令的缩写，shell 会自动将其替换成原本的命令。例如，bash 中的别名语法如下：

```
alias alias_name="command_to_alias arg1 arg2"
```

Note that there is no space around the equal sign `=`, because [`alias`](https://www.man7.org/linux/man-pages/man1/alias.1p.html) is a shell command that takes a single argument.

> 注意， `=`两边是没有空格的，因为 [`alias`](https://www.man7.org/linux/man-pages/man1/alias.1p.html) 是一个 shell 命令，它只接受一个参数。

Aliases have many convenient features:

```
# Make shorthands for common flags
alias ll="ls -lh"

# Save a lot of typing for common commands
alias gs="git status"
alias gc="git commit"
alias v="vim"

# Save you from mistyping
alias sl=ls

# Overwrite existing commands for better defaults
alias mv="mv -i"           # -i prompts before overwrite
alias mkdir="mkdir -p"     # -p make parent dirs as needed
alias df="df -h"           # -h prints human readable format

# Alias can be composed
alias la="ls -A"
alias lla="la -l"

# To ignore an alias run it prepended with \
\ls
# Or disable an alias altogether with unalias
unalias la

# To get an alias definition just call it with alias
alias ll
# Will print ll='ls -lh'
```

Note that aliases do not persist shell sessions by default. To make an alias persistent you need to include it in shell startup files, like `.bashrc` or `.zshrc`, which we are going to introduce in the next section.

> 值得注意的是，在默认情况下 shell 并不会保存别名。为了让别名持续生效，您需要将配置放进 shell 的启动文件里，像是`.bashrc` 或 `.zshrc`，下一节我们就会讲到。

<img src="./Command-line Environment/Screenshot 2023-12-09 at 11.12.25-3323701.png" alt="Screenshot 2023-12-09 at 11.12.25" />

# Dotfiles

Many programs are configured using plain-text files known as *dotfiles* (because the file names begin with a `.`, e.g. `~/.vimrc`, so that they are hidden in the directory listing `ls` by default).

> 很多程序的配置都是通过纯文本格式的被称作*点文件*的配置文件来完成的（之所以称为点文件，是因为它们的文件名以 `.` 开头，例如 `~/.vimrc`。也正因为此，它们默认是隐藏文件，`ls`并不会显示它们）。

Shells are one example of programs configured with such files. On startup, your shell will read many files to load its configuration. Depending on the shell, whether you are starting a login and/or interactive the entire process can be quite complex. [Here](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html) is an excellent resource on the topic.

> shell 的配置也是通过这类文件完成的。在启动时，您的 shell 程序会读取很多文件以加载其配置项。根据 shell 本身的不同，您从登录开始还是以交互的方式完成这一过程可能会有很大的不同。关于这一话题，[这里](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html) 有非常好的资源

For `bash`, editing your `.bashrc` or `.bash_profile` will work in most systems. Here you can include commands that you want to run on startup, like the alias we just described or modifications to your `PATH` environment variable. In fact, many programs will ask you to include a line like `export PATH="$PATH:/path/to/program/bin"` in your shell configuration file so their binaries can be found.

> 对于 `bash`来说，在大多数系统下，您可以通过编辑 `.bashrc` 或 `.bash_profile` 来进行配置。在文件中您可以添加需要在启动时执行的命令，例如上文我们讲到过的别名，或者是您的环境变量。实际上，很多程序都要求您在 shell 的配置文件中包含一行类似 `export PATH="$PATH:/path/to/program/bin"` 的命令，这样才能确保这些程序能够被 shell 找到。

> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.17.07-3323701.png" alt="Screenshot 2023-12-09 at 11.17.07" />
>
> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.21.25-3323701.png" alt="Screenshot 2023-12-09 at 11.21.25" />
>
> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.22.55-3323701.png" alt="Screenshot 2023-12-09 at 11.22.55" />
>
> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.23.15-3323701.png" alt="Screenshot 2023-12-09 at 11.23.15" />
>
> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.23.56-3323701.png" alt="Screenshot 2023-12-09 at 11.23.56" />
>
> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.24.41-3323701.png" alt="Screenshot 2023-12-09 at 11.24.41" />

Some other examples of tools that can be configured through dotfiles are:

> 还有一些其他的工具也可以通过*点文件*进行配置：

- `bash` - `~/.bashrc`, `~/.bash_profile`
- `git` - `~/.gitconfig`
- `vim` - `~/.vimrc` and the `~/.vim` folder
- `ssh` - `~/.ssh/config`
- `tmux` - `~/.tmux.conf`

How should you organize your dotfiles? They should be in their own folder, under version control, and **symlinked** into place using a script. This has the benefits of:

> 我们应该如何管理这些配置文件呢，它们应该在它们的文件夹下，并使用版本控制系统进行管理，然后通过脚本将其 **符号链接** 到需要的地方。这么做有如下好处：

> <img src="./Command-line Environment/Screenshot 2023-12-09 at 11.39.22-3323701.png" alt="Screenshot 2023-12-09 at 11.39.22" />

- **Easy installation**: if you log in to a new machine, applying your customizations will only take a minute.

  > **安装简单**: 如果您登录了一台新的设备，在这台设备上应用您的配置只需要几分钟的时间；

- **Portability**: your tools will work the same way everywhere.

  > **可移植性**: 您的工具在任何地方都以相同的配置工作

- **Synchronization**: you can update your dotfiles anywhere and keep them all in sync.

  > **同步**: 在一处更新配置文件，可以同步到其他所有地方

- **Change tracking**: you’re probably going to be maintaining your dotfiles for your entire programming career, and version history is nice to have for long-lived projects.

  > **变更追踪**: 您可能要在整个程序员生涯中持续维护这些配置文件，而对于长期项目而言，版本历史是非常重要的

What should you put in your dotfiles? You can learn about your tool’s settings by reading online documentation or [man pages](https://en.wikipedia.org/wiki/Man_page). Another great way is to search the internet for blog posts about specific programs, where authors will tell you about their preferred customizations. Yet another way to learn about customizations is to look through other people’s dotfiles: you can find tons of [dotfiles repositories](https://github.com/search?o=desc&q=dotfiles&s=stars&type=Repositories) on Github — see the most popular one [here](https://github.com/mathiasbynens/dotfiles) (we advise you not to blindly copy configurations though). [Here](https://dotfiles.github.io/) is another good resource on the topic.

> 配置文件中需要放些什么？您可以通过在线文档和[帮助手册](https://en.wikipedia.org/wiki/Man_page)了解所使用工具的设置项。另一个方法是在网上搜索有关特定程序的文章，作者们在文章中会分享他们的配置。还有一种方法就是直接浏览其他人的配置文件：您可以在这里找到无数的[dotfiles 仓库](https://github.com/search?o=desc&q=dotfiles&s=stars&type=Repositories) —— 其中最受欢迎的那些可以在[这里](https://github.com/mathiasbynens/dotfiles)找到（我们建议您不要直接复制别人的配置）。[这里](https://dotfiles.github.io/) 也有一些非常有用的资源。

All of the class instructors have their dotfiles publicly accessible on GitHub: [Anish](https://github.com/anishathalye/dotfiles), [Jon](https://github.com/jonhoo/configs), [Jose](https://github.com/jjgo/dotfiles).

> 本课程的老师们也在 GitHub 上开源了他们的配置文件： [Anish](https://github.com/anishathalye/dotfiles), [Jon](https://github.com/jonhoo/configs), [Jose](https://github.com/jjgo/dotfiles).



## Portability

A common pain with dotfiles is that the configurations might not work when working with several machines, e.g. if they have different operating systems or shells. Sometimes you also want some configuration to be applied only in a given machine.

> 配置文件的一个常见的痛点是它可能并不能在多种设备上生效。例如，如果您在不同设备上使用的操作系统或者 shell 是不同的，则配置文件是无法生效的。或者，有时您仅希望特定的配置只在某些设备上生效。

There are some tricks for making this easier. If the configuration file supports it, use the equivalent of if-statements to apply machine specific customizations. For example, your shell could have something like:

> 有一些技巧可以轻松达成这些目的。如果配置文件 if 语句，则您可以借助它针对不同的设备编写不同的配置。例如，您的 shell 可以这样做：

```
if [[ "$(uname)" == "Linux" ]]; then {do_something}; fi

# Check before using shell-specific features
if [[ "$SHELL" == "zsh" ]]; then {do_something}; fi

# You can also make it machine-specific
if [[ "$(hostname)" == "myServer" ]]; then {do_something}; fi
```

If the configuration file supports it, make use of includes. For example, a `~/.gitconfig` can have a setting:

> 如果配置文件支持 include 功能，您也可以多加利用。例如：`~/.gitconfig` 可以这样编写：

```
[include]
    path = ~/.gitconfig_local
```

And then on each machine, `~/.gitconfig_local` can contain machine-specific settings. You could even track these in a separate repository for machine-specific settings.

> 然后我们可以在日常使用的设备上创建配置文件 `~/.gitconfig_local` 来包含与该设备相关的特定配置。您甚至应该创建一个单独的代码仓库来管理这些与设备相关的配置。

This idea is also useful if you want different programs to share some configurations. For instance, if you want both `bash` and `zsh` to share the same set of aliases you can write them under `.aliases` and have the following block in both:

> 如果您希望在不同的程序之间共享某些配置，该方法也适用。例如，如果您想要在 `bash` 和 `zsh` 中同时启用一些别名，您可以把它们写在 `.aliases` 里，然后在这两个 shell 里应用：

```
# Test if ~/.aliases exists and source it
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi
```



# Remote Machines

It has become more and more common for programmers to use remote servers in their everyday work. If you need to use remote servers in order to deploy backend software or you need a server with higher computational capabilities, you will end up using a Secure Shell (SSH). As with most tools covered, SSH is highly configurable so it is worth learning about it.

> 对于程序员来说，在他们的日常工作中使用远程服务器已经非常普遍了。如果您需要使用远程服务器来部署后端软件或您需要一些计算能力强大的服务器，您就会用到安全 shell（SSH）。和其他工具一样，SSH 也是可以高度定制的，也值得我们花时间学习它。

To `ssh` into a server you execute a command as follows

> 通过如下命令，您可以使用 `ssh` 连接到其他服务器：

```
ssh foo@bar.mit.edu
```

Here we are trying to ssh as user `foo` in server `bar.mit.edu`. The server can be specified with a URL (like `bar.mit.edu`) or an IP (something like `foobar@192.168.1.42`). Later we will see that if we modify ssh config file you can access just using something like `ssh bar`.

> 这里我们尝试以用户名 `foo` 登录服务器 `bar.mit.edu`。服务器可以通过 URL 指定（例如`bar.mit.edu`），也可以使用 IP 指定（例如`foobar@192.168.1.42`）。后面我们会介绍如何修改 ssh 配置文件使我们可以用类似 `ssh bar` 这样的命令来登录服务器。

<img src="./Command-line Environment/Screenshot 2023-12-09 at 11.44.56-3323701.png" alt="Screenshot 2023-12-09 at 11.44.56" />

<img src="./Command-line Environment/Screenshot 2023-12-09 at 11.46.05-3323701.png" alt="Screenshot 2023-12-09 at 11.46.05" />



## Executing commands

An often overlooked feature of `ssh` is the ability to run commands directly. `ssh foobar@server ls` will execute `ls` in the home folder of foobar. It works with pipes, so `ssh foobar@server ls | grep PATTERN` will grep locally the remote output of `ls` and `ls | ssh foobar@server grep PATTERN` will grep remotely the local output of `ls`.

> `ssh` 的一个经常被忽视的特性是它可以直接远程执行命令。 `ssh foobar@server ls` 可以直接在用foobar的命令下执行 `ls` 命令。 想要配合管道来使用也可以， `ssh foobar@server ls | grep PATTERN` 会在本地查询远端 `ls` 的输出而 `ls | ssh foobar@server grep PATTERN` 会在远端对本地 `ls` 输出的结果进行查询。

## SSH Keys

Key-based authentication exploits public-key cryptography to prove to the server that the client owns the secret private key without revealing the key. This way you do not need to reenter your password every time. Nevertheless, the private key (often `~/.ssh/id_rsa` and more recently `~/.ssh/id_ed25519`) is effectively your password, so treat it like so.

> 基于密钥的验证机制使用了密码学中的公钥，我们只需要向服务器证明客户端持有对应的私钥，而不需要公开其私钥。这样您就可以避免每次登录都输入密码的麻烦了秘密就可以登录。不过，私钥(通常是 `~/.ssh/id_rsa` 或者 `~/.ssh/id_ed25519`) 等效于您的密码，所以一定要好好保存它。

### Key generation

To generate a pair you can run [`ssh-keygen`](https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html).

> 使用 [`ssh-keygen`](http://man7.org/linux/man-pages/man1/ssh-keygen.1.html) 命令可以生成一对密钥：

```
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519
```

You should choose a passphrase, to avoid someone who gets hold of your private key to access authorized servers. Use [`ssh-agent`](https://www.man7.org/linux/man-pages/man1/ssh-agent.1.html) or [`gpg-agent`](https://linux.die.net/man/1/gpg-agent) so you do not have to type your passphrase every time.

> 您可以为密钥设置密码，防止有人持有您的私钥并使用它访问您的服务器。您可以使用 [`ssh-agent`](https://www.man7.org/linux/man-pages/man1/ssh-agent.1.html) 或 [`gpg-agent`](https://linux.die.net/man/1/gpg-agent) ，这样就不需要每次都输入该密码了。

If you have ever configured pushing to GitHub using SSH keys, then you have probably done the steps outlined [here](https://help.github.com/articles/connecting-to-github-with-ssh/) and have a valid key pair already. To check if you have a passphrase and validate it you can run `ssh-keygen -y -f /path/to/key`.

> 如果您曾经配置过使用 SSH 密钥推送到 GitHub，那么可能您已经完成了[这里](https://help.github.com/articles/connecting-to-github-with-ssh/) 介绍的这些步骤，并且已经有了一个可用的密钥对。要检查您是否持有密码并验证它，您可以运行 `ssh-keygen -y -f /path/to/key`.

### Key based authentication

`ssh` will look into `.ssh/authorized_keys` to determine which clients it should let in. To copy a public key over you can use:

> `ssh` 会查询 `.ssh/authorized_keys` 来确认那些用户可以被允许登录。您可以通过下面的命令将一个公钥拷贝到这里：

```
cat .ssh/id_ed25519.pub | ssh foobar@remote 'cat >> ~/.ssh/authorized_keys'
```

A simpler solution can be achieved with `ssh-copy-id` where available:

> 如果支持 `ssh-copy-id` 的话，可以使用下面这种更简单的解决方案：

```
ssh-copy-id -i .ssh/id_ed25519 foobar@remote
```



## Copying files over SSH

There are many ways to copy files over ssh:

- `ssh+tee`, the simplest is to use `ssh` command execution and STDIN input by doing `cat localfile | ssh remote_server tee serverfile`. Recall that [`tee`](https://www.man7.org/linux/man-pages/man1/tee.1.html) writes the output from STDIN into a file.

  > `ssh+tee`, 最简单的方法是执行 `ssh` 命令，然后通过这样的方法利用标准输入实现 `cat localfile | ssh remote_server tee serverfile`。回忆一下，[`tee`](https://www.man7.org/linux/man-pages/man1/tee.1.html) 命令会将标准输出写入到一个文件；

- [`scp`](https://www.man7.org/linux/man-pages/man1/scp.1.html) when copying large amounts of files/directories, the secure copy `scp` command is more convenient since it can easily recurse over paths. The syntax is `scp path/to/local_file remote_host:path/to/remote_file`

  > 当需要拷贝大量的文件或目录时，使用`scp` 命令则更加方便，因为它可以方便的遍历相关路径。语法如下：`scp path/to/local_file remote_host:path/to/remote_file`；

- [`rsync`](https://www.man7.org/linux/man-pages/man1/rsync.1.html) improves upon `scp` by detecting identical files in local and remote, and preventing copying them again. It also provides more fine grained control over symlinks, permissions and has extra features like the `--partial` flag that can resume from a previously interrupted copy. `rsync` has a similar syntax to `scp`.

  > [`rsync`](https://www.man7.org/linux/man-pages/man1/rsync.1.html) 对 `scp` 进行了改进，它可以检测本地和远端的文件以防止重复拷贝。它还可以提供一些诸如符号连接、权限管理等精心打磨的功能。甚至还可以基于 `--partial`标记实现断点续传。`rsync` 的语法和`scp`类似；

> <img src="./Command-line Environment/Screenshot 2023-12-09 at 12.20.41-3323701.png" alt="Screenshot 2023-12-09 at 12.20.41" />



## Port Forwarding

In many scenarios you will run into software that listens to specific ports in the machine. When this happens in your local machine you can type `localhost:PORT` or `127.0.0.1:PORT`, but what do you do with a remote server that does not have its ports directly available through the network/internet?.

> 很多情况下我们都会遇到软件需要监听特定设备的端口。如果是在您的本机，可以使用 `localhost:PORT` 或 `127.0.0.1:PORT`。但是如果需要监听远程服务器的端口该如何操作呢？这种情况下远端的端口并不会直接通过网络暴露给您。

This is called *port forwarding* and it comes in two flavors: Local Port Forwarding and Remote Port Forwarding (see the pictures for more details, credit of the pictures from [this StackOverflow post](https://unix.stackexchange.com/questions/115897/whats-ssh-port-forwarding-and-whats-the-difference-between-ssh-local-and-remot)).

> 此时就需要进行 *端口转发*。端口转发有两种，一种是本地端口转发和远程端口转发（参见下图，该图片引用自这篇[StackOverflow 文章](https://unix.stackexchange.com/questions/115897/whats-ssh-port-forwarding-and-whats-the-difference-between-ssh-local-and-remot)）中的图片。

**Local Port Forwarding**<img src="./Command-line Environment/a28N8-3323701.png" alt="Local Port Forwarding" />

**Remote Port Forwarding**<img src="./Command-line Environment/4iK3b-3323701.png" alt="Remote Port Forwarding" />

The most common scenario is local port forwarding, where a service in the remote machine listens in a port and you want to link a port in your local machine to forward to the remote port. For example, if we execute `jupyter notebook` in the remote server that listens to the port `8888`. Thus, to forward that to the local port `9999`, we would do `ssh -L 9999:localhost:8888 foobar@remote_server` and then navigate to `localhost:9999` in our local machine.

> 常见的情景是使用本地端口转发，即远端设备上的服务监听一个端口，而您希望在本地设备上的一个端口建立连接并转发到远程端口上。例如，我们在远端服务器上运行 Jupyter notebook 并监听 `8888` 端口。 然后，建立从本地端口 `9999` 的转发，使用 `ssh -L 9999:localhost:8888 foobar@remote_server` 。这样只需要访问本地的 `localhost:9999` 即可。

## SSH Configuration

We have covered many many arguments that we can pass. A tempting alternative is to create shell aliases that look like

> 我们已经介绍了很多参数。为它们创建一个别名是个好想法，我们可以这样做：

```
alias my_server="ssh -i ~/.id_ed25519 --port 2222 -L 9999:localhost:8888 foobar@remote_server
```

However, there is a better alternative using `~/.ssh/config`.

> 不过，更好的方法是使用 `~/.ssh/config`.

```
Host vm
    User foobar
    HostName 172.16.174.141
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 9999 localhost:8888

# Configs can also take wildcards
Host *.mit.edu
    User foobaz
```

An additional advantage of using the `~/.ssh/config` file over aliases is that other programs like `scp`, `rsync`, `mosh`, &c are able to read it as well and convert the settings into the corresponding flags.

> 这么做的好处是，使用 `~/.ssh/config` 文件来创建别名，类似 `scp`、`rsync`和`mosh`的这些命令都可以读取这个配置并将设置转换为对应的命令行选项。

Note that the `~/.ssh/config` file can be considered a dotfile, and in general it is fine for it to be included with the rest of your dotfiles. However, if you make it public, think about the information that you are potentially providing strangers on the internet: addresses of your servers, users, open ports, &c. This may facilitate some types of attacks so be thoughtful about sharing your SSH configuration.

> 注意，`~/.ssh/config` 文件也可以被当作配置文件，而且一般情况下也是可以被导入其他配置文件的。不过，如果您将其公开到互联网上，那么其他人都将会看到您的服务器地址、用户名、开放端口等等。这些信息可能会帮助到那些企图攻击您系统的黑客，所以请务必三思。

Server side configuration is usually specified in `/etc/ssh/sshd_config`. Here you can make changes like disabling password authentication, changing ssh ports, enabling X11 forwarding, &c. You can specify config settings on a per user basis.

> 服务器侧的配置通常放在 `/etc/ssh/sshd_config`。您可以在这里配置免密认证、修改 ssh 端口、开启 X11 转发等等。 您也可以为每个用户单独指定配置。

<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.33.26-3323701.png" alt="Screenshot 2023-12-09 at 12.33.26" />

<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.32.11-3323701.png" alt="Screenshot 2023-12-09 at 12.32.11" />

<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.34.16-3323701.png" alt="Screenshot 2023-12-09 at 12.34.16" />

## Miscellaneous

A common pain when connecting to a remote server are disconnections due to your computer shutting down, going to sleep, or changing networks. Moreover if one has a connection with significant lag using ssh can become quite frustrating. [Mosh](https://mosh.org/), the mobile shell, improves upon ssh, allowing roaming connections, intermittent connectivity and providing intelligent local echo.

> 连接远程服务器的一个常见痛点是遇到由关机、休眠或网络环境变化导致的掉线。如果连接的延迟很高也很让人讨厌。[Mosh](https://mosh.org/)（即 mobile shell ）对 ssh 进行了改进，它允许连接漫游、间歇连接及智能本地回显。

Sometimes it is convenient to mount a remote folder. [sshfs](https://github.com/libfuse/sshfs) can mount a folder on a remote server locally, and then you can use a local editor.

> 有时将一个远端文件夹挂载到本地会比较方便， [sshfs](https://github.com/libfuse/sshfs) 可以将远端服务器上的一个文件夹挂载到本地，然后您就可以使用本地的编辑器了。



<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.38.26-3323701.png" alt="Screenshot 2023-12-09 at 12.38.26" />

<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.39.17-3323701.png" alt="Screenshot 2023-12-09 at 12.39.17" />

<img src="./Command-line Environment/Screenshot 2023-12-09 at 12.39.34-3323701.png" alt="Screenshot 2023-12-09 at 12.39.34" />

这与你离开时候的状态一摸一样

# Shells & Frameworks

During shell tool and scripting we covered the `bash` shell because it is by far the most ubiquitous shell and most systems have it as the default option. Nevertheless, it is not the only option.

> 在 shell 工具和脚本那节课中我们已经介绍了 `bash` shell，因为它是目前最通用的 shell，大多数的系统都将其作为默认 shell。但是，它并不是唯一的选项。

For example, the `zsh` shell is a superset of `bash` and provides many convenient features out of the box such as:

> 例如，`zsh` shell 是 `bash` 的超集并提供了一些方便的功能：

- Smarter globbing, `**`
- Inline globbing/wildcard expansion
- Spelling correction
- Better tab completion/selection
- Path expansion (`cd /u/lo/b` will expand as `/usr/local/bin`)

**Frameworks** can improve your shell as well. Some popular general frameworks are [prezto](https://github.com/sorin-ionescu/prezto) or [oh-my-zsh](https://ohmyz.sh/), and smaller ones that focus on specific features such as [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) or [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search). Shells like [fish](https://fishshell.com/) include many of these user-friendly features by default. Some of these features include:

> **框架** 也可以改进您的 shell。比较流行的通用框架包括[prezto](https://github.com/sorin-ionescu/prezto) 或 [oh-my-zsh](https://ohmyz.sh/)。还有一些更精简的框架，它们往往专注于某一个特定功能，例如[zsh 语法高亮](https://github.com/zsh-users/zsh-syntax-highlighting) 或 [zsh 历史子串查询](https://github.com/zsh-users/zsh-history-substring-search)。 像 [fish](https://fishshell.com/) 这样的 shell 包含了很多用户友好的功能，其中一些特性包括：

- Right prompt
- Command syntax highlighting
- History substring search
- manpage based flag completions
- Smarter autocompletion
- Prompt themes

One thing to note when using these frameworks is that they may slow down your shell, especially if the code they run is not properly optimized or it is too much code. You can always profile it and disable the features that you do not use often or value over speed.

> 需要注意的是，使用这些框架可能会降低您 shell 的性能，尤其是如果这些框架的代码没有优化或者代码过多。您随时可以测试其性能或禁用某些不常用的功能来实现速度与功能的平衡。

# Terminal Emulators

Along with customizing your shell, it is worth spending some time figuring out your choice of **terminal emulator** and its settings. There are many many terminal emulators out there (here is a [comparison](https://anarc.at/blog/2018-04-12-terminal-emulators-1/)).

> 和自定义 shell 一样，花点时间选择适合您的 **终端模拟器**并进行设置是很有必要的。有许多终端模拟器可供您选择（这里有一些关于它们之间[比较](https://anarc.at/blog/2018-04-12-terminal-emulators-1/)的信息）

Since you might be spending hundreds to thousands of hours in your terminal it pays off to look into its settings. Some of the aspects that you may want to modify in your terminal include:

> 您会花上很多时间在使用终端上，因此研究一下终端的设置是很有必要的，您可以从下面这些方面来配置您的终端：

- Font choice
- Color Scheme
- Keyboard shortcuts
- Tab/Pane support
- Scrollback configuration
- Performance (some newer terminals like [Alacritty](https://github.com/jwilm/alacritty) or [kitty](https://sw.kovidgoyal.net/kitty/) offer GPU acceleration).



# Exercises

## Job control

1. From what we have seen, we can use some `ps aux | grep` commands to get our jobs’ pids and then kill them, but there are better ways to do it. Start a `sleep 10000` job in a terminal, background it with `Ctrl-Z` and continue its execution with `bg`. Now use [`pgrep`](https://www.man7.org/linux/man-pages/man1/pgrep.1.html) to find its pid and [`pkill`](http://man7.org/linux/man-pages/man1/pgrep.1.html) to kill it without ever typing the pid itself. (Hint: use the `-af` flags).

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 12.54.19-3323701.png" alt="Screenshot 2023-12-09 at 12.54.19" />

   > `pgrep sleep` : 列出包含关键字 sleep 的进程的 `pid`
   >
   > `pgrep sleep 10000` : 列出包含关键字 sleep 的进程的 `pid`
   >
   > `-a`:  Include process ancestors in the match list.  By default, the current pgrep or pkill process and all of its ancestors are excluded (unless -v is used).
   >
   > `-f`:  Match against full argument lists. The default is to match against process names.

2. Say you don’t want to start a process until another completes. How would you go about it? In this exercise, our limiting process will always be `sleep 60 &`. One way to achieve this is to use the [`wait`](https://www.man7.org/linux/man-pages/man1/wait.1p.html) command. Try launching the sleep command and having an `ls` wait until the background process finishes.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 12.59.00-3323701.png" alt="Screenshot 2023-12-09 at 12.59.00" />

   However, this strategy will fail if we start in a different bash session, since `wait` only works for child processes. One feature we did not discuss in the notes is that the `kill` command’s exit status will be zero on success and nonzero otherwise. `kill -0` does not send a signal but will give a nonzero exit status if the process does not exist. Write a bash function called `pidwait` that takes a pid and waits until the given process completes. You should use `sleep` to avoid wasting CPU unnecessarily.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 13.03.11-3323701.png" alt="Screenshot 2023-12-09 at 13.03.11" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 13.06.19-3323701.png" alt="Screenshot 2023-12-09 at 13.06.19" />

## Terminal multiplexer

1. Follow this `tmux` [tutorial](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) and then learn how to do some basic customizations following [these steps](https://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/).

## Aliases

1. Create an alias `dc` that resolves to `cd` for when you type it wrongly.
2. Run `history | awk '{$1="";print substr($0,2)}' | sort | uniq -c | sort -n | tail -n 10` to get your top 10 most used commands and consider writing shorter aliases for them. Note: this works for Bash; if you’re using ZSH, use `history 1` instead of just `history`.

<img src="./Command-line Environment/Screenshot 2023-12-09 at 13.07.38-3323701.png" alt="Screenshot 2023-12-09 at 13.07.38" />

## Dotfiles

Let’s get you up to speed with dotfiles.

1. Create a folder for your dotfiles and set up version control.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.31.03-3323701.png" alt="Screenshot 2023-12-09 at 15.31.03" />

2. Add a configuration for at least one program, e.g. your shell, with some customization (to start off, it can be something as simple as customizing your shell prompt by setting `$PS1`).

    

    

3. Set up a method to install your dotfiles quickly (and without manual effort) on a new machine. This can be as simple as a shell script that calls `ln -s` for each file, or you could use a [specialized utility](https://dotfiles.github.io/utilities/).

    

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.35.09-3323701.png" alt="Screenshot 2023-12-09 at 13.18.28" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.45.36-3323701.png" alt="Screenshot 2023-12-09 at 15.45.36" />

   

4. Test your installation script on a fresh virtual machine.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.48.51-3323701.png" alt="Screenshot 2023-12-09 at 15.48.51" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.53.06-3323701.png" alt="Screenshot 2023-12-09 at 15.53.06" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.53.20-3323701.png" alt="Screenshot 2023-12-09 at 15.53.20" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.53.52-3323701.png" alt="Screenshot 2023-12-09 at 15.53.52" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.54.18-3323701.png" alt="Screenshot 2023-12-09 at 15.54.18" />

5. Migrate all of your current tool configurations to your dotfiles repository.

6. Publish your dotfiles on GitHub.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.55.23-3323701.png" alt="Screenshot 2023-12-09 at 15.55.23" />

## Remote Machines

Install a Linux virtual machine (or use an already existing one) for this exercise. If you are not familiar with virtual machines check out [this](https://hibbard.eu/install-ubuntu-virtual-box/) tutorial for installing one.

1. Go to `~/.ssh/` and check if you have a pair of SSH keys there. If not, generate them with `ssh-keygen -o -a 100 -t ed25519`. It is recommended that you use a password and use `ssh-agent` , more info [here](https://www.ssh.com/ssh/agent).

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 13.58.34-3323701.png" alt="Screenshot 2023-12-09 at 13.58.34" />

2. Edit `.ssh/config` to have an entry as follows

   ```
    Host vm
        User username_goes_here
        HostName ip_goes_here
        IdentityFile ~/.ssh/id_ed25519
        LocalForward 9999 localhost:8888
   ```

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 13.59.34-3323701.png" alt="Screenshot 2023-12-09 at 13.59.34" />

3. Use `ssh-copy-id vm` to copy your ssh key to the server.

   `brew install ssh-copy-id`

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.07.42-3323701.png" alt="Screenshot 2023-12-09 at 14.07.42" />

4. Start a webserver in your VM by executing `python -m http.server 8888`. Access the VM webserver by navigating to `http://localhost:9999` in your machine.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.10.36-3323701.png" alt="Screenshot 2023-12-09 at 14.10.36" />

5. Edit your SSH server config by doing `sudo vim /etc/ssh/sshd_config` and disable password authentication by editing the value of `PasswordAuthentication`. Disable root login by editing the value of `PermitRootLogin`. Restart the `ssh` service with `sudo service sshd restart`. Try sshing in again.

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.30.49.png" alt="Screenshot 2023-12-09 at 14.30.49" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.29.42-3323701.png" alt="Screenshot 2023-12-09 at 14.29.42" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.34.48-3323701.png" alt="Screenshot 2023-12-09 at 14.34.16" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.38.31-3323701.png" alt="Screenshot 2023-12-09 at 14.38.31" />

   

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.25.16-3323701.png" alt="Screenshot 2023-12-09 at 14.25.16" />

   

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.37.38-3323701.png" alt="Screenshot 2023-12-09 at 14.37.38" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.40.16-3323701.png" alt="Screenshot 2023-12-09 at 14.40.16" />

   Delete the root user: `sudo passwd -dl root`

6. (Challenge) Install [`mosh`](https://mosh.org/) in the VM and establish a connection. Then disconnect the network adapter of the server/VM. Can mosh properly recover from it?

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 14.44.19-3323701.png" alt="Screenshot 2023-12-09 at 14.44.19" />

   

   `brew install mosh`

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.21.57.png" alt="Screenshot 2023-12-09 at 15.21.57" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.23.17-3323701.png" alt="Screenshot 2023-12-09 at 15.23.17" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.22.53.png" alt="Screenshot 2023-12-09 at 15.22.53" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.23.48.png" alt="Screenshot 2023-12-09 at 15.23.48" />

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.23.54.png" alt="Screenshot 2023-12-09 at 15.23.54" />

7. (Challenge) Look into what the `-N` and `-f` flags do in `ssh` and figure out a command to achieve background port forwarding.

   `ssh -N -f -L local_port:remote_address:remote_port user@ssh_server`

   <img src="./Command-line Environment/Screenshot 2023-12-09 at 15.18.15.png" alt="Screenshot 2023-12-09 at 15.18.15" />

