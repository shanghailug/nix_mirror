# NixOS镜像脚本

脚本共分为2个，对应镜像的2个步骤：下载频道数据、下载更新的二进制包。

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

## 2.download_binary_cache.sh

该脚本负责从二进制缓冲中下载数据，具体用法如下：

```shell
./2.download_binary_cache.sh LOCAL_NIX_CHANNEL_DIR
```

数据保存的路径为Nix频道数据所在目录，的名为`store`的目录。接着上一个脚本，例子如下：
```shell
./2.download_binary_cache.sh ./nixos-19.09/channel
```

对于nixos-19.09频道，首次下载需要花较长的时间，大概需要80G的磁盘空间。下载过程中，该脚本有时会出错，反复执行该脚本，直到不出错为止即可（返回值为0）。

## diff_size.sh

该脚本用来计算新的Nix频道需要新增多少二进制数据量：

```shell
./diff_size.sh STORE_URL OLD_CHANNEL_PATH NEW_CHANNEL_PATH
```

假设上次的Nix频道数据为`./nixos-19.09.1776.b926503738c`，新更新的频道数据为`./nixos-19.09.1815.caad1a78c47`。那么通过下面命令可以计算需要新更新多是数据量（nar的数据量和下载数据量）：

```shell
./diff_size.sh https://cache.nixos.org nixos-19.09.1776.b926503738c nixos-19.09.1815.caad1a78c47
```

第一次执行该命令时，会比较慢。后续执行会快很多，因为`narinfo`数据已经被缓存到`~/.cache/nix/`中的SQLite数据库中。

