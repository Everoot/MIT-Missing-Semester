# Data Wrangling

> I use Parallels Desktop with Ubuntu 22.04 ARM64 and use the mac terminal to connect to it. <img src="./Data Wrangling/Screenshot 2023-11-29 at 10.55.25.png" alt="Screenshot 2023-11-29 at 10.55.25" />

https://youtu.be/sz_dsktIjt4

Have you ever wanted to take data in one format and turn it into a different format? Of course you have! That, in very general terms, is what this lecture is all about. Specifically, massaging data, whether in text or binary format, until you end up with exactly what you wanted.

> 您是否曾经有过这样的需求，将某种格式存储的数据转换成另外一种格式? 肯定有过，对吧！ 这也正是我们这节课所要讲授的主要内容。具体来讲，我们需要不断地对数据进行处理，直到得到我们想要的最终结果。

We’ve already seen some basic data wrangling in past lectures. Pretty much any time you use the `|` operator, you are performing some kind of data wrangling. Consider a command like `journalctl | grep -i intel`. It finds all system log entries that mention Intel (case insensitive). You may not think of it as wrangling data, but it is going from one format (your entire system log) to a format that is more useful to you (just the intel log entries). Most data wrangling is about knowing what tools you have at your disposal, and how to combine them.

> 在之前的课程中，其实我们已经接触到了一些数据整理的基本技术。可以这么说，每当您使用管道运算符的时候，其实就是在进行某种形式的数据整理。例如这样一条命令 `journalctl | grep -i intel`，它会找到所有包含intel(不区分大小写)的系统日志。您可能并不认为这是数据整理，但是它确实将某种形式的数据（全部系统日志）转换成了另外一种形式的数据（仅包含intel的日志）。大多数情况下，数据整理需要您能够明确哪些工具可以被用来达成特定数据整理的目的，并且明白如何组合使用这些工具。

Let’s start from the beginning. To wrangle data, we need two things: data to wrangle, and something to do with it. Logs often make for a good use-case, because you often want to investigate things about them, and reading the whole thing isn’t feasible. Let’s figure out who’s trying to log into my server by looking at my server’s log:

> 让我们从头讲起。既然是学习数据整理，那有两样东西自然是必不可少的：用来整理的数据以及相关的应用场景。日志处理通常是一个比较典型的使用场景，因为我们经常需要在日志中查找某些信息，这种情况下通读日志是不现实的。现在，让我们研究一下系统日志，看看哪些用户曾经尝试过登录我们的服务器：

```
ssh myserver journalctl
```

> ```
> ssh parallels@10.211.55.4 journalctl
> ```
>
> 
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 10.56.49.png" alt="Screenshot 2023-11-29 at 10.56.49" />

That’s far too much stuff. Let’s limit it to ssh stuff:

> 内容太多了。现在让我们把涉及 sshd 的信息过滤出来：

```
ssh myserver journalctl | grep sshd
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 10.59.47.png" alt="Screenshot 2023-11-29 at 10.59.47" />

Notice that we’re using a pipe to stream a *remote* file through `grep` on our local computer! `ssh` is magical, and we will talk more about it in the next lecture on the command-line environment. This is still way more stuff than we wanted though. And pretty hard to read. Let’s do better:

> 注意，这里我们使用管道将一个远程服务器上的文件传递给本机的 `grep` 程序！ `ssh` 太牛了，下一节课我们会讲授命令行环境，届时我们会详细讨论 `ssh` 的相关内容。此时我们打印出的内容，仍然比我们需要的要多得多，读起来也非常费劲。我们来改进一下：

```
ssh myserver 'journalctl | grep sshd | grep "Disconnected from"' | less
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.03.16.png" alt="Screenshot 2023-11-29 at 11.03.16" />

Why the additional quoting? Well, our logs may be quite large, and it’s wasteful to stream it all to our computer and then do the filtering. Instead, we can do the filtering on the remote server, and then massage the data locally. `less` gives us a “pager” that allows us to scroll up and down through the long output. To save some additional traffic while we debug our command-line, we can even stick the current filtered logs into a file so that we don’t have to access the network while developing:

> 多出来的引号是什么作用呢？这么说吧，我们的日志是一个非常大的文件，把这么大的文件流直接传输到我们本地的电脑上再进行过滤是对流量的一种浪费。因此我们采取另外一种方式，我们先在远端机器上过滤文本内容，然后再将结果传输到本机。 `less` 为我们创建来一个文件分页器，使我们可以通过翻页的方式浏览较长的文本。为了进一步节省流量，我们甚至可以将当前过滤出的日志保存到文件中，这样后续就不需要再次通过网络访问该文件了：

```
$ ssh myserver 'journalctl | grep sshd | grep "Disconnected from"' > ssh.log
$ less ssh.log
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.07.41.png" alt="Screenshot 2023-11-29 at 11.07.41" />
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.07.29.png" alt="Screenshot 2023-11-29 at 11.07.29" />

There’s still a lot of noise here. There are *a lot* of ways to get rid of that, but let’s look at one of the most powerful tools in your toolkit: `sed`.

> 过滤结果中仍然包含不少没用的数据。我们有很多办法可以删除这些无用的数据，但是让我们先研究一下 `sed` 这个非常强大的工具。

`sed` is a “stream editor” that builds on top of the old `ed` editor. In it, you basically give short commands for how to modify the file, rather than manipulate its contents directly (although you can do that too). There are tons of commands, but one of the most common ones is `s`: substitution. For example, we can write:

> `sed` 是一个基于文本编辑器`ed`构建的”流编辑器” 。在 `sed` 中，您基本上是利用一些简短的命令来修改文件，而不是直接操作文件的内容（尽管您也可以选择这样做）。相关的命令行非常多，但是最常用的是 `s`，即*替换*命令，例如我们可以这样写：

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed 's/.*Disconnected from //'
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.13.49.png" alt="Screenshot 2023-11-29 at 11.13.49" />

What we just wrote was a simple *regular expression*; a powerful construct that lets you match text against patterns. The `s` command is written on the form: `s/REGEX/SUBSTITUTION/`, where `REGEX` is the regular expression you want to search for, and `SUBSTITUTION` is the text you want to substitute matching text with.

> 上面这段命令中，我们使用了一段简单的*正则表达式*。正则表达式是一种非常强大的工具，可以让我们基于某种模式来对字符串进行匹配。`s` 命令的语法如下：`s/REGEX/SUBSTITUTION/`, 其中 `REGEX` 部分是我们需要使用的正则表达式，而 `SUBSTITUTION` 是用于替换匹配结果的文本。

(You may recognize this syntax from the “Search and replace” section of our Vim [lecture notes](https://missing.csail.mit.edu/2020/editors/#advanced-vim)! Indeed, Vim uses a syntax for searching and replacing that is similar to `sed`’s substitution command. Learning one tool often helps you become more proficient with others.)

> (您可能在Vim[课堂笔记](https://missing.csail.mit.edu/2020/editors/#advanced-vim)的“搜索和替换”部分中认识这种语法!实际上，Vim使用的搜索和替换语法类似于`sed`的替换命令。学习一种工具通常可以帮助你更熟练地使用其他工具。)



## Regular expressions

Regular expressions are common and useful enough that it’s worthwhile to take some time to understand how they work. Let’s start by looking at the one we used above: `/.*Disconnected from /`. Regular expressions are usually (though not always) surrounded by `/`. Most ASCII characters just carry their normal meaning, but some characters have “special” matching behavior. Exactly which characters do what vary somewhat between different implementations of regular expressions, which is a source of great frustration. Very common patterns are:

> 正则表达式非常常见也非常有用，值得您花些时间去理解它。让我们从这一句正则表达式开始学习： `/.*Disconnected from /`。正则表达式通常以（尽管并不总是） `/`开始和结束。大多数的 ASCII 字符都表示它们本来的含义，但是有一些字符确实具有表示匹配行为的“特殊”含义。不同字符所表示的含义，根据正则表达式的实现方式不同，也会有所变化，这一点确实令人沮丧。常见的模式有：

- `.` means “any single character” except newline
- `*` zero or more of the preceding match
- `+` one or more of the preceding match
- `[abc]` any one character of `a`, `b`, and `c`
- `(RX1|RX2)` either something that matches `RX1` or `RX2`
- `^` the start of the line
- `$` the end of the line

> - `.` 除换行符之外的”任意单个字符”
> - `*` 匹配前面字符零次或多次
> - `+` 匹配前面字符一次或多次
> - `[abc]` 匹配 `a`, `b` 和 `c` 中的任意一个
> - `(RX1|RX2)` 任何能够匹配`RX1` 或 `RX2`的结果
> - `^` 行首
> - `$` 行尾

`sed`’s regular expressions are somewhat weird, and will require you to put a `\` before most of these to give them their special meaning. Or you can pass `-E`.

> `sed` 的正则表达式有些时候是比较奇怪的，它需要你在这些模式前添加`\`才能使其具有特殊含义。或者，您也可以添加`-E`选项来支持这些匹配。
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.25.22.png" alt="Screenshot 2023-11-29 at 11.25.22" />

So, looking back at `/.*Disconnected from /`, we see that it matches any text that starts with any number of characters, followed by the literal string “Disconnected from ”. Which is what we wanted. But beware, regular expressions are tricky. What if someone tried to log in with the username “Disconnected from”? We’d have:

> 回过头我们再看`/.*Disconnected from /`，我们会发现这个正则表达式可以匹配任何以若干任意字符开头，并接着包含”Disconnected from “的字符串。这也正式我们所希望的。但是请注意，正则表达式并不容易写对。如果有人将 “Disconnected from” 作为自己的用户名会怎样呢？

```
Jan 17 03:13:00 thesquareplanet.com sshd[2631]: Disconnected from invalid user Disconnected from 46.97.239.16 port 55920 [preauth]
```

What would we end up with? Well, `*` and `+` are, by default, “greedy”. They will match as much text as they can. So, in the above, we’d end up with just

> 正则表达式会如何匹配？`*` 和 `+` 在默认情况下是贪婪模式，也就是说，它们会尽可能多的匹配文本。因此对上述字符串的匹配结果如下：

```
46.97.239.16 port 55920 [preauth]
```

Which may not be what we wanted. In some regular expression implementations, you can just suffix `*` or `+` with a `?` to make them non-greedy, but sadly `sed` doesn’t support that. We *could* switch to perl’s command-line mode though, which *does* support that construct:

> 这可不是我们想要的结果。对于某些正则表达式的实现来说，您可以给 `*` 或 `+` 增加一个`?` 后缀使其变成非贪婪模式，但是很可惜 `sed` 并不支持该后缀。不过，我们可以切换到 perl 的命令行模式，该模式支持编写这样的正则表达式：

```
perl -pe 's/.*?Disconnected from //'
```

We’ll stick to `sed` for the rest of this, because it’s by far the more common tool for these kinds of jobs. `sed` can also do other handy things like print lines following a given match, do multiple substitutions per invocation, search for things, etc. But we won’t cover that too much here. `sed` is basically an entire topic in and of itself, but there are often better tools.

> 让我们回到 `sed` 命令并使用它完成后续的任务，毕竟对于这一类任务，`sed`是最常见的工具。`sed` 还可以非常方便的做一些事情，例如打印匹配后的内容，一次调用中进行多次替换搜索等。但是这些内容我们并不会在此进行介绍。`sed` 本身是一个非常全能的工具，但是在具体功能上往往能找到更好的工具作为替代品。

Okay, so we also have a suffix we’d like to get rid of. How might we do that? It’s a little tricky to match just the text that follows the username, especially if the username can have spaces and such! What we need to do is match the *whole* line:

> 好的，我们还需要去掉用户名后面的后缀，应该如何操作呢？想要匹配用户名后面的文本，尤其是当这里的用户名可以包含空格时，这个问题变得非常棘手！这里我们需要做的是匹配*一整行*：

```
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user .* [^ ]+ port [0-9]+( \[preauth\])?$//'
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.43.48.png" alt="Screenshot 2023-11-29 at 11.43.48" />

Let’s look at what’s going on with a [regex debugger](https://regex101.com/r/qqbZqh/2). Okay, so the start is still as before. Then, we’re matching any of the “user” variants (there are two prefixes in the logs). Then we’re matching on any string of characters where the username is. Then we’re matching on any single word (`[^ ]+`; any non-empty sequence of non-space characters). Then the word “port” followed by a sequence of digits. Then possibly the suffix `[preauth]`, and then the end of the line.

> 让我们借助正则表达式在线调试工具[regex debugger](https://regex101.com/r/qqbZqh/2) 来理解这段表达式。OK，开始的部分和以前是一样的，随后，我们匹配两种类型的“user”（在日志中基于两种前缀区分）。再然后我们匹配属于用户名的所有字符。接着，再匹配任意一个单词（`[^ ]+` 会匹配任意非空且不包含空格的序列）。紧接着后面匹配单“port”和它后面的一串数字，以及可能存在的后缀`[preauth]`，最后再匹配行尾。
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 11.45.39.png" alt="Screenshot 2023-11-29 at 11.45.39" />

Notice that with this technique, as username of “Disconnected from” won’t confuse us any more. Can you see why?

> 注意，这样做的话，即使用户名是“Disconnected from”，对匹配结果也不会有任何影响，您知道这是为什么吗？

There is one problem with this though, and that is that the entire log becomes empty. We want to *keep* the username after all. For this, we can use “capture groups”. Any text matched by a regex surrounded by parentheses is stored in a numbered capture group. These are available in the substitution (and in some engines, even in the pattern itself!) as `\1`, `\2`, `\3`, etc. So:

> 问题还没有完全解决，日志的内容全部被替换成了空字符串，整个日志的内容因此都被删除了。我们实际上希望能够将用户名*保留*下来。对此，我们可以使用“捕获组（capture groups）”来完成。被圆括号内的正则表达式匹配到的文本，都会被存入一系列以编号区分的捕获组中。捕获组的内容可以在替换字符串时使用（有些正则表达式的引擎甚至支持替换表达式本身），例如`\1`、 `\2`、`\3`等等，因此可以使用如下命令： 

```
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
```

As you can probably imagine, you can come up with *really* complicated regular expressions. For example, here’s an article on how you might match an [e-mail address](https://www.regular-expressions.info/email.html). It’s [not easy](https://web.archive.org/web/20221223174323/http://emailregex.com/). And there’s [lots of discussion](https://stackoverflow.com/questions/201323/how-to-validate-an-email-address-using-a-regular-expression/1917982). And people have [written tests](https://fightingforalostcause.net/content/misc/2006/compare-email-regex.php). And [test matrices](https://mathiasbynens.be/demo/url-regex). You can even write a regex for determining if a given number [is a prime number](https://www.noulakaz.net/2007/03/18/a-regular-expression-to-check-for-prime-numbers/).

> 想必您已经意识到了，为了完成某种匹配，我们最终可能会写出非常复杂的正则表达式。例如，这里有一篇关于如何匹配电子邮箱地址的文章[e-mail address](https://www.regular-expressions.info/email.html)，匹配电子邮箱可一点[也不简单](https://emailregex.com/)。网络上还有很多关于如何匹配电子邮箱地址的[讨论](https://stackoverflow.com/questions/201323/how-to-validate-an-email-address-using-a-regular-expression/1917982)。人们还为其编写了[测试用例](https://fightingforalostcause.net/content/misc/2006/compare-email-regex.php)及 [测试矩阵](https://mathiasbynens.be/demo/url-regex)。您甚至可以编写一个用于判断一个数[是否为质数](https://www.noulakaz.net/2007/03/18/a-regular-expression-to-check-for-prime-numbers/)的正则表达式。

Regular expressions are notoriously hard to get right, but they are also very handy to have in your toolbox!

> 正则表达式是出了名的难以写对，但是它仍然会是您强大的常备工具之一。

## Back to data wrangling

Okay, so we now have

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
```

`sed` can do all sorts of other interesting things, like injecting text (with the `i` command), explicitly printing lines (with the `p` command), selecting lines by index, and lots of other things. Check `man sed`!

> `sed` 还可以做很多各种各样有趣的事情，例如文本注入：(使用 `i` 命令)，打印特定的行 (使用 `p`命令)，基于索引选择特定行等等。详情请见`man sed`!

Anyway. What we have now gives us a list of all the usernames that have attempted to log in. But this is pretty unhelpful. Let’s look for common ones:

> 现在，我们已经得到了一个包含用户名的列表，列表中的用户都曾经尝试过登录我们的系统。但这还不够，让我们过滤出那些最常出现的用户：

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
```

`sort` will, well, sort its input. `uniq -c` will collapse consecutive lines that are the same into a single line, prefixed with a count of the number of occurrences. We probably want to sort that too and only keep the most common usernames:

> `sort` 会对其输入数据进行排序。`uniq -c` 会把连续出现的行折叠为一行并使用出现次数作为前缀。我们希望按照出现次数排序，过滤出最常出现的用户名：

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
```

`sort -n` will sort in numeric (instead of lexicographic) order. `-k1,1` means “sort by only the first whitespace-separated column”. The `,n` part says “sort until the `n`th field, where the default is the end of the line. In this *particular* example, sorting by the whole line wouldn’t matter, but we’re here to learn!

> `sort -n` 会按照数字顺序对输入进行排序（默认情况下是按照字典序排序 `-k1,1` 则表示“仅基于以空格分割的第一列进行排序”。`,n` 部分表示“仅排序到第n个部分”，默认情况是到行尾。就本例来说，针对整个行进行排序也没有任何问题，我们这里主要是为了学习这一用法！

If we wanted the *least* common ones, we could use `head` instead of `tail`. There’s also `sort -r`, which sorts in reverse order.

> 如果我们希望得到登录次数最少的用户，我们可以使用 `head` 来代替`tail`。或者使用`sort -r`来进行倒序排序。

Okay, so that’s pretty cool, but what if we’d like these extract only the usernames as a comma-separated list instead of one per line, perhaps for a config file?

> 相当不错。但我们只想获取用户名，而且不要一行一个地显示。

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
 | awk '{print $2}' | paste -sd,
```

If you’re using macOS: note that the command as shown won’t work with the BSD `paste` shipped with macOS. See [exercise 4 from the shell tools lecture](https://missing.csail.mit.edu/2020/shell-tools/#exercises) for more on the difference between BSD and GNU coreutils and instructions for how to install GNU coreutils on macOS.

> 如果您使用的是 MacOS：注意这个命令并不能配合 MacOS 系统默认的 BSD `paste`使用。参考[课程概览与 shell](https://missing-semester-cn.github.io/2020/course-shell/)的习题内容获取更多相关信息。

Let’s start with `paste`: it lets you combine lines (`-s`) by a given single-character delimiter (`-d`; `,` in this case). But what’s this `awk` business?

> 我们可以利用 `paste`命令来合并行(`-s`)，并指定一个分隔符进行分割 (`-d`)，那`awk`的作用又是什么呢？

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 12.17.26.png" alt="Screenshot 2023-11-29 at 12.17.26" />

## awk – another editor

`awk` is a programming language that just happens to be really good at processing text streams. There is *a lot* to say about `awk` if you were to learn it properly, but as with many other things here, we’ll just go through the basics.

> `awk` 其实是一种编程语言，只不过它碰巧非常善于处理文本。关于 `awk` 可以介绍的内容太多了，限于篇幅，这里我们仅介绍一些基础知识。

First, what does `{print $2}` do? Well, `awk` programs take the form of an optional pattern plus a block saying what to do if the pattern matches a given line. The default pattern (which we used above) matches all lines. Inside the block, `$0` is set to the entire line’s contents, and `$1` through `$n` are set to the `n`th *field* of that line, when separated by the `awk` field separator (whitespace by default, change with `-F`). In this case, we’re saying that, for every line, print the contents of the second field, which happens to be the username!

> 首先， `{print $2}` 的作用是什么？ `awk` 程序接受一个模式串（可选），以及一个代码块，指定当模式匹配时应该做何种操作。默认当模式串即匹配所有行（上面命令中当用法）。 在代码块中，`$0` 表示整行的内容，`$1` 到 `$n` 为一行中的 n 个区域，区域的分割基于 `awk` 的域分隔符（默认是空格，可以通过`-F`来修改）。在这个例子中，我们的代码意思是：对于每一行文本，打印其第二个部分，也就是用户名。

Let’s see if we can do something fancier. Let’s compute the number of single-use usernames that start with `c` and end with `e`:

> 让我们康康，还有什么炫酷的操作可以做。让我们统计一下所有以`c` 开头，以 `e` 结尾，并且仅尝试过一次登录的用户。

```
 | awk '$1 == 1 && $2 ~ /^c[^ ]*e$/ { print $2 }' | wc -l
```

There’s a lot to unpack here. First, notice that we now have a pattern (the stuff that goes before `{...}`). The pattern says that the first field of the line should be equal to 1 (that’s the count from `uniq -c`), and that the second field should match the given regular expression. And the block just says to print the username. We then count the number of lines in the output with `wc -l`.

> 让我们好好分析一下。首先，注意这次我们为 `awk`指定了一个匹配模式串（也就是`{...}`前面的那部分内容）。该匹配要求文本的第一部分需要等于1（这部分刚好是`uniq -c`得到的计数值），然后其第二部分必须满足给定的一个正则表达式。代码块中的内容则表示打印用户名。然后我们使用 `wc -l` 统计输出结果的行数。

However, `awk` is a programming language, remember?

> 不过，既然 `awk` 是一种编程语言，那么则可以这样：

```
BEGIN { rows = 0 }
$1 == 1 && $2 ~ /^c[^ ]*e$/ { rows += $1 }
END { print rows }
```

`BEGIN` is a pattern that matches the start of the input (and `END` matches the end). Now, the per-line block just adds the count from the first field (although it’ll always be 1 in this case), and then we print it out at the end. In fact, we *could* get rid of `grep` and `sed` entirely, because `awk` [can do it all](https://backreference.org/2010/02/10/idiomatic-awk/), but we’ll leave that as an exercise to the reader.

> `BEGIN` 也是一种模式，它会匹配输入的开头（ `END` 则匹配结尾）。然后，对每一行第一个部分进行累加，最后将结果输出。事实上，我们完全可以抛弃 `grep` 和 `sed` ，因为 `awk` 就可以[解决所有问题](https://backreference.org/2010/02/10/idiomatic-awk)。至于怎么做，就留给读者们做课后练习吧。

## Analyzing data

You can do math directly in your shell using `bc`, a calculator that can read from STDIN! For example, add the numbers on each line together by concatenating them together, delimited by `+`:

> 想做数学计算也是可以的！例如这样，您可以将每行的数字加起来：

```
 | paste -sd+ | bc -l
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 12.40.46.png" alt="Screenshot 2023-11-29 at 12.40.46" />
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 12.41.23.png" alt="Screenshot 2023-11-29 at 12.41.23" />

Or produce more elaborate expressions:

> 下面这种更加复杂的表达式也可以：

```
echo "2*($(data | paste -sd+))" | bc -l
```

> <img src="./Data Wrangling/Screenshot 2023-11-29 at 12.45.04.png" alt="Screenshot 2023-11-29 at 12.45.04" />

You can get stats in a variety of ways. [`st`](https://github.com/nferraz/st) is pretty neat, but if you already have [R](https://www.r-project.org/):

> 您可以通过多种方式获取统计数据。如果已经安装了R语言，[`st`](https://github.com/nferraz/st)是个不错的选择：

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | awk '{print $1}' | R --no-echo -e 'x <- scan(file="stdin", quiet=TRUE); summary(x)'
```

R is another (weird) programming language that’s great at data analysis and [plotting](https://ggplot2.tidyverse.org/). We won’t go into too much detail, but suffice to say that `summary` prints summary statistics for a vector, and we created a vector containing the input stream of numbers, so R gives us the statistics we wanted!

> R 也是一种编程语言，它非常适合被用来进行数据分析和[绘制图表](https://ggplot2.tidyverse.org/)。这里我们不会讲的特别详细， 您只需要知道`summary` 可以打印某个向量的统计结果。我们将输入的一系列数据存放在一个向量后，利用R语言就可以得到我们想要的统计数据。

> `brew install r`
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 12.58.17.png" alt="Screenshot 2023-11-29 at 12.58.17" />

If you just want some simple plotting, `gnuplot` is your friend:

> 如果您希望绘制一些简单的图表， `gnuplot` 可以帮助到您：

```
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
 | gnuplot -p -e 'set boxwidth 0.5; plot "-" using 1:xtic(2) with boxes'
```

> `brew install gnuplot`
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.02.06.png" alt="Screenshot 2023-11-29 at 13.02.06" />
>
> <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.02.31.png" alt="Screenshot 2023-11-29 at 13.02.31" />

> bug:
>
> ```
> ~ cat ssh.log | sort | uniq -c | awk '$1 != 1 {print $1}' | paste -sd+
> usage: paste [-s] [-d delimiters] file ...
> ```
>
> 问题在于 `paste` 命令期望文件作为输入，但在命令中，它是接收来自管道的数据。
>
> 要解决这个问题，可以通过以下方式修改命令：
>
> ```
> shellCopy code
> cat ssh.log | sort | uniq -c | awk '$1 != 1 {print $1}' | paste -sd+ -
> ```
>
> 这里，`-` 表示 `paste` 命令应该从标准输入（即前面管道中的输出）读取数据，而不是从文件中读取。这样，您的命令应该能够正确执行，并将 `awk` 命令的输出以加号分隔合并为一行。



## Data wrangling to make arguments

Sometimes you want to do data wrangling to find things to install or remove based on some longer list. The data wrangling we’ve talked about so far + `xargs` can be a powerful combo.

> 有时候您要利用数据整理技术从一长串列表里找出你所需要安装或移除的东西。我们之前讨论的相关技术配合 `xargs` 即可实现：

For example, as seen in lecture, I can use the following command to uninstall old nightly builds of Rust from my system by extracting the old build names using data wrangling tools and then passing them via `xargs` to the uninstaller:

```
rustup toolchain list | grep nightly | grep -vE "nightly-x86" | sed 's/-x86.*//' | xargs rustup toolchain uninstall
```

## Wrangling binary data

So far, we have mostly talked about wrangling textual data, but pipes are just as useful for binary data. For example, we can use ffmpeg to capture an image from our camera, convert it to grayscale, compress it, send it to a remote machine over SSH, decompress it there, make a copy, and then display it.

> 虽然到目前为止我们的讨论都是基于文本数据，但对于二进制文件其实同样有用。例如我们可以用 ffmpeg 从相机中捕获一张图片，将其转换成灰度图后通过SSH将压缩后的文件发送到远端服务器，并在那里解压、存档并显示。

```
ffmpeg -loglevel panic -i /dev/video0 -frames 1 -f image2 -
 | convert - -colorspace gray -
 | gzip
 | ssh mymachine 'gzip -d | tee copy.jpg | env DISPLAY=:0 feh -'
```

# Exercises

1. Take this [short interactive regex tutorial](https://regexone.com/).

2. Find the number of words (in `/usr/share/dict/words`) that contain at least three `a`s and don’t have a `'s` ending. 

   What are the three most common last two letters of those words? `sed`’s `y` command, or the `tr` program, may help you with case insensitivity. 

   How many of those two-letter combinations are there? 

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.16.52.png" alt="Screenshot 2023-11-29 at 13.16.52" />

   And for a challenge: which combinations do not occur?

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.45.58.png" alt="Screenshot 2023-11-29 at 13.45.58" />

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.52.02.png" alt="Screenshot 2023-11-29 at 13.52.02" />

   

3. To do in-place substitution it is quite tempting to do something like `sed s/REGEX/SUBSTITUTION/ input.txt > input.txt`. However this is a bad idea, why? Is this particular to `sed`? Use `man sed` to find out how to accomplish this.

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.10.00.png" alt="Screenshot 2023-11-29 at 14.10.00" />

4. Find your average, median, and max system boot time over the last ten boots. Use

   ```plaintext
   journalctl
   ```

   on Linux and

   ```plaintext
   log show
   ```

   on macOS, and look for log timestamps near the beginning and end of each boot. On Linux, they may look something like:

   ```
   Logs begin at ...
   ```

   and

   ```
   systemd[577]: Startup finished in ...
   ```

   On macOS, [look for](https://eclecticlight.co/2018/03/21/macos-unified-log-3-finding-your-way/):

   ```
   === system boot:
   ```

   and

   ```
   Previous shutdown cause: 5
   ```

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 13.56.23.png" alt="Screenshot 2023-11-29 at 13.56.23" />

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.00.24.png" alt="Screenshot 2023-11-29 at 14.00.24" />

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.01.24.png" alt="Screenshot 2023-11-29 at 14.01.24" />

5. Look for boot messages that are *not* shared between your past three reboots (see `journalctl`’s `-b` flag). Break this task down into multiple steps. First, find a way to get just the logs from the past three boots. There may be an applicable flag on the tool you use to extract the boot logs, or you can use `sed '0,/STRING/d'` to remove all lines previous to one that matches `STRING`. Next, remove any parts of the line that *always* varies (like the timestamp). Then, de-duplicate the input lines and keep a count of each one (`uniq` is your friend). And finally, eliminate any line whose count is 3 (since it *was* shared among all the boots).

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.03.44.png" alt="Screenshot 2023-11-29 at 14.03.44" />

6. Find an online data set like [this one](https://stats.wikimedia.org/EN/TablesWikipediaZZ.htm), [this one](https://ucr.fbi.gov/crime-in-the-u.s/2016/crime-in-the-u.s.-2016/topic-pages/tables/table-1), or maybe one [from here](https://www.springboard.com/blog/data-science/free-public-data-sets-data-science-project/). Fetch it using `curl` and extract out just two columns of numerical data. If you’re fetching HTML data, [`pup`](https://github.com/EricChiang/pup) might be helpful. For JSON data, try [`jq`](https://stedolan.github.io/jq/). Find the min and max of one column in a single command, and the difference of the sum of each column in another.

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.11.44.png" alt="Screenshot 2023-11-29 at 14.11.44" />

   <img src="./Data Wrangling/Screenshot 2023-11-29 at 14.12.01.png" alt="Screenshot 2023-11-29 at 14.12.01" />

