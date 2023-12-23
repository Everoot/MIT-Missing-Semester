# Version Control (Git)

Version control systems (VCSs) are tools used to track changes to source code (or other collections of files and folders). As the name implies, these tools help maintain a history of changes; furthermore, they facilitate collaboration. VCSs track changes to a folder and its contents in a series of snapshots, where each snapshot encapsulates the entire state of files/folders within a top-level directory. VCSs also maintain metadata like who created each snapshot, messages associated with each snapshot, and so on.

Why is version control useful? Even when you're working by yourself, it can let you look at old snapshots of a project, keep a log of why certain changes were made, work on parallel branches of development, and much more. When working with others, it's an invaluable tool for seeing what other people have changed, as well as resolving conflicts in concurrent development.

Modern VCSs also let you easily (and often automatically) answer questions like:

* Who wrote this module?
* When was this particular line of this particular file edited? By whom? Why was it edited?
* Over the last 1000 revisions, when/why did a particular unit test stop working?

While other VCSs exist, Git is the de facto standard for version control. This XKCD comic captures Git's reputation:

<img src="./Version Control (Git).assets/git.png" alt="xkcd 1597" />

Because Git's interface is a leaky abstraction, learning Git top-down (starting with its interface / command-line interface) can lead to a lot of confusion. It's possible to memorize a handful of commands and think of them as magic incantations, and follow the approach in the comic above whenever anything goes wrong.

While Git admittedly has an ugly interface, its underlying design and ideas are beautiful. While an ugly interface has to be memorized, a beautiful design can be understood. For this reason, we give a bottom-up explanation of Git, starting with its data model and later covering the command-line interface. Once the data model is understood, the commands can be better understood in terms of how they manipulate the underlying data model.

## Git's data model

There are many ad-hoc approaches you could take to version control. Git has a well-thought-out model that enables all the nice features of version control, like maintaining history, supporting branches, and enabling collaboration.

### Snapshots

Git models the history of a collection of files and folders within some top-level directory as a series of snapshots. In Git terminology, a file is called a "blob", and it's just a bunch of bytes. A directory is called a "tree", and it maps names to blobs or trees (so directories can contain other directions). A snapshot is the top-level tree that is being tracked. For example, we might have a tree as follows:

```
<root> (tree)
|
+- foo (tree)
|	 |
|  + bar.txt (blob, contents = "hello world")
|
+- baz.txt (blob, contents = "git is wonderful")
```

The top-level tree contains two elements, a tree "foo" (that itself contains one element, a blob "bar.txt"), and a blob "baz.txt"

### Modeling history: relating snapshots

How should a version control system relate snapshots? One simple model would be to have a linear history. A history would be a list of snapshots in time-order. For many reasons, Git doesn’t use a simple model like this.

In Git, a history is a directed acyclic graph (DAG) of snapshots. That may sound like a fancy math word, but don’t be intimidated. All this means is that each snapshot in Git refers to a set of “parents”, the snapshots that preceded it. It’s a set of parents rather than a single parent (as would be the case in a linear history) because a snapshot might descend from multiple parents, for example, due to combining (merging) two parallel branches of development.

Git calls these snapshots “commit”s. Visualizing a commit history might look something like this:

```
o <-- o <-- o <-- o
            ^
              \
               --- o <-- o
```

In the ASCII art above, the `o`s correspond to individual commits (snapshots). The arrows point to the parent of each commit (it’s a “comes before” relation, not “comes after”). After the third commit, the history branches into two separate branches. This might correspond to, for example, two separate features being developed in parallel, independently from each other. In the future, these branches may be merged to create a new snapshot that incorporates both of the features, producing a new history that looks like this, with the newly created merge commit shown in bold:

```
o <-- o <-- o <-- o <---- o
            ^            /
             \          v
              --- o <-- o
```

Commits in Git are immutable. This doesn’t mean that mistakes can’t be corrected, however; it’s just that “edits” to the commit history are actually creating entirely new commits, and references (see below) are updated to point to the new ones.

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 01.46.44.png" alt="Screenshot 2023-10-06 at 01.46.44" />



### Data model, as pseudocode

It may be instructive to see Git’s data model written down in pseudocode:

```pseudocode
// a file is a bunch of bytes
type blob = array<byte>
  
// a directory contains named files and directories
type tree = map<string, tree | blob>
  
// a commit has parents, metadata, and the top-level tree
type commit = struc {
  parents: array<commit>
  author: string
  message: string
  snapshot: tree
}
```

It’s a clean, simple model of history.



### Objects and content-addressing

An “object” is a blob, tree, or commit:

```pseudocode
type object = blob | tree | commit
```

In Git data store, all objects are content-addressed by their [SHA-1 hash](https://en.wikipedia.org/wiki/SHA-1).

```pseudocode
objects = map<string, object>

def store(object):
	id = sha1(object)
	objects[id] = object
	
def load(id):
	return objects[id]
```



### References

Now, all snapshots can be identified by their SHA-1 hashes. That’s inconvenient, because humans aren’t good at remembering strings of 40 hexadecimal characters.

Git’s solution to this problem is human-readable names for SHA-1 hashes, called “references”. References are pointers to commits. Unlike objects, which are immutable, references are mutable (can be updated to point to a new commit). For example, the `master` reference usually points to the latest commit in the main branch of development.

```pseudocode
references = map<string, string>

def update_reference(name, id):
	references[name] = id
	
def read_reference(name):
	return references[name]
	
def load_reference(name_or_id):
	if name_or_id in references:
		return load(refernces[name_or_id])
	else:
		return load(name_or_id)
```

With this, Git can use human-readable names like “master” to refer to a particular snapshot in the history, instead of a long hexadecimal string.

One detail is that we often want a notion of “where we currently are” in the history, so that when we take a new snapshot, we know what it is relative to (how we set the `parents` field of the commit). In Git, that “where we currently are” is a special reference called “HEAD”.

### Repositories

Finally, we can define what (roughly) is a Git *repository*: it is the data `objects`and `references`.

On disk, all Git stores are objects and references: that’s all there is to Git’s data model. All `git` commands map to some manipulation of the commit DAG by adding objects and adding/updating references.

Whenever you’re typing in any command, think about what manipulation the command is making to the underlying graph data structure. Conversely, if you’re trying to make a particular kind of change to the commit DAG, e.g. “discard uncommitted changes and make the ‘master’ ref point to commit `5d83f9e`”, there’s probably a command to do it (e.g. in this case, `git checkout master; git reset --hard 5d83f9e`).

# Staging area

This is another concept that’s orthogonal to the data model, but it’s a part of the interface to create commits.

One way you might imagine implementing snapshotting as described above is to have a “create snapshot” command that creates a new snapshot based on the *current state* of the working directory. Some version control tools work like this, but not Git. We want clean snapshots, and it might not always be ideal to make a snapshot from the current state. For example, imagine a scenario where you’ve implemented two separate features, and you want to create two separate commits, where the first introduces the first feature, and the next introduces the second feature. Or imagine a scenario where you have debugging print statements added all over your code, along with a bugfix; you want to commit the bugfix while discarding all the print statements.

Git accommodates such scenarios by allowing you to specify which modifications should be included in the next snapshot through a mechanism called the “staging area”.

#### Lecture interactive demo

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.38.19.png" alt="Screenshot 2023-10-06 at 10.38.19" />

`.git`: This is the directory on disk  where Git stores all of its internal data, namely the objects and references, and you actually see here "objects" and "refs" as two directories in here, and all the repository data will be stored underneath those two directories.

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.38.35.png" alt="Screenshot 2023-10-06 at 10.38.35" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.43.40.png" alt="Screenshot 2023-10-06 at 10.42.12" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.42.49.png" alt="Screenshot 2023-10-06 at 10.42.49" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.44.38.png" alt="Screenshot 2023-10-06 at 10.44.38" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.44.22.png" alt="Screenshot 2023-10-06 at 10.44.22" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.47.17.png" alt="Screenshot 2023-10-06 at 10.47.17" />

When I `git log` it will show on separate screen, but I want show on the same:

https://stackoverflow.com/questions/7736781/how-to-make-git-log-not-prompt-to-continue

`git config --global pager.log false`



<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.53.03.png" alt="Screenshot 2023-10-06 at 10.53.03" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 10.57.36.png" alt="Screenshot 2023-10-06 at 10.57.36" />

`master` is one reference that's created by default when you initialize a git repository. And by convention, it generally refers to the main branch of development in your code. So "master" will represent like the most up-to-date version of your project.

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.10.22.png" alt="Screenshot 2023-10-06 at 11.10.22" />

`git checkout` actually changes the contents of your working directory, and so in that way, it can be a somewhat dangerous command if you misuse it. For example:

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.23.17.png" alt="Screenshot 2023-10-06 at 11.23.17" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.24.57.png" alt="Screenshot 2023-10-06 at 11.24.57" />

`-f`: force

And now it's throwing away my changes.

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.40.25.png" alt="Screenshot 2023-10-06 at 11.40.25" />



<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.44.36.png" alt="Screenshot 2023-10-06 at 11.44.36" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.47.08.png" alt="Screenshot 2023-10-06 at 11.47.08" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.50.39.png" alt="Screenshot 2023-10-06 at 11.50.39" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.52.13.png" alt="Screenshot 2023-10-06 at 11.52.13" />



<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 11.57.28.png" alt="Screenshot 2023-10-06 at 11.57.28" />

`git branch dog; git checkout dog `  = ` git checkout -b dog `



<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.19.05.png" alt="Screenshot 2023-10-06 at 12.19.05" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.23.15.png" alt="Screenshot 2023-10-06 at 12.23.15" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.27.17.png" alt="Screenshot 2023-10-06 at 12.27.17" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.28.45.png" alt="Screenshot 2023-10-06 at 12.28.45" />





<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.30.01.png" alt="Screenshot 2023-10-06 at 12.30.01" />



<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.32.03.png" alt="Screenshot 2023-10-06 at 12.32.03" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.33.06.png" alt="Screenshot 2023-10-06 at 12.33.06" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.33.53.png" alt="Screenshot 2023-10-06 at 12.33.53" />

remote:

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.40.04.png" alt="Screenshot 2023-10-06 at 12.40.04" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.40.35.png" alt="Screenshot 2023-10-06 at 12.40.35" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.41.00.png" alt="Screenshot 2023-10-06 at 12.41.00" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.44.03.png" alt="Screenshot 2023-10-06 at 12.44.03" />

git push origin master:masterd

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.50.09.png" alt="Screenshot 2023-10-06 at 12.50.09" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.51.31.png" alt="Screenshot 2023-10-06 at 12.51.31" />

Something you can know:

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.53.33.png" alt="Screenshot 2023-10-06 at 12.53.33" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 12.58.59.png" alt="Screenshot 2023-10-06 at 12.58.59" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.03.42.png" alt="Screenshot 2023-10-06 at 13.03.42" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.03.56.png" alt="Screenshot 2023-10-06 at 13.03.56" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.07.07.png" alt="Screenshot 2023-10-06 at 13.07.07" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.12.42.png" alt="Screenshot 2023-10-06 at 13.12.42" />

<img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.16.19.png" alt="Screenshot 2023-10-06 at 13.16.19" />

## Git command-line interface

To avoid duplicating information, we're not going to explain the commands below in detail. See the highly recommended [Pro Git](https://git-scm.com/book/en/v2) for more information, or watch the lecture video.

### Basics

- `git help <command>` : get help for a git command
- `git init`: creates a new git repo, with data stored in the `.git` directory
- `git status`: tells you what's going on
- `git add <filename>`: adds files to staging area
- `git commit`: creates a new commit
  * Write [good commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)!
  * Even more reasons to write [good commit messages](https://chris.beams.io/posts/git-commit/)!
- `git log`: shows a flattened log of history
- `git log --all --graph --decorate`: visualizes history as a DAG
- `git diff <filename>`: show changes you made relative to the staging area
- `git diff <revision> <filename>`: shows differences in a file between snapshots
- `git checkout <revision>` : updates HEAD and current branch

### Branching and merging

* `git branch`: shows branches
* `git branch <name>`: creates a branch
* `git checkout -b <name>`: creates a branch and switches to it
  * same as `git branch <name>; git checkout <name>`
* `git merge <revision>` : merges into current branch
* `git mergetool`: use a fancy tool to help resolve merge conflicts
* `git rebase`: rebase set of patches onto a new base

### Remotes

* `git remote`: list remotes
* `git remote add <name> <url>`: add a remote
* `git push <remote> <local branch>:<remote branch>`: send objects to remote, and update remote reference
* `git branch --set-upstream-to=<remote>/<remote branch>` : set up correspondence between local and remote branch
* `git fetch`: retrieve objects/references from a remote
* `git pull`: same as `git fetch; git merge`
* `git clone`: download repository from remote

### Undo

* `git commit --amend`: edit a commit's contents/message
* `git reset HEAD <file>`: unstage a file
* `git checkout -- <file>`: discard changes

## Advanced Git

* `git config`: Git is [highly customizable](https://git-scm.com/docs/git-config)
* `git clone --depth-1`: shallow clone, without entire version history
* `git add -p`: interactive staging
* `git rebase -i` : interactive rebasing
* `git blame`: show who last edited which line
* `git stash`: temporarily remove modifications to working directory
* `git bisect`: binary search history (e.g. for regressions)
* `.gitignore`:  [specify](https://git-scm.com/docs/gitignore) intentionally untracked files to ignore



## Miscellaneous

- **GUIs**: there are many [GUI clients](https://git-scm.com/downloads/guis) out there for Git. We personally don’t use them and use the command-line interface instead.
- **Shell integration**: it’s super handy to have a Git status as part of your shell prompt ([zsh](https://github.com/olivierverdier/zsh-git-prompt), [bash](https://github.com/magicmonty/bash-git-prompt)). Often included in frameworks like [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh).
- **Editor integration**: similarly to the above, handy integrations with many features. [fugitive.vim](https://github.com/tpope/vim-fugitive) is the standard one for Vim.
- **Workflows**: we taught you the data model, plus some basic commands; we didn’t tell you what practices to follow when working on big projects (and there are [many](https://nvie.com/posts/a-successful-git-branching-model/) [different](https://www.endoflineblog.com/gitflow-considered-harmful) [approaches](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).
- **GitHub**: Git is not GitHub. GitHub has a specific way of contributing code to other projects, called [pull requests](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests).
- **Other Git providers**: GitHub is not special: there are many Git repository hosts, like [GitLab](https://about.gitlab.com/) and [BitBucket](https://bitbucket.org/).



##  Resources

- [Pro Git](https://git-scm.com/book/en/v2) is **highly recommended reading**. Going through Chapters 1–5 should teach you most of what you need to use Git proficiently, now that you understand the data model. The later chapters have some interesting, advanced material.
- [Oh Shit, Git!?!](https://ohshitgit.com/) is a short guide on how to recover from some common Git mistakes.
- [Git for Computer Scientists](https://eagain.net/articles/git-for-computer-scientists/) is a short explanation of Git’s data model, with less pseudocode and more fancy diagrams than these lecture notes.
- [Git from the Bottom Up](https://jwiegley.github.io/git-from-the-bottom-up/) is a detailed explanation of Git’s implementation details beyond just the data model, for the curious.
- [How to explain git in simple words](https://smusamashah.github.io/blog/2017/10/14/explain-git-in-simple-words)
- [Learn Git Branching](https://learngitbranching.js.org/) is a browser-based game that teaches you Git.



# Exercises

1. If you don’t have any past experience with Git, either try reading the first couple chapters of [Pro Git](https://git-scm.com/book/en/v2) or go through a tutorial like [Learn Git Branching](https://learngitbranching.js.org/). As you’re working through it, relate Git commands to the data model.

2. Clone the [repository for the class website](https://github.com/missing-semester/missing-semester).

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.08.31.png" alt="Screenshot 2023-10-06 at 00.08.31" />

   1. Explore the version history by visualizing it as a graph.

      `cd class_website`

      `git log --all --graph --decorate`

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.10.43.png" alt="Screenshot 2023-10-06 at 00.10.43" />

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.10.02.png" alt="Screenshot 2023-10-06 at 00.10.02" />

   2. Who was the last person to modify `README.md`? (Hint: use `git log` with an argument).

      `git log --all --graph --decorate README.md`

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.13.15.png" alt="Screenshot 2023-10-06 at 00.13.15" />

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.12.27.png" alt="Screenshot 2023-10-06 at 00.12.27" />

      Note that the top of the tree graph denotes the last person: Anish Athalye. 

   3. What was the commit message associated with the last modification to the `collections:` line of `_config.yml`? (Hint: use `git blame` and `git show`).

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.19.56.png" alt="Screenshot 2023-10-06 at 00.19.56" style="zoom: 50%;" />

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.16.58.png" alt="Screenshot 2023-10-06 at 00.16.58" />

      It prints that the corresponding hash for the commit is `a88b4eac`.

      So `git show a88b4eac`

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.22.04.png" alt="Screenshot 2023-10-06 at 00.22.04" />

      <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 00.21.07.png" alt="Screenshot 2023-10-06 at 00.21.07" />

      It shows the commit message is "Redo lectures as a collection".

3. One common mistake when learning Git is to commit large files that should not be managed by Git or adding sensitive information. Try adding a file to a repository, making some commits and then deleting that file from history (you may want to look at [this](https://help.github.com/articles/removing-sensitive-data-from-a-repository/)).

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.23.03.png" alt="Screenshot 2023-10-06 at 13.23.03" />

   当你使用 Git 管理你的代码时，有时可能会不小心提交了不应该由 Git 管理的大文件，或者包含敏感信息的文件。如果这样的文件已经被提交，那么仅仅通过 `git rm` 命令删除该文件并提交这个更改是不够的。因为该文件仍然存在于 Git 的历史记录中。这意味着任何人仍然可以查看或检出早期的提交来访问该文件。

   `git filter-branch` 是一个强大的命令，允许你在整个 Git 历史中重写或过滤提交。这可以用来从 Git 历史中彻底删除文件.

   `git filter-branch`: 用于重写 Git 历史

   `--force`: 如果已经执行过 filter-branch 操作，这个选项会强制运行它，覆盖旧的临时目录

   `--index-filter`: 与 `--tree-filter` 相比，这是一个更快的方法，它不检出每次提交的树。你只修改索引（即暂存区域)

   `"git rm --cached --ignore-unmatch PATH-TO-YOUR-FILE-WITH-SENSITIVE-DATA"`: 这是在每次提交上运行的命令。它尝试从 Git 索引中删除指定的文件。`--ignore-unmatch` 确保命令在文件不存在时（例如，在某些提交中）不会失败。

   `--prune-empty`: 删除那些由于上述操作而变为空的提交。

   `--tag-name-filter cat`: 重新写所有标签名以使其指向新的提交（如果提交 ID 由于前面的操作而更改）

   `-- --all`: 这意味着你要对所有分支和标签应用此过滤器

   执行此命令后，指定的文件将从整个 Git 历史中删除。但请注意，如果你已经将该仓库推送到远程，那么删除历史记录并重新推送会是一个破坏性的操作。你需要确保与你合作的每个人都了解这一更改，并从你的新历史重新拉取或克隆。

4. Clone some repository from GitHub, and modify one of its existing files. What happens when you do `git stash`? What do you see when running `git log --all --oneline`? Run `git stash pop` to undo what you did with `git stash`. In what scenario might this be useful?

   `git-stash` - Stash the changes in a dirty working directory away.

   

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.33.03.png" alt="Screenshot 2023-10-06 at 13.33.03" />

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.35.16.png" alt="Screenshot 2023-10-06 at 13.35.16" />

   `git log --all --oneline` prints `(refs/stash) WIP on master:` followed by the hash id and the commit message of the latest commit i.e. the `HEAD` commit before the local change. After running `git stash pop`, the stash log will disappear.

   `git-stash` would be useful when checking out to other commits but do not want to overwrite the local changes not yet committed, either because they don’t seem good enough yet to commit or there are more urgent bugs to address at the moment, etc.

   -----

   **运行 `git stash`**

   `git stash` 将会执行以下操作：

   - 保存你的工作目录和暂存区中的更改。
   - 将这些更改存储在一个新的独立地方，称为 "stash"。
   - 重置你的工作目录，使其与上次的提交匹配。

   现在，你的工作目录是干净的，就像你从未做过任何更改一样。

   

   **运行 `git log --all --oneline`**

   `git log` 命令显示提交历史。`--all` 参数意味着它会显示所有分支的历史，而 `--oneline` 使每个提交仅显示为一行。

   你不会在此日志中看到与 "stash" 直接相关的内容，因为 "stash" 不是一个正式的提交或分支。但你可以使用 `git stash list` 来查看所有的 "stash" 项

   

   **运行 `git stash pop`**

   这个命令做两件事：

   - 它将最近的 "stash" 中的更改应用到你的工作目录。
   - 它从 "stash" 列表中删除这些更改。

   现在，你的工作目录恢复到了你运行 `git stash` 之前的状态。

   

   在什么情境下这可能有用？

   1. **中断当前工作**：假设你正在开发一个新功能，但突然需要修复一个紧急的错误。你可以使用 `git stash` 临时保存你的更改，然后切换到一个新分支来修复错误。
   2. **切换分支**：如果你在一个分支上有未提交的更改，但你想切换到另一个分支，`git stash` 可以帮助你在不提交当前更改的情况下切换分支。
   3. **测试更改**：如果你想临时删除你的更改以运行某些测试，然后再应用这些更改，`git stash` 也会很有用。

   总之，`git stash` 提供了一个灵活的方式来临时保存和恢复更改，使你可以在不同的任务或分支之间自由切换。

   

5. Like many command line tools, Git provides a configuration file (or dotfile) called `~/.gitconfig`. Create an alias in `~/.gitconfig` so that when you run `git graph`, you get the output of `git log --all --graph --decorate --oneline`. You can do this by directly [editing](https://git-scm.com/docs/git-config#Documentation/git-config.txt-alias) the `~/.gitconfig` file, or you can use the `git config` command to add the alias. Information about git aliases can be found [here](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases).

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.40.49.png" alt="Screenshot 2023-10-06 at 13.40.49" />

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.45.34.png" alt="Screenshot 2023-10-06 at 13.45.34" />

6. You can define global ignore patterns in `~/.gitignore_global` after running `git config --global core.excludesfile ~/.gitignore_global`. Do this, and set up your global gitignore file to ignore OS-specific or editor-specific temporary files, like `.DS_Store`.

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.50.46.png" alt="Screenshot 2023-10-06 at 13.50.46" />

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.52.48.png" alt="Screenshot 2023-10-06 at 13.52.48" />

   This tells Git to use `~/.gitignore_global` as the global `.gitignore` file.

   

7. Fork the [repository for the class website](https://github.com/missing-semester/missing-semester), find a typo or some other improvement you can make, and submit a pull request on GitHub (you may want to look at [this](https://github.com/firstcontributions/first-contributions)). Please only submit PRs that are useful (don’t spam us, please!). If you can’t find an improvement to make, you can skip this exercise.

   I use this link https://github.com/firstcontributions/first-contributions to finish this exercise.

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 13.58.55.png" alt="Screenshot 2023-10-06 at 13.58.55" />

   

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 14.02.22.png" alt="Screenshot 2023-10-06 at 14.02.22" />

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 14.15.22.png" alt="Screenshot 2023-10-06 at 14.03.19" />

   

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 14.12.17.png" alt="Screenshot 2023-10-06 at 14.12.17" />

   <img src="./Version Control (Git).assets/Screenshot 2023-10-06 at 14.12.56.png" alt="Screenshot 2023-10-06 at 14.12.56" />

   

#### Reference

https://missing.csail.mit.edu/2020/version-control/

https://youtu.be/2sjqTHE0zok

https://ivan-kim.github.io/MIT-missing-semester/Lecture6/

https://www.bilibili.com/video/BV1Wh4y1s7Lj/?spm_id_from=333.999.0.0&vd_source=73e7d2c4251a7c9000b22d21b70f5635

