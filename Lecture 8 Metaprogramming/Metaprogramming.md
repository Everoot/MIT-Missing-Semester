# Metaprogramming

https://youtu.be/_Ms1Z4xfqv4

What do we mean by “metaprogramming”? Well, it was the best collective term we could come up with for the set of things that are more about *process* than they are about writing code or working more efficiently. In this lecture, we will look at systems for building and testing your code, and for managing dependencies. These may seem like they are of limited importance in your day-to-day as a student, but the moment you interact with a larger code base through an internship or once you enter the “real world”, you will see this everywhere. We should note that “metaprogramming” can also mean “[programs that operate on programs](https://en.wikipedia.org/wiki/Metaprogramming)”, whereas that is not quite the definition we are using for the purposes of this lecture.

> 我们这里说的 “元编程（metaprogramming）” 是什么意思呢？好吧，对于本文要介绍的这些内容，这是我们能够想到的最能概括它们的词。因为我们今天要讲的东西，更多是关于 *流程* ，而不是写代码或更高效的工作。本节课我们会学习构建系统、代码测试以及依赖管理。在您还是学生的时候，这些东西看上去似乎对您来说没那么重要，不过当您开始实习或走进社会的时候，您将会接触到大型的代码库，本节课讲授的这些东西也会变得随处可见。必须要指出的是，“元编程” 也有[用于操作程序的程序](https://en.wikipedia.org/wiki/Metaprogramming)” 之含义，这和我们今天讲座所介绍的概念是完全不同的。

# Build systems

If you write a paper in LaTeX, what are the commands you need to run to produce your paper? What about the ones used to run your benchmarks, plot them, and then insert that plot into your paper? Or to compile the code provided in the class you’re taking and then running the tests?

> 如果您使用 LaTeX 来编写论文，您需要执行哪些命令才能编译出您想要的论文呢？执行基准测试、绘制图表然后将其插入论文的命令又有哪些？或者，如何编译本课程提供的代码并执行测试呢？

For most projects, whether they contain code or not, there is a “build process”. Some sequence of operations you need to do to go from your inputs to your outputs. Often, that process might have many steps, and many branches. Run this to generate this plot, that to generate those results, and something else to produce the final paper. As with so many of the things we have seen in this class, you are not the first to encounter this annoyance, and luckily there exist many tools to help you!

> 对于大多数系统来说，不论其是否包含代码，都会包含一个“构建过程”。有时，您需要执行一系列操作。通常，这一过程包含了很多步骤，很多分支。执行一些命令来生成图表，然后执行另外的一些命令生成结果，然后再执行其他的命令来生成最终的论文。有很多事情需要我们完成，您并不是第一个因此感到苦恼的人，幸运的是，有很多工具可以帮助我们完成这些操作。

These are usually called “build systems”, and there are *many* of them. Which one you use depends on the task at hand, your language of preference, and the size of the project. At their core, they are all very similar though. You define a number of *dependencies*, a number of *targets*, and *rules* for going from one to the other. You tell the build system that you want a particular target, and its job is to find all the transitive dependencies of that target, and then apply the rules to produce intermediate targets all the way until the final target has been produced. Ideally, the build system does this without unnecessarily executing rules for targets whose dependencies haven’t changed and where the result is available from a previous build.

> 这些工具通常被称为 “构建系统”，而且这些工具还不少。如何选择工具完全取决于您当前手头上要完成的任务以及项目的规模。从本质上讲，这些工具都是非常类似的。您需要定义*依赖*、*目标*和*规则*。您必须告诉构建系统您具体的构建目标，系统的任务则是找到构建这些目标所需要的依赖，并根据规则构建所需的中间产物，直到最终目标被构建出来。理想的情况下，如果目标的依赖没有发生改动，并且我们可以从之前的构建中复用这些依赖，那么与其相关的构建规则并不会被执行。

> <img src="./Metaprogramming/Screenshot 2023-12-22 at 19.06.48.png" alt="Screenshot 2023-12-22 at 19.06.48" />

`make` is one of the most common build systems out there, and you will usually find it installed on pretty much any UNIX-based computer. It has its warts, but works quite well for simple-to-moderate projects. When you run `make`, it consults a file called `Makefile` in the current directory. All the targets, their dependencies, and the rules are defined in that file. Let’s take a look at one:

> `make` 是最常用的构建系统之一，您会发现它通常被安装到了几乎所有基于UNIX的系统中。`make`并不完美，但是对于中小型项目来说，它已经足够好了。当您执行 `make` 时，它会去参考当前目录下名为 `Makefile` 的文件。所有构建目标、相关依赖和规则都需要在该文件中定义，它看上去是这样的：

```makefile
paper.pdf: paper.tex plot-data.png
	pdflatex paper.tex

plot-%.png: %.dat plot.py
	./plot.py -i $*.dat -o $@
```

Each directive in this file is a rule for how to produce the left-hand side using the right-hand side. Or, phrased differently, the things named on the right-hand side are dependencies, and the left-hand side is the target. The indented block is a sequence of programs to produce the target from those dependencies. In `make`, the first directive also defines the default goal. If you run `make` with no arguments, this is the target it will build. Alternatively, you can run something like `make plot-data.png`, and it will build that target instead.

> 这个文件中的指令，即如何使用右侧文件构建左侧文件的规则。或者，换句话说，冒号左侧的是构建目标，冒号右侧的是构建它所需的依赖。缩进的部分是从依赖构建目标时需要用到的一段命令。在 `make` 中，第一条指令还指明了构建的目的，如果您使用不带参数的 `make`，这便是我们最终的构建结果。或者，您可以使用这样的命令来构建其他目标：`make plot-data.png`。

The `%` in a rule is a “pattern”, and will match the same string on the left and on the right. For example, if the target `plot-foo.png` is requested, `make` will look for the dependencies `foo.dat` and `plot.py`. Now let’s look at what happens if we run `make` with an empty source directory.

> 规则中的 `%` 是一种模式，它会匹配其左右两侧相同的字符串。例如，如果目标是 `plot-foo.png`， `make` 会去寻找 `foo.dat` 和 `plot.py` 作为依赖。现在，让我们看看如果在一个空的源码目录中执行`make` 会发生什么？

```
$ make
make: *** No rule to make target 'paper.tex', needed by 'paper.pdf'.  Stop.
```

`make` is helpfully telling us that in order to build `paper.pdf`, it needs `paper.tex`, and it has no rule telling it how to make that file. Let’s try making it!

> `make` 会告诉我们，为了构建出`paper.pdf`，它需要 `paper.tex`，但是并没有一条规则能够告诉它如何构建该文件。让我们构建它吧！

```
$ touch paper.tex
$ make
make: *** No rule to make target 'plot-data.png', needed by 'paper.pdf'.  Stop.
```

Hmm, interesting, there *is* a rule to make `plot-data.png`, but it is a pattern rule. Since the source files do not exist (`data.dat`), `make` simply states that it cannot make that file. Let’s try creating all the files:

> 哟，有意思，我们是**有**构建 `plot-data.png` 的规则的，但是这是一条模式规则。因为源文件`data.dat` 并不存在，因此 `make` 就会告诉您它不能构建 `plot-data.png`，让我们创建这些文件：

```shell
$ cat paper.tex
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\includegraphics[scale=0.65]{plot-data.png}
\end{document}
$ cat plot.py
#!/usr/bin/env python
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', type=argparse.FileType('r'))
parser.add_argument('-o')
args = parser.parse_args()

data = np.loadtxt(args.i)
plt.plot(data[:, 0], data[:, 1])
plt.savefig(args.o)
$ cat data.dat
1 1
2 2
3 3
4 4
5 8
```

Now what happens if we run `make`?

> 当我们执行 `make` 时会发生什么？

```shell
$ make
./plot.py -i data.dat -o plot-data.png
pdflatex paper.tex
... lots of output ...
```

> `python3 -m pip install matplotlib`
>
> <img src="./Metaprogramming/Screenshot 2023-12-22 at 19.46.04.png" alt="Screenshot 2023-12-22 at 19.46.04" />

And look, it made a PDF for us! What if we run `make` again?

> 看！PDF ！如果再次执行 `make` 会怎样？

```shell
$ make
make: 'paper.pdf' is up to date.
```

It didn’t do anything! Why not? Well, because it didn’t need to. It checked that all of the previously-built targets were still up to date with respect to their listed dependencies. We can test this by modifying `paper.tex` and then re-running `make`:

> 什么事情都没做！为什么？好吧，因为它什么都不需要做。make回去检查之前的构建是因其依赖改变而需要被更新。让我们试试修改 `paper.tex` 在重新执行 `make`：

```shell
$ vim paper.tex
$ make
pdflatex paper.tex
...
```

Notice that `make` did *not* re-run `plot.py` because that was not necessary; none of `plot-data.png`’s dependencies changed!

> 注意 `make` 并**没有**重新构建 `plot.py`，因为没必要；`plot-data.png` 的所有依赖都没有发生改变。

> <img src="./Metaprogramming/Screenshot 2023-12-22 at 19.53.26.png" alt="Screenshot 2023-12-22 at 19.53.26" />
>
> <img src="./Metaprogramming/Screenshot 2023-12-22 at 19.53.48.png" alt="Screenshot 2023-12-22 at 19.53.48" />
>
> makefile 对空格有严格的要求 需要注意



# Dependency management

At a more macro level, your software projects are likely to have dependencies that are themselves projects. You might depend on installed programs (like `python`), system packages (like `openssl`), or libraries within your programming language (like `matplotlib`). These days, most dependencies will be available through a *repository* that hosts a large number of such dependencies in a single place, and provides a convenient mechanism for installing them. Some examples include the Ubuntu package repositories for Ubuntu system packages, which you access through the `apt` tool, RubyGems for Ruby libraries, PyPi for Python libraries, or the Arch User Repository for Arch Linux user-contributed packages.

> 就您的项目来说，它的依赖可能本身也是其他的项目。您也许会依赖某些程序(例如 `python`)、系统包 (例如 `openssl`)或相关编程语言的库(例如 `matplotlib`)。 现在，大多数的依赖可以通过某些**软件仓库**来获取，这些仓库会在一个地方托管大量的依赖，我们则可以通过一套非常简单的机制来安装依赖。例如 Ubuntu 系统下面有Ubuntu软件包仓库，您可以通过`apt` 这个工具来访问， RubyGems 则包含了 Ruby 的相关库，PyPi 包含了 Python 库， Arch Linux 用户贡献的库则可以在 Arch User Repository 中找到。

Since the exact mechanisms for interacting with these repositories vary a lot from repository to repository and from tool to tool, we won’t go too much into the details of any specific one in this lecture. What we *will* cover is some of the common terminology they all use. The first among these is *versioning*. Most projects that other projects depend on issue a *version number* with every release. Usually something like 8.1.3 or 64.1.20192004. They are often, but not always, numerical. Version numbers serve many purposes, and one of the most important of them is to ensure that software keeps working. Imagine, for example, that I release a new version of my library where I have renamed a particular function. If someone tried to build some software that depends on my library after I release that update, the build might fail because it calls a function that no longer exists! Versioning attempts to solve this problem by letting a project say that it depends on a particular version, or range of versions, of some other project. That way, even if the underlying library changes, dependent software continues building by using an older version of my library.

> 由于每个仓库、每种工具的运行机制都不太一样，因此我们并不会在本节课深入讲解具体的细节。我们会介绍一些通用的术语，例如*版本控制*。大多数被其他项目所依赖的项目都会在每次发布新版本时创建一个*版本号*。通常看上去像 8.1.3 或 64.1.20192004。版本号一般是数字构成的，但也并不绝对。版本号有很多用途，其中最重要的作用是保证软件能够运行。试想一下，假如我的库要发布一个新版本，在这个版本里面我重命名了某个函数。如果有人在我的库升级版本后，仍希望基于它构建新的软件，那么很可能构建会失败，因为它希望调用的函数已经不复存在了。有了版本控制就可以很好的解决这个问题，我们可以指定当前项目需要基于某个版本，甚至某个范围内的版本，或是某些项目来构建。这么做的话，即使某个被依赖的库发生了变化，依赖它的软件可以基于其之前的版本进行构建。

That also isn’t ideal though! What if I issue a security update which does *not* change the public interface of my library (its “API”), and which any project that depended on the old version should immediately start using? This is where the different groups of numbers in a version come in. The exact meaning of each one varies between projects, but one relatively common standard is [*semantic versioning*](https://semver.org/). With semantic versioning, every version number is of the form: major.minor.patch. The rules are:

> 这样还并不理想！如果我们发布了一项和安全相关的升级，它并*没有*影响到任何公开接口（API），但是处于安全的考虑，依赖它的项目都应该立即升级，那应该怎么做呢？这也是版本号包含多个部分的原因。不同项目所用的版本号其具体含义并不完全相同，但是一个相对比较常用的标准是[语义版本号](https://semver.org/)，这种版本号具有不同的语义，它的格式是这样的：主版本号.次版本号.补丁号。相关规则有：

- If a new release does not change the API, increase the patch version.
- If you *add* to your API in a backwards-compatible way, increase the minor version.
- If you change the API in a non-backwards-compatible way, increase the major version.

> - 如果新的版本没有改变 API，请将补丁号递增；
> - 如果您添加了 API 并且该改动是向后兼容的，请将次版本号递增；
> - 如果您修改了 API 但是它并不向后兼容，请将主版本号递增。

This already provides some major advantages. Now, if my project depends on your project, it *should* be safe to use the latest release with the same major version as the one I built against when I developed it, as long as its minor version is at least what it was back then. In other words, if I depend on your library at version `1.3.7`, then it *should* be fine to build it with `1.3.8`, `1.6.1`, or even `1.3.0`. Version `2.2.4` would probably not be okay, because the major version was increased. We can see an example of semantic versioning in Python’s version numbers. Many of you are probably aware that Python 2 and Python 3 code do not mix very well, which is why that was a *major* version bump. Similarly, code written for Python 3.5 might run fine on Python 3.7, but possibly not on 3.4.

> 这么做有很多好处。现在如果我们的项目是基于您的项目构建的，那么只要最新版本的主版本号只要没变就是安全的 ，次版本号不低于之前我们使用的版本即可。换句话说，如果我依赖的版本是`1.3.7`，那么使用`1.3.8`、`1.6.1`，甚至是`1.3.0`都是可以的。如果版本号是 `2.2.4` 就不一定能用了，因为它的主版本号增加了。我们可以将 Python 的版本号作为语义版本号的一个实例。您应该知道，Python 2 和 Python 3 的代码是不兼容的，这也是为什么 Python 的主版本号改变的原因。类似的，使用 Python 3.5 编写的代码在 3.7 上可以运行，但是在 3.4 上可能会不行。

When working with dependency management systems, you may also come across the notion of *lock files*. A lock file is simply a file that lists the exact version you are *currently* depending on of each dependency. Usually, you need to explicitly run an update program to upgrade to newer versions of your dependencies. There are many reasons for this, such as avoiding unnecessary recompiles, having reproducible builds, or not automatically updating to the latest version (which may be broken). An extreme version of this kind of dependency locking is *vendoring*, which is where you copy all the code of your dependencies into your own project. That gives you total control over any changes to it, and lets you introduce your own changes to it, but also means you have to explicitly pull in any updates from the upstream maintainers over time.

> 使用依赖管理系统的时候，您可能会遇到锁文件（*lock files*）这一概念。锁文件列出了您当前每个依赖所对应的具体版本号。通常，您需要执行升级程序才能更新依赖的版本。这么做的原因有很多，例如避免不必要的重新编译、创建可复现的软件版本或禁止自动升级到最新版本（可能会包含 bug）。还有一种极端的依赖锁定叫做 *vendoring*，它会把您的依赖中的所有代码直接拷贝到您的项目中，这样您就能够完全掌控代码的任何修改，同时您也可以将自己的修改添加进去，不过这也意味着如果该依赖的维护者更新了某些代码，您也必须要自己去拉取这些更新。

# Continuous integration systems

As you work on larger and larger projects, you’ll find that there are often additional tasks you have to do whenever you make a change to it. You might have to upload a new version of the documentation, upload a compiled version somewhere, release the code to pypi, run your test suite, and all sort of other things. Maybe every time someone sends you a pull request on GitHub, you want their code to be style checked and you want some benchmarks to run? When these kinds of needs arise, it’s time to take a look at continuous integration.

> 随着您接触到的项目规模越来越大，您会发现修改代码之后还有很多额外的工作要做。您可能需要上传一份新版本的文档、上传编译后的文件到某处、发布代码到 pypi，执行测试套件等等。或许您希望每次有人提交代码到 GitHub 的时候，他们的代码风格被检查过并执行过某些基准测试？如果您有这方面的需求，那么请花些时间了解一下持续集成。

Continuous integration, or CI, is an umbrella term for “stuff that runs whenever your code changes”, and there are many companies out there that provide various types of CI, often for free for open-source projects. Some of the big ones are Travis CI, Azure Pipelines, and GitHub Actions. They all work in roughly the same way: you add a file to your repository that describes what should happen when various things happen to that repository. By far the most common one is a rule like “when someone pushes code, run the test suite”. When the event triggers, the CI provider spins up a virtual machines (or more), runs the commands in your “recipe”, and then usually notes down the results somewhere. You might set it up so that you are notified if the test suite stops passing, or so that a little badge appears on your repository as long as the tests pass.

> 持续集成，或者叫做 CI 是一种雨伞术语（umbrella term，涵盖了一组术语的术语），它指的是那些“当您的代码变动时，自动运行的东西”，市场上有很多提供各式各样 CI 工具的公司，这些工具大部分都是免费或开源的。比较大的有 Travis CI、Azure Pipelines 和 GitHub Actions。它们的工作原理都是类似的：您需要在代码仓库中添加一个文件，描述当前仓库发生任何修改时，应该如何应对。目前为止，最常见的规则是：如果有人提交代码，执行测试套件。当这个事件被触发时，CI 提供方会启动一个（或多个）虚拟机，执行您制定的规则，并且通常会记录下相关的执行结果。您可以进行某些设置，这样当测试套件失败时您能够收到通知或者当测试全部通过时，您的仓库主页会显示一个徽标。

As an example of a CI system, the class website is set up using GitHub Pages. Pages is a CI action that runs the Jekyll blog software on every push to `master` and makes the built site available on a particular GitHub domain. This makes it trivial for us to update the website! We just make our changes locally, commit them with git, and then push. CI takes care of the rest.

> 本课程的网站基于 GitHub Pages 构建，这就是一个很好的例子。Pages 在每次`master`有代码更新时，会执行 Jekyll 博客软件，然后使您的站点可以通过某个 GitHub 域名来访问。对于我们来说这些事情太琐碎了，我现在我们只需要在本地进行修改，然后使用 git 提交代码，发布到远端。CI 会自动帮我们处理后续的事情。

## A brief aside on testing

Most large software projects come with a “test suite”. You may already be familiar with the general concept of testing, but we thought we’d quickly mention some approaches to testing and testing terminology that you may encounter in the wild:

> 多数的大型软件都有“测试套件”。您可能已经对测试的相关概念有所了解，但是我们觉得有些测试方法和测试术语还是应该再次提醒一下：

- Test suite: a collective term for all the tests
- Unit test: a “micro-test” that tests a specific feature in isolation
- Integration test: a “macro-test” that runs a larger part of the system to check that different feature or components work *together*.
- Regression test: a test that implements a particular pattern that *previously* caused a bug to ensure that the bug does not resurface.
- Mocking: to replace a function, module, or type with a fake implementation to avoid testing unrelated functionality. For example, you might “mock the network” or “mock the disk”.

> - 测试套件：所有测试的统称。
> - 单元测试：一种“微型测试”，用于对某个封装的特性进行测试。
> - 集成测试：一种“宏观测试”，针对系统的某一大部分进行，测试其不同的特性或组件是否能*协同*工作。
> - 回归测试：一种实现特定模式的测试，用于保证之前引起问题的 bug 不会再次出现。
> - 模拟（Mocking）: 使用一个假的实现来替换函数、模块或类型，屏蔽那些和测试不相关的内容。例如，您可能会“模拟网络连接” 或 “模拟硬盘”。

# Exercises

1. Most makefiles provide a target called `clean`. This isn’t intended to produce a file called `clean`, but instead to clean up any files that can be re-built by make. Think of it as a way to “undo” all of the build steps. Implement a `clean` target for the `paper.pdf` `Makefile` above. You will have to make the target [phony](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html). You may find the [`git ls-files`](https://git-scm.com/docs/git-ls-files) subcommand useful. A number of other very common make targets are listed [here](https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html#Standard-Targets).

    <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.06.25.png" alt="Screenshot 2023-12-22 at 20.06.25" />

   ```makefile
   paper.pdf: paper.tex plot-data.png
           pdflatex paper.tex
   
   plot-%.png: %.dat plot.py
           ./plot.py -i $*.dat -o $@
   
   .PHONY: clean
   clean:
           rm -f paper.pdf
           git ls-files --others --exclude-standard | xargs rm -f
   ```

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.07.04.png" alt="Screenshot 2023-12-22 at 20.07.04" />

   

2. Take a look at the various ways to specify version requirements for dependencies in [Rust’s build system](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html). Most package repositories support similar syntax. For each one (caret, tilde, wildcard, comparison, and multiple), try to come up with a use-case in which that particular kind of requirement makes sense.

   Rust's build system, managed by Cargo, uses specific syntax to specify version requirements for dependencies. Understanding how to specify these dependencies correctly is crucial for ensuring that your project gets the right versions of its dependencies, thus maintaining compatibility and stability. Here's an overview of each type of version requirement and a use-case where it makes sense:

   1. **Caret Requirements (`^`)**:
      - **Syntax:** `^1.2.3`
      - **Behavior:** Allows versions that do not make any changes to the left-most non-zero digit. `^1.2.3` would include versions from `1.2.3` to, but not including, `2.0.0`.
      - **Use-Case:** Use caret requirements when you want to accept any compatible updates, including minor and patch updates that do not contain breaking changes. This is suitable for libraries where you trust the semantic versioning of dependencies.
   2. **Tilde Requirements (`~`)**:
      - **Syntax:** `~1.2.3`
      - **Behavior:** When specifying a patch version, this allows patch updates. For `~1.2.3`, this includes versions from `1.2.3` to, but not including, `1.3.0`.
      - **Use-Case:** Tilde requirements are useful when you want to accept updates that are expected to be minor and backward-compatible, like bug fixes, but want to avoid new features which might come with minor version updates.
   3. **Wildcard Requirements (`\*`)**:
      - **Syntax:** `1.*` or `1.2.*`
      - **Behavior:** Allows any version where the specified digits are the same. `1.*` matches any `1.x.y` version, and `1.2.*` matches any `1.2.x` version.
      - **Use-Case:** Wildcard requirements are helpful during the early stages of development, where you might not be concerned about the specific versions of dependencies as long as they are within a certain range.
   4. **Comparison Requirements (`>`, `<`, `>=`, `<=`)**:
      - **Syntax:** `>1.2.3`, `<1.2.3`, `>=1.2.3`, `<=1.2.3`
      - **Behavior:** Specifies versions that must be greater than, less than, greater than or equal to, or less than or equal to the specified version.
      - **Use-Case:** Comparison requirements are useful when you need to avoid specific versions that are known to be problematic or incompatible with your project. For example, if a dependency has a bug in version `1.3.1`, you might specify `>=1.3.2` to ensure that version is not used.
   5. **Multiple Requirements**:
      - **Syntax:** Combining multiple requirements, like `>=1.2, <1.5`.
      - **Behavior:** Allows specifying a range of versions.
      - **Use-Case:** Multiple requirements are helpful when you need a specific range of versions for a dependency. For instance, if your project is compatible with a dependency for a specific range of versions only, you could specify something like `>=1.2, <1.5` to ensure compatibility.

   Each of these methods provides a different level of flexibility and control over the versions of dependencies used in a Rust project, allowing developers to balance the needs for stability, compatibility, and access to new features.

   > 
   > Rust 的构建系统由 Cargo 管理，它使用特定的语法来指定依赖项的版本要求。正确理解如何指定这些依赖项对于确保项目获取正确版本的依赖项非常重要，从而维持兼容性和稳定性。以下是每种类型版本要求的概述及其合理用例：
   >
   > 1. **脱字符要求（`^`）**:
   >    - **语法:** `^1.2.3`
   >    - **行为:** 允许版本在最左边的非零数字不变的情况下进行更改。`^1.2.3` 会包括从 `1.2.3` 到（但不包括）`2.0.0` 的版本。
   >    - **用例:** 当您想接受任何兼容的更新时使用脱字符要求，包括不包含重大更改的次要和补丁更新。这适用于您信任依赖项的语义版本控制的库。
   > 2. **波浪号要求（`~`）**:
   >    - **语法:** `~1.2.3`
   >    - **行为:** 指定补丁版本时，允许补丁更新。对于 `~1.2.3`，这包括从 `1.2.3` 到（但不包括）`1.3.0` 的版本。
   >    - **用例:** 波浪号要求在您希望接受预期为次要且向后兼容的更新（如错误修复）但想避免可能伴随次要版本更新的新功能时有用。
   > 3. **通配符要求（`\*`）**:
   >    - **语法:** `1.*` 或 `1.2.*`
   >    - **行为:** 允许任何指定数字相同的版本。`1.*` 匹配任何 `1.x.y` 版本，而 `1.2.*` 匹配任何 `1.2.x` 版本。
   >    - **用例:** 在开发初期，当您可能不太关心依赖项的具体版本，只要它们在某个范围内时，通配符要求很有帮助。
   > 4. **比较要求（`>`, `<`, `>=`, `<=`）**:
   >    - **语法:** `>1.2.3`, `<1.2.3`, `>=1.2.3`, `<=1.2.3`
   >    - **行为:** 指定必须大于、小于、大于等于或小于等于指定版本的版本。
   >    - **用例:** 当您需要避免已知存在问题或与您的项目不兼容的特定版本时，比较要求非常有用。例如，如果依赖项在版本 `1.3.1` 中有一个错误，您可能会指定 `>=1.3.2` 以确保不使用该版本。
   > 5. **多重要求**:
   >    - **语法:** 结合多个要求，如 `>=1.2, <1.5`。
   >    - **行为:** 允许指定一系列版本。
   >    - **用例:** 当您需要为依赖项指定特定范围的版本时，多重要求很有帮助。例如，如果您的项目仅与依赖项的特定版本范围兼容，您可以指定类似 `>=1.2, <1.5` 的内容以确保兼容性。
   >
   > 这些方法中的每一种都为在 Rust 项目中使用的依赖项版本提供了不同程度的灵活性和控制，允许开发人员在稳定性、兼容性和获取新功能方面实现平衡。

3. Git can act as a simple CI system all by itself. In `.git/hooks` inside any git repository, you will find (currently inactive) files that are run as scripts when a particular action happens. Write a [`pre-commit`](https://git-scm.com/docs/githooks#_pre_commit) hook that runs `make paper.pdf` and refuses the commit if the `make` command fails. This should prevent any commit from having an unbuildable version of the paper.

    <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.24.40.png" alt="Screenshot 2023-12-22 at 20.24.40" />

4. Set up a simple auto-published page using [GitHub Pages](https://pages.github.com/). Add a [GitHub Action](https://github.com/features/actions) to the repository to run `shellcheck` on any shell files in that repository (here is [one way to do it](https://github.com/marketplace/actions/shellcheck)). Check that it works!

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.29.35.png" alt="Screenshot 2023-12-22 at 20.29.35" />

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.29.06.png" alt="Screenshot 2023-12-22 at 20.29.06" />

   

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.14.13.png" alt="Screenshot 2023-12-22 at 21.14.13" />

    <img src="./Metaprogramming/Screenshot 2023-12-22 at 20.33.09.png" alt="Screenshot 2023-12-22 at 20.33.09" />

   

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.03.23.png" alt="Screenshot 2023-12-22 at 21.03.23" />

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.02.47.png" alt="Screenshot 2023-12-22 at 21.02.47" />

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.05.39.png" alt="Screenshot 2023-12-22 at 21.05.39" />

   

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.06.04.png" alt="Screenshot 2023-12-22 at 21.06.04" />

   

5. [Build your own](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/building-actions) GitHub action to run [`proselint`](https://github.com/amperser/proselint) or [`write-good`](https://github.com/btford/write-good) on all the `.md` files in the repository. Enable it in your repository, and check that it works by filing a pull request with a typo in it.

   ```java
   name: Markdown Linting
   
   on:
     pull_request:
       paths:
         - '**.md'
   
   jobs:
     lint:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - name: Install proselint
           run: pip install proselint
         - name: Run proselint
           run: find . -name '*.md' | xargs proselint
   ```

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.40.55.png" alt="Screenshot 2023-12-22 at 21.40.55" />

   <img src="./Metaprogramming/Screenshot 2023-12-22 at 21.39.31.png" alt="Screenshot 2023-12-22 at 21.39.31" />

   Pull requests it will check.<img src="./Metaprogramming/Screenshot 2023-12-22 at 21.39.48.png" alt="Screenshot 2023-12-22 at 21.39.48" />

