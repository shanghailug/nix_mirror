# NixOS镜像脚本

脚本共分为3个，对应镜像的3个步骤：下载频道数据、处理重复的二进制包、下载更新的二进制包。

## 1.mirror_channel.sh

该脚本的功能是下载某个Nix频道当前的数据（iso和ova除外），具体如下：

```shell
./1.mirror_channel.sh NIX_CHANNEL_URL LOCAL_DIR
```

两个参数分别为Nix频道的URL以及数据在本地存放的目录。

以下载nixos-19.09的数据`./nixos-19.09`为例，则命令如下：
```shell
./1.mirror_channel.sh https://nixos.org/channels/nixos-19.09 ./nixos-19.09
```

下载的数据放在指定目录的一个子目录，该子目录以Nix频道重定向后的URL最末尾部分命名。此外，下载完后，脚本还会在指定目录创建一个名为`channel`的符号链接，指向下载了数据的子目录。

## 2.hard_link_files.sh

该脚本把当前需要下载的二进制包中，和上一版本重复的，建立硬链接以减少下载量，具体用法如下：

```shell
./2.hard_link_files.sh LOCAL_NIX_CHANNEL_DIR
```

唯一的参数是二进制包对应的Nix频道数据。该脚本的数据输出为频道数据目录加`.store`后缀的目录。脚本运行时，会假定上一版本的二进制包数据保存在统一层次下名为`store`的目录（或符号链接）中。若`store`不存在，该脚本直接返回。

该脚本还会创建一个名称为数据目录加上`.new`后缀的文本文件，文件内包含`store`不保存包的列表，供后面的脚本使用。

以接着前一个脚本的例子为例，则命令应该如下：

```shell
./2.hard_link_files.sh ./nixos-19.09/channel
```

## 3.download_binary_cache.sh

该脚本负责从二进制缓冲中下载数据，具体用法如下：

```shell
./3.download_binary_cache.sh LOCAL_NIX_CHANNEL_DIR
```

数据保存的路径和上一个脚本相同。接着上一个脚本，例子如下：
```shell
./3.download_binary_cache.sh ./nixos-19.09/channel
```

对于nixos-19.09频道，首次下载需要花较长的时间，大概需要80G的磁盘空间。下载过程中，该脚本有时会出错，反复执行该脚本，直到不出错为止即可（返回值为0）。



