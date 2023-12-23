# Security and Cryptography

https://youtu.be/tjwobAmnKTo

Last year’s [security and privacy lecture](https://missing.csail.mit.edu/2019/security/) focused on how you can be more secure as a computer *user*. This year, we will focus on security and cryptography concepts that are relevant in understanding tools covered earlier in this class, such as the use of hash functions in Git or key derivation functions and symmetric/asymmetric cryptosystems in SSH.

> 去年的[这节课](https://missing-semester-cn.github.io/2019/security/)我们从计算机 *用户* 的角度探讨了增强隐私保护和安全的方法。 今年我们将关注比如散列函数、密钥生成函数、对称/非对称密码体系这些安全和密码学的概念是如何应用于前几节课所学到的工具（Git和SSH）中的。

This lecture is not a substitute for a more rigorous and complete course on computer systems security ([6.858](https://css.csail.mit.edu/6.858/)) or cryptography ([6.857](https://courses.csail.mit.edu/6.857/) and 6.875). Don’t do security work without formal training in security. Unless you’re an expert, don’t [roll your own crypto](https://www.schneier.com/blog/archives/2015/05/amateurs_produc.html). The same principle applies to systems security.

> 本课程不能作为计算机系统安全 ([6.858](https://css.csail.mit.edu/6.858/)) 或者密码学 ([6.857](https://courses.csail.mit.edu/6.857/)以及6.875)的替代。 如果你不是密码学的专家，请不要[试图创造或者修改加密算法](https://www.schneier.com/blog/archives/2015/05/amateurs_produc.html)。从事和计算机系统安全相关的工作同理。

This lecture has a very informal (but we think practical) treatment of basic cryptography concepts. This lecture won’t be enough to teach you how to *design* secure systems or cryptographic protocols, but we hope it will be enough to give you a general understanding of the programs and protocols you already use.

> 这节课将对一些基本的概念进行简单（但实用）的说明。 虽然这些说明不足以让你学会如何 *设计* 安全系统或者加密协议，但我们希望你可以对现在使用的程序和协议有一个大概了解。

# Entropy

[Entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) is a measure of randomness. This is useful, for example, when determining the strength of a password.

> [熵](https://en.wikipedia.org/wiki/Entropy_(information_theory))(Entropy) 度量了不确定性并可以用来决定密码的强度。

<img src="./Security and Cryptography/password_strength.png" alt="XKCD 936: Password Strength" />

As the above [XKCD comic](https://xkcd.com/936/) illustrates, a password like “correcthorsebatterystaple” is more secure than one like “Tr0ub4dor&3”. But how do you quantify something like this?

> 正如上面的 [XKCD 漫画](https://xkcd.com/936/) 所描述的， “correcthorsebatterystaple” 这个密码比 “Tr0ub4dor&3” 更安全——可是熵是如何量化安全性的呢？

Entropy is measured in *bits*, and when selecting uniformly at random from a set of possible outcomes, the entropy is equal to `log_2(# of possibilities)`. A fair coin flip gives 1 bit of entropy. A dice roll (of a 6-sided die) has ~2.58 bits of entropy.

> 熵的单位是 *比特*。对于一个均匀分布的随机离散变量，熵等于`log_2(所有可能的个数，即n)`。 扔一次硬币的熵是1比特。掷一次（六面）骰子的熵大约为2.58比特。

You should consider that the attacker knows the *model* of the password, but not the randomness (e.g. from [dice rolls](https://en.wikipedia.org/wiki/Diceware)) used to select a particular password.

> 一般我们认为攻击者了解密码的模型（最小长度，最大长度，可能包含的字符种类等），但是不了解某个密码是如何随机选择的—— 比如[掷骰子](https://en.wikipedia.org/wiki/Diceware)。

How many bits of entropy is enough? It depends on your threat model. For online guessing, as the XKCD comic points out, ~40 bits of entropy is pretty good. To be resistant to offline guessing, a stronger password would be necessary (e.g. 80 bits, or more).

> 使用多少比特的熵取决于应用的威胁模型。 上面的XKCD漫画告诉我们，大约40比特的熵足以对抗在线穷举攻击（受限于网络速度和应用认证机制）。 而对于离线穷举攻击（主要受限于计算速度）, 一般需要更强的密码 (比如80比特或更多)。

# Hash functions

A [cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function) maps data of arbitrary size to a fixed size, and has some special properties. A rough specification of a hash function is as follows:

> [密码散列函数](https://en.wikipedia.org/wiki/Cryptographic_hash_function) (Cryptographic hash function) 可以将任意大小的数据映射为一个固定大小的输出。除此之外，还有一些其他特性。 一个散列函数的大概规范如下：

```
hash(value: array<byte>) -> vector<byte, N>  (for some fixed N)
```

An example of a hash function is [SHA1](https://en.wikipedia.org/wiki/SHA-1), which is used in Git. It maps arbitrary-sized inputs to 160-bit outputs (which can be represented as 40 hexadecimal characters). We can try out the SHA1 hash on an input using the `sha1sum` command:

> [SHA-1](https://en.wikipedia.org/wiki/SHA-1)是Git中使用的一种散列函数， 它可以将任意大小的输入映射为一个160比特（可被40位十六进制数表示）的输出。 下面我们用`sha1sum`命令来测试SHA1对几个字符串的输出：

```
$ printf 'hello' | sha1sum
aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
$ printf 'hello' | sha1sum
aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
$ printf 'Hello' | sha1sum 
f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0
```

At a high level, a hash function can be thought of as a hard-to-invert random-looking (but deterministic) function (and this is the [ideal model of a hash function](https://en.wikipedia.org/wiki/Random_oracle)). A hash function has the following properties:

> 抽象地讲，散列函数可以被认为是一个不可逆，且看上去随机（但具确定性）的函数 （这就是[散列函数的理想模型](https://en.wikipedia.org/wiki/Random_oracle)）。 一个散列函数拥有以下特性：

- Deterministic: the same input always generates the same output.
- Non-invertible: it is hard to find an input `m` such that `hash(m) = h` for some desired output `h`.
- Target collision resistant: given an input `m_1`, it’s hard to find a different input `m_2` such that `hash(m_1) = hash(m_2)`.
- Collision resistant: it’s hard to find two inputs `m_1` and `m_2` such that `hash(m_1) = hash(m_2)` (note that this is a strictly stronger property than target collision resistance).

> - 确定性：对于不变的输入永远有相同的输出。
> - 不可逆性：对于`hash(m) = h`，难以通过已知的输出`h`来计算出原始输入`m`。
> - 目标碰撞抵抗性/弱无碰撞：对于一个给定输入`m_1`，难以找到`m_2 != m_1`且`hash(m_1) = hash(m_2)`。
> - 碰撞抵抗性/强无碰撞：难以找到一组满足`hash(m_1) = hash(m_2)`的输入`m_1, m_2`（该性质严格强于目标碰撞抵抗性）。

Note: while it may work for certain purposes, SHA-1 is [no longer](https://shattered.io/) considered a strong cryptographic hash function. You might find this table of [lifetimes of cryptographic hash functions](https://valerieaurora.org/hash.html) interesting. However, note that recommending specific hash functions is beyond the scope of this lecture. If you are doing work where this matters, you need formal training in security/cryptography.

> 注：虽然SHA-1还可以用于特定用途，但它已经[不再被认为](https://shattered.io/)是一个强密码散列函数。 你可参照[密码散列函数的生命周期](https://valerieaurora.org/hash.html)这个表格了解一些散列函数是何时被发现弱点及破解的。 请注意，针对应用推荐特定的散列函数超出了本课程内容的范畴。 如果选择散列函数对于你的工作非常重要，请先系统学习信息安全及密码学。

## Applications

- Git, for content-addressed storage. The idea of a [hash function](https://en.wikipedia.org/wiki/Hash_function) is a more general concept (there are non-cryptographic hash functions). Why does Git use a cryptographic hash function?

  > Git中的内容寻址存储(Content-addressed storage)：[散列函数](https://en.wikipedia.org/wiki/Hash_function)是一个宽泛的概念（存在非密码学的散列函数），那么Git为什么要特意使用密码散列函数？

- A short summary of the contents of a file. Software can often be downloaded from (potentially less trustworthy) mirrors, e.g. Linux ISOs, and it would be nice to not have to trust them. The official sites usually post hashes alongside the download links (that point to third-party mirrors), so that the hash can be checked after downloading a file.

  > 文件的信息摘要(Message digest)：像Linux ISO这样的软件可以从非官方的（有时不太可信的）镜像站下载，所以需要设法确认下载的软件和官方一致。 官方网站一般会在（指向镜像站的）下载链接旁边备注安装文件的哈希值。 用户从镜像站下载安装文件后可以对照公布的哈希值来确定安装文件没有被篡改。

- [Commitment schemes](https://en.wikipedia.org/wiki/Commitment_scheme). Suppose you want to commit to a particular value, but reveal the value itself later. For example, I want to do a fair coin toss “in my head”, without a trusted shared coin that two parties can see. I could choose a value `r = random()`, and then share `h = sha256(r)`. Then, you could call heads or tails (we’ll agree that even `r` means heads, and odd `r` means tails). After you call, I can reveal my value `r`, and you can confirm that I haven’t cheated by checking `sha256(r)` matches the hash I shared earlier.

  > [承诺机制](https://en.wikipedia.org/wiki/Commitment_scheme)(Commitment scheme)： 假设我希望承诺一个值，但之后再透露它—— 比如在没有一个可信的、双方可见的硬币的情况下在我的脑海中公平的“扔一次硬币”。 我可以选择一个值`r = random()`，并和你分享它的哈希值`h = sha256(r)`。 这时你可以开始猜硬币的正反：我们一致同意偶数`r`代表正面，奇数`r`代表反面。 你猜完了以后，我告诉你值`r`的内容，得出胜负。同时你可以使用`sha256(r)`来检查我分享的哈希值`h`以确认我没有作弊。

# Key derivation functions

A related concept to cryptographic hashes, [key derivation functions](https://en.wikipedia.org/wiki/Key_derivation_function) (KDFs) are used for a number of applications, including producing fixed-length output for use as keys in other cryptographic algorithms. Usually, KDFs are deliberately slow, in order to slow down offline brute-force attacks.

> [密钥生成函数](https://en.wikipedia.org/wiki/Key_derivation_function) (Key Derivation Functions) 作为密码散列函数的相关概念，被应用于包括生成固定长度，可以使用在其他密码算法中的密钥等方面。 为了对抗穷举法攻击，密钥生成函数通常较慢。

## Applications

- Producing keys from passphrases for use in other cryptographic algorithms (e.g. symmetric cryptography, see below).

  > 从密码生成可以在其他加密算法中使用的密钥，比如对称加密算法（见下）。

- Storing login credentials. Storing plaintext passwords is bad; the right approach is to generate and store a random [salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) `salt = random()` for each user, store `KDF(password + salt)`, and verify login attempts by re-computing the KDF given the entered password and the stored salt.

  > 存储登录凭证时不可直接存储明文密码。正确的方法是针对每个用户随机生成一个[盐](https://en.wikipedia.org/wiki/Salt_(cryptography)) `salt = random()`， 并存储盐，以及密钥生成函数对连接了盐的明文密码生成的哈希值`KDF(password + salt)`。在验证登录请求时，使用输入的密码连接存储的盐重新计算哈希值`KDF(input + salt)`，并与存储的哈希值对比。

# Symmetric cryptography

Hiding message contents is probably the first concept you think about when you think about cryptography. Symmetric cryptography accomplishes this with the following set of functionality:

> 说到加密，可能你会首先想到隐藏明文信息。对称加密使用以下几个方法来实现这个功能：

```shell
keygen() -> key  (this function is randomized)

encrypt(plaintext: array<byte>, key) -> array<byte>  (the ciphertext)
decrypt(ciphertext: array<byte>, key) -> array<byte>  (the plaintext)
```

The encrypt function has the property that given the output (ciphertext), it’s hard to determine the input (plaintext) without the key. The decrypt function has the obvious correctness property, that `decrypt(encrypt(m, k), k) = m`.

> 加密方法`encrypt()`输出的密文`ciphertext`很难在不知道`key`的情况下得出明文`plaintext`。 解密方法`decrypt()`有明显的正确性。因为功能要求给定密文及其密钥，解密方法必须输出明文：`decrypt(encrypt(m, k), k) = m`。

An example of a symmetric cryptosystem in wide use today is [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard).

> [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) 是现在常用的一种对称加密系统。

## Applications

- Encrypting files for storage in an untrusted cloud service. This can be combined with KDFs, so you can encrypt a file with a passphrase. Generate `key = KDF(passphrase)`, and then store `encrypt(file, key)`.

  > 加密不信任的云服务上存储的文件。对称加密和密钥生成函数配合起来，就可以使用密码加密文件： 将密码输入密钥生成函数生成密钥 `key = KDF(passphrase)`，然后存储`encrypt(file, key)`。

# Asymmetric cryptography

The term “asymmetric” refers to there being two keys, with two different roles. A private key, as its name implies, is meant to be kept private, while the public key can be publicly shared and it won’t affect security (unlike sharing the key in a symmetric cryptosystem). Asymmetric cryptosystems provide the following set of functionality, to encrypt/decrypt and to sign/verify:

> 非对称加密的“非对称”代表在其环境中，使用两个具有不同功能的密钥： 一个是私钥(private key)，不向外公布；另一个是公钥(public key)，公布公钥不像公布对称加密的共享密钥那样可能影响加密体系的安全性。
> 非对称加密使用以下几个方法来实现加密/解密(encrypt/decrypt)，以及签名/验证(sign/verify)：

```shell
keygen() -> (public key, private key)  (this function is randomized)

encrypt(plaintext: array<byte>, public key) -> array<byte>  (the ciphertext)
decrypt(ciphertext: array<byte>, private key) -> array<byte>  (the plaintext)

sign(message: array<byte>, private key) -> array<byte>  (the signature)
verify(message: array<byte>, signature: array<byte>, public key) -> bool  (whether or not the signature is valid)
```

The encrypt/decrypt functions have properties similar to their analogs from symmetric cryptosystems. A message can be encrypted using the *public* key. Given the output (ciphertext), it’s hard to determine the input (plaintext) without the *private* key. The decrypt function has the obvious correctness property, that `decrypt(encrypt(m, public key), private key) = m`.

> 非对称的加密/解密方法和对称的加密/解密方法有类似的特征。信息在非对称加密中使用 *公钥* 加密， 且输出的密文很难在不知道 *私钥* 的情况下得出明文。解密方法`decrypt()`有明显的正确性。 给定密文及私钥，解密方法一定会输出明文： `decrypt(encrypt(m, public key), private key) = m`。

Symmetric and asymmetric encryption can be compared to physical locks. A symmetric cryptosystem is like a door lock: anyone with the key can lock and unlock it. Asymmetric encryption is like a padlock with a key. You could give the unlocked lock to someone (the public key), they could put a message in a box and then put the lock on, and after that, only you could open the lock because you kept the key (the private key).

> 对称加密和非对称加密可以类比为机械锁。 对称加密就好比一个防盗门：只要是有钥匙的人都可以开门或者锁门。 非对称加密好比一个可以拿下来的挂锁。你可以把打开状态的挂锁（公钥）给任何一个人并保留唯一的钥匙（私钥）。这样他们将给你的信息装进盒子里并用这个挂锁锁上以后，只有你可以用保留的钥匙开锁。

The sign/verify functions have the same properties that you would hope physical signatures would have, in that it’s hard to forge a signature. No matter the message, without the *private* key, it’s hard to produce a signature such that `verify(message, signature, public key)` returns true. And of course, the verify function has the obvious correctness property that `verify(message, sign(message, private key), public key) = true`.

> 签名/验证方法具有和书面签名类似的特征。在不知道 *私钥* 的情况下，不管需要签名的信息为何，很难计算出一个可以使 `verify(message, signature, public key)` 返回为真的签名。对于使用私钥签名的信息，验证方法验证和私钥相对应的公钥时一定返回为真： `verify(message, sign(message, private key), public key) = true`。

## Applications

- [PGP email encryption](https://en.wikipedia.org/wiki/Pretty_Good_Privacy). People can have their public keys posted online (e.g. in a PGP keyserver, or on [Keybase](https://keybase.io/)). Anyone can send them encrypted email.

  > [PGP电子邮件加密](https://en.wikipedia.org/wiki/Pretty_Good_Privacy)：用户可以将所使用的公钥在线发布，比如：PGP密钥服务器或 [Keybase](https://keybase.io/)。任何人都可以向他们发送加密的电子邮件。

- Private messaging. Apps like [Signal](https://signal.org/) and [Keybase](https://keybase.io/) use asymmetric keys to establish private communication channels.

  > 聊天加密：像 [Signal](https://signal.org/) 和 [Keybase](https://keybase.io/) 使用非对称密钥来建立私密聊天。

- Signing software. Git can have GPG-signed commits and tags. With a posted public key, anyone can verify the authenticity of downloaded software.

  > 软件签名：Git 支持用户对提交(commit)和标签(tag)进行GPG签名。任何人都可以使用软件开发者公布的签名公钥验证下载的已签名软件。

## Key distribution

Asymmetric-key cryptography is wonderful, but it has a big challenge of distributing public keys / mapping public keys to real-world identities. There are many solutions to this problem. Signal has one simple solution: trust on first use, and support out-of-band public key exchange (you verify your friends’ “safety numbers” in person). PGP has a different solution, which is [web of trust](https://en.wikipedia.org/wiki/Web_of_trust). Keybase has yet another solution of [social proof](https://keybase.io/blog/chat-apps-softer-than-tofu) (along with other neat ideas). Each model has its merits; we (the instructors) like Keybase’s model.

> 非对称加密面对的主要挑战是，如何分发公钥并对应现实世界中存在的人或组织。Signal的信任模型是，信任用户第一次使用时给出的身份(trust on first use)，同时支持用户线下(out-of-band)、面对面交换公钥（Signal里的safety number）。PGP使用的是[信任网络](https://en.wikipedia.org/wiki/Web_of_trust)。简单来说，如果我想加入一个信任网络，则必须让已经在信任网络中的成员对我进行线下验证，比如对比证件。验证无误后，信任网络的成员使用私钥对我的公钥进行签名。这样我就成为了信任网络的一部分。只要我使用签名过的公钥所对应的私钥就可以证明“我是我”。Keybase主要使用[社交网络证明 (social proof)](https://keybase.io/blog/chat-apps-softer-than-tofu)，和一些别的精巧设计。每个信任模型有它们各自的优点：我们（讲师）更倾向于 Keybase 使用的模型。

# Case studies

## Password managers

This is an essential tool that everyone should try to use (e.g. [KeePassXC](https://keepassxc.org/), [pass](https://www.passwordstore.org/), and [1Password](https://1password.com/)). Password managers make it convenient to use unique, randomly generated high-entropy passwords for all your logins, and they save all your passwords in one place, encrypted with a symmetric cipher with a key produced from a passphrase using a KDF.

Using a password manager lets you avoid password reuse (so you’re less impacted when websites get compromised), use high-entropy passwords (so you’re less likely to get compromised), and only need to remember a single high-entropy password.

> 每个人都应该尝试使用密码管理器，比如[KeePassXC](https://keepassxc.org/)、[pass](https://www.passwordstore.org/) 和 [1Password](https://1password.com/))。密码管理器会帮助你对每个网站生成随机且复杂（表现为高熵）的密码，并使用你指定的主密码配合密钥生成函数来对称加密它们。你只需要记住一个复杂的主密码，密码管理器就可以生成很多复杂度高且不会重复使用的密码。密码管理器通过这种方式降低密码被猜出的可能，并减少网站信息泄露后对其他网站密码的威胁。

## Two-factor authentication

[Two-factor authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication) (2FA) requires you to use a passphrase (“something you know”) along with a 2FA authenticator (like a [YubiKey](https://www.yubico.com/), “something you have”) in order to protect against stolen passwords and [phishing](https://en.wikipedia.org/wiki/Phishing) attacks.

> [两步验证](https://en.wikipedia.org/wiki/Multi-factor_authentication)(2FA)要求用户同时使用密码（“你知道的信息”）和一个身份验证器（“你拥有的物品”，比如[YubiKey](https://www.yubico.com/)）来消除密码泄露或者[钓鱼攻击](https://en.wikipedia.org/wiki/Phishing)的威胁。

## Full disk encryption

Keeping your laptop’s entire disk encrypted is an easy way to protect your data in the case that your laptop is stolen. You can use [cryptsetup + LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_a_non-root_file_system) on Linux, [BitLocker](https://fossbytes.com/enable-full-disk-encryption-windows-10/) on Windows, or [FileVault](https://support.apple.com/en-us/HT204837) on macOS. This encrypts the entire disk with a symmetric cipher, with a key protected by a passphrase.

> 对笔记本电脑的硬盘进行全盘加密是防止因设备丢失而信息泄露的简单且有效方法。 Linux的[cryptsetup + LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_a_non-root_file_system)， Windows的[BitLocker](https://fossbytes.com/enable-full-disk-encryption-windows-10/)，或者macOS的[FileVault](https://support.apple.com/en-us/HT204837)都使用一个由密码保护的对称密钥来加密盘上的所有信息。

## Private messaging

Use [Signal](https://signal.org/) or [Keybase](https://keybase.io/). End-to-end security is bootstrapped from asymmetric-key encryption. Obtaining your contacts’ public keys is the critical step here. If you want good security, you need to authenticate public keys out-of-band (with Signal or Keybase), or trust social proofs (with Keybase).

> [Signal](https://signal.org/)和[Keybase](https://keybase.io/)使用非对称加密对用户提供端到端(End-to-end)安全性。
>
> 获取联系人的公钥非常关键。为了保证安全性，应使用线下方式验证Signal或者Keybase的用户公钥，或者信任Keybase用户提供的社交网络证明。

## SSH

We’ve covered the use of SSH and SSH keys in an [earlier lecture](https://missing.csail.mit.edu/2020/command-line/#remote-machines). Let’s look at the cryptography aspects of this.

> 我们在[之前的一堂课](https://missing-semester-cn.github.io/2020/command-line/#remote-machines)讨论了SSH和SSH密钥的使用。那么我们今天从密码学的角度来分析一下它们。

When you run `ssh-keygen`, it generates an asymmetric keypair, `public_key, private_key`. This is generated randomly, using entropy provided by the operating system (collected from hardware events, etc.). The public key is stored as-is (it’s public, so keeping it a secret is not important), but at rest, the private key should be encrypted on disk. The `ssh-keygen` program prompts the user for a passphrase, and this is fed through a key derivation function to produce a key, which is then used to encrypt the private key with a symmetric cipher.

> 当你运行`ssh-keygen`命令，它会生成一个非对称密钥对：公钥和私钥`(public_key, private_key)`。 生成过程中使用的随机数由系统提供的熵决定。这些熵可以来源于硬件事件(hardware events)等。 公钥最终会被分发，它可以直接明文存储。 但是为了防止泄露，私钥必须加密存储。`ssh-keygen`命令会提示用户输入一个密码，并将它输入密钥生成函数 产生一个密钥。最终，`ssh-keygen`使用对称加密算法和这个密钥加密私钥。

In use, once the server knows the client’s public key (stored in the `.ssh/authorized_keys` file), a connecting client can prove its identity using asymmetric signatures. This is done through [challenge-response](https://en.wikipedia.org/wiki/Challenge–response_authentication). At a high level, the server picks a random number and sends it to the client. The client then signs this message and sends the signature back to the server, which checks the signature against the public key on record. This effectively proves that the client is in possession of the private key corresponding to the public key that’s in the server’s `.ssh/authorized_keys` file, so the server can allow the client to log in.

> 在实际运用中，当服务器已知用户的公钥（存储在`.ssh/authorized_keys`文件中，一般在用户HOME目录下），尝试连接的客户端可以使用非对称签名来证明用户的身份——这便是[挑战应答方式](https://en.wikipedia.org/wiki/Challenge–response_authentication)。 简单来说，服务器选择一个随机数字发送给客户端。客户端使用用户私钥对这个数字信息签名后返回服务器。 服务器随后使用`.ssh/authorized_keys`文件中存储的用户公钥来验证返回的信息是否由所对应的私钥所签名。这种验证方式可以有效证明试图登录的用户持有所需的私钥。

# Resources

- [Last year’s notes](https://missing.csail.mit.edu/2019/security/): from when this lecture was more focused on security and privacy as a computer user
- [Cryptographic Right Answers](https://latacora.micro.blog/2018/04/03/cryptographic-right-answers.html): answers “what crypto should I use for X?” for many common X.

> - [去年的讲稿](https://missing-semester-cn.github.io/2019/security/): 更注重于计算机用户可以如何增强隐私保护和安全
> - [Cryptographic Right Answers](https://latacora.micro.blog/2018/04/03/cryptographic-right-answers.html): 解答了在一些应用环境下“应该使用什么加密？”的问题

# Exercises

1. Entropy.
   1. Suppose a password is chosen as a concatenation of four lower-case dictionary words, where each word is selected uniformly at random from a dictionary of size 100,000. An example of such a password is `correcthorsebatterystaple`. How many bits of entropy does this have?
      $$
      Entropy = log_2(100000^4) = 66 \ \#correcthorsebatterystaple
      $$

   2. Consider an alternative scheme where a password is chosen as a sequence of 8 random alphanumeric characters (including both lower-case and upper-case letters). An example is `rg8Ql34g`. How many bits of entropy does this have?
      $$
      Entropy = log_2((26+26+10)^8) = 48 \ \#rg8Ql34g
      $$

   3. Which is the stronger password?

      The first one.

   4. Suppose an attacker can try guessing 10,000 passwords per second. On average, how long will it take to break each of the passwords?
      $$
      \frac{\frac{\frac{100,000^4}{10^4}}{(365\times24\times3600)}}{2} = 108,500,000 \ years\\
      \frac{\frac{\frac{62^8}{10^4}}{(365\times24\times3600)}}{2} =346 \ years
      $$
      

2. **Cryptographic hash functions.** Download a Debian image from a [mirror](https://www.debian.org/CD/http-ftp/) (e.g. [from this Argentinean mirror](http://debian.xfree.com.ar/debian-cd/current/amd64/iso-cd/)). Cross-check the hash (e.g. using the `sha256sum` command) with the hash retrieved from the official Debian site (e.g. [this file](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS) hosted at `debian.org`, if you’ve downloaded the linked file from the Argentinean mirror).

   ```
   $ curl -O -L -C - https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-mac-12.4.0-amd64-netinst.iso
   $ curl -O https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS
   $ cat SHA256SUMS | grep debian-mac-12.4.0-amd64-netinst.iso
   $ shasum -a 256 debian-mac-12.4.0-amd64-netinst.iso
   $ diff <(cat SHA256SUMS | grep debian-mac-12.4.0-amd64-netinst.iso) <(shasum -a 256 debian-mac-12.4.0-amd64-netinst.iso)
   ```

   

   <img src="./Security and Cryptography/Screenshot 2023-12-22 at 22.17.50.png" alt="Screenshot 2023-12-22 at 22.17.50" />

3. **Symmetric cryptography.** Encrypt a file with AES encryption, using [OpenSSL](https://www.openssl.org/): `openssl aes-256-cbc -salt -in {input filename} -out {output filename}`. Look at the contents using `cat` or `hexdump`. Decrypt it with `openssl aes-256-cbc -d -in {input filename} -out {output filename}` and confirm that the contents match the original using `cmp`.

   <img src="./Security and Cryptography/Screenshot 2023-12-22 at 22.29.51.png" alt="Screenshot 2023-12-22 at 22.29.51" />

4. Asymmetric cryptography.
   1. Set up [SSH keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) on a computer you have access to (not Athena, because Kerberos interacts weirdly with SSH keys). Make sure your private key is encrypted with a passphrase, so it is protected at rest.

      <img src="./Security and Cryptography/Screenshot 2023-12-22 at 22.32.33.png" alt="Screenshot 2023-12-22 at 22.32.33" />

   2. [Set up GPG](https://www.digitalocean.com/community/tutorials/how-to-use-gpg-to-encrypt-and-sign-messages)

      <img src="./Security and Cryptography/Screenshot 2023-12-22 at 22.34.28.png" alt="Screenshot 2023-12-22 at 22.34.28" />

   3. Send Anish an encrypted email ([public key](https://keybase.io/anish)).

      <img src="./Security and Cryptography/Screenshot 2023-12-22 at 22.37.57.png" alt="Screenshot 2023-12-22 at 22.37.57" />

   4. Sign a Git commit with `git commit -S` or create a signed Git tag with `git tag -s`. Verify the signature on the commit with `git show --show-signature` or on the tag with `git tag -v`.

      <img src="./Security and Cryptography/Screenshot 2023-12-22 at 23.23.54.png" alt="Screenshot 2023-12-22 at 23.23.54" />

      <img src="./Security and Cryptography/Screenshot 2023-12-22 at 23.24.18.png" alt="Screenshot 2023-12-22 at 23.24.18" />