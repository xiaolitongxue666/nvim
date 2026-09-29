# Practical Vim 与当前 nvim 键位对照

笔记权威来源：[iampkuhz/Practival-Vim](https://github.com/iampkuhz/Practival-Vim)（技巧 1–121，对应中文第 1 版）。英标题取自第 1 版 TOC。第 2 版是 123 条，约技巧 97 之后编号不同，本表不按第 2 版改号。

「作用」按各条 `tipN.md` 正文写，不以笔记 README 的键位摘要为准（例如技巧 13 的 README 写成 `<C-x>`，正文是 `<C-h>`）。键位描述来自 [lua/keybindings.lua](../lua/keybindings.lua) 与各插件 `desc`。

状态含义：

- **内置**：书上的键没有被映射改掉
- **改键**：同一类动作有你的键，和书不同
- **插件**：配置里用插件键覆盖了同类能力（写出 `desc`）
- **挡住**：书上的键现在做别的事
- **命令**：没有 leader 封装，在 `:` 里手打
- **已配置**：选项或行为已打开，没有单独快捷键
- **未配置**：当前环境没有对应能力

查自己的键：`<leader>fk`（键位映射）、`<leader>?`（缓冲区本地键位映射）。

## 先记这张改键表

普通模式 / 可视模式（[lua/keybindings.lua](../lua/keybindings.lua)）：

- 左 `j`，下 `k`，上 `i`，右 `l`
- 插入 `h`，行首插入 `H`，行尾追加仍是 `A`，光标后插入仍是 `a`
- 上一词 `J`（书上的 `b`），下一词 `L`（书上的 `w`），行尾 `E`（书上的 `$`）
- 上 5 行 `I`，下 5 行 `K`
- 保存 `S`，退出 `Q`，重载配置 `R`（`:source $MYVIMRC`）
- 下一搜索 `n`（带 `zz` 居中），上一搜索 `N`，取消高亮 `<leader><CR>`（`:nohlsearch`）
- 跳转前进 `<A-[>`（即 `<C-i>`），跳转后退 `<A-]>`（即 `<C-o>`）
- 分屏：`si` 上、`sk` 下、`sj` 左、`sl` 右；窗口焦点 `<leader>i/k/j/l`
- 显示路径 `sp`；切换大小写 `<leader>sc`

会被书上的例子踩到的键：

- `R` 是重载配置，替换模式进不去（技巧 19）
- `S` 是保存，整行替换 `S` 进不去
- `Q` 是退出，Ex 模式 `Q` 进不去
- `E` 是行尾，WORD 结尾的 `E` 进不去
- `s` 后面若接 `i/k/j/l/h/v/p` 会走分屏或 `sp` 显示路径（`timeoutlen` 300ms）。技巧 3 的 `s` 要停一下或改用 `cl`
- 插入模式 `<C-k>` 是「签名帮助」，二合字母 `<C-k>` 被挡住（技巧 18）
- hardtime 在 1 秒内连按 `i/k/j/l` 超过 3 次会拦住（[lua/plugins/practice_hardtime.lua](../lua/plugins/practice_hardtime.lua)）

宏相关键没有改：`q`、`@`、`@@`、`.`、`u`、`"`、`<C-r>`。

```mermaid
flowchart LR
  dot[". 重复上次修改"]
  normalRange[":normal 对行范围重放"]
  macro["q 录制 / @ 回放"]
  sub[":s 与 :g"]
  spectre["leader sr 替换"]
  dot --> normalRange --> macro
  dot --> sub --> spectre
```

## 第〇部分 技巧 1–6

第 1 章：Vim 解决问题的方式。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 1 | 认识 `.` 命令 / Meet the Dot Command | `.` 重复上次修改；顺带认识 `x` `u` `dd` 和 `>` 配动作做缩进 | `.` `u` `x` `dd` | 内置 |
| 2 | 不要自我重复 / Don’t Repeat Yourself | 用 `A` 代替 `$a`，把「行尾插入」收成一次修改，才能用 `.` 往下做 | 插入用 `h`/`H`/`a`/`A`，行尾用 `E` | 改键 |
| 3 | 以退为进 / Take One Step Back, Then Three Forward | 先退出插入，让插入变短可复用；再用 `f`/`s`/`;`/`.` 往下一处走 | `f` `;` `,` 可用；`s` 见上面的前缀 | 内置 / 挡住 |
| 4 | 执行、重复、回退 / Act, Repeat, Reverse | 移动和修改都做成可重复的，用 `.` 前进、`u` 回退 | `.` `u` | 内置 |
| 5 | 查找并手动替换 / Find and Replace by Hand | 不能一把 `:s` 时，用 `*`/`#` 跳到同词再 `cw` 手改；需要确认再用带 `c` 的 `:s` | `*` `#` 可用；`n`/`N` 居中；跨文件见 `<leader>sr` 替换 | 内置 / 改键 / 插件 |
| 6 | 结识 `.` 范式 / Meet the Dot Formula | 一键移到下一处目标，一键 `.` 执行（`j.`、`;.`、`n.`） | `.` | 内置 |

## 第一部分 模式

在不同的模式上按键，产生的效果可能不同。

### 第 2 章 普通模式

普通模式可以指定次数；次数少按键，但有时连点比先数更快。普通模式：操作符 + 动作命令。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 7 | 停顿时请移开画笔 / Pause with Your Brush Off the Page | 普通模式是休息态，多数时间在思考、阅读、移动；也可以直接在普通模式改，不必总进插入 | 习惯，无额外键 | 内置 |
| 8 | 把撤销的单元切成块 / Chunk Your Undos | 从进插入到 `<Esc>` 算一次修改。行尾要另起一行时用 `<Esc>o`，不要在插入里回车，否则 `u` 会连上一行一起撤 | `<Esc>` 后 `o` | 内置 |
| 9 | 尽量构造可重复的修改 / Compose Repeatable Changes | 光标在词尾时比较 `dbx`、`bdw`、`daw`：只有 `daw` 能稳定用 `.` 再删下一个词 | `d`/`c`/`y` + 文本对象；词移动用 `J`/`L` | 内置 / 改键 |
| 10 | 用次数做简单的算术运算 / Use Counts to Do Simple Arithmetic | 次数加在普通命令前；`<C-a>`/`<C-x>` 给光标处（或行内下一个）数字加减 | `<C-a>` `<C-x>` | 内置 |
| 11 | 能够重复，就别用次数 / Don’t Count If You Can Repeat | `d6w` 和 `dw.` 两派：数得清、数得快用次数；数不清用 `.` 所见即所得 | `.`（和 hardtime 同一方向） | 内置 |
| 12 | 操作 + 操作符 双剑合璧 / Combine and Conquer | 操作符（`d` `y` `c` `gU` `g~` `=` 等）加上动作（含文本对象）才是一条完整修改 | 同上；单字符另有 `<leader>sc` 切换字符大小写 | 内置 |

### 第 3 章 插入模式

大多数操作都在非插入模式中实现（复制、删除、剪切、粘贴）。不离开插入模式就可以粘贴寄存器中的文本。也可以插入键盘上不存在的字符。替换模式是插入模式的特例。插入-普通模式是插入模式的子集。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 13 | 在插入模式中回退 / Make Corrections Instantly from Insert Mode | 插入里用 `<C-h>` 删一字、`<C-w>` 删一词、`<C-u>` 删到行首，不必回普通模式 | 同上（笔记正文是 `<C-h>`，不是 README 里的 `<C-x>`） | 内置 |
| 14 | 返回普通模式 / Get Back to Normal Mode | `<Esc>` 与 `<C-[>` 回普通模式；只要执行一条普通命令再继续插入，用 `<C-o>`（笔记例子是 `<C-o>zz`） | `<Esc>` 或 `<C-o>` | 内置 |
| 15 | 不离开插入模式，粘贴寄存器中的文本 / Paste from a Register Without Leaving Insert Mode | 先在普通模式 `yt,` 之类 yank，插入里 `<C-r>0` 贴出刚才复制的文本 | `<C-r>{寄存器}`；which-key 会弹出寄存器列表 | 内置 |
| 16 | 随时随地做运算 / Do Back-of-the-Envelope Calculations in Place | 表达式寄存器 `=` 跑一段 Vim 脚本；插入里 `<C-r>=` 把结果插进来 | `<C-r>=` | 内置 |
| 17 | 用字符编码插入非常用字符 / Insert Unusual Characters by Character Code | 知道编码时用 `<C-v>` 按十进制或 Unicode 插入；`ga` 查看当前字符编码 | `<C-v>` | 内置 |
| 18 | 用二合字母插入非常用字符 / Insert Unusual Characters by Digraph | 不知道编码时用 `<C-k>` 加两个字符插入特殊符号 | 插入 `<C-k>` 被「签名帮助」占用 | 挡住 |
| 19 | 使用替换模式替换已有文本 / Overwrite Existing Text with Replace Mode | `R` 进入替换模式，新字覆盖旧字直到 `<Esc>`；`r` 只换光标上那一个字符 | `r` 可用；`R` 现为重载配置 | 内置 / 挡住 |

### 第 4 章 可视模式

可视模式在选中区域上操作，分字符、行、列块。`.` 对行可视命令比较有用，对其它可视模式意义不大。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 20 | 深入理解可视模式 / Grok Visual Mode | `viw` 选中光标所在词；`<C-g>` 进选择模式才能用退格删选区；`c` 是删后进插入 | 选区内移动用 `i/k/j/l` | 内置 |
| 21 | 选择高亮区域 / Define a Visual Selection | `v` 字符、`V` 行、`<C-v>` 列块；`o` 把光标换到选区另一端；`gv` 重选上次 | 同上 | 内置 |
| 22 | 重复执行面向行的可视命令 / Repeat Line-Wise Visual Commands | 行可视做完缩进等之后，`.` 会按同样行数再做一遍 | `>` `.` | 内置 |
| 23 | 尽可能使用操作符命令，而不是可视命令 / Prefer Operators to Visual Commands Where Possible | 可视对 `.` 支持差。`vitU` 是两条命令，`gUit` 是一条，要重复时用后者 | `gU`/`gu` + 文本对象 | 内置 |
| 24 | 用列块可视模式编辑表格数据 / Edit Tabular Data with Visual-Block Mode | 列块选一列后删、`r\|` 改分隔符，或 `V` 再 `r-` 画分隔行 | `<C-v>`；块内上下用 `i`/`k` | 内置 |
| 25 | 修改列文本 / Change Columns of Text | 列块选中多行同一段后 `c`，改完 `<Esc>`，其余行同样被替换 | 同上 | 内置 |
| 26 | 在长短不一的高亮块中添加文本 / Append After a Ragged Visual Block | 列块用 `$` 拉到各自行尾后，在第一行 `A` 插入，`<Esc>` 后作用到其余行 | 同上 | 内置 |

### 第 5 章 命令行模式

Ex 本来是行编辑器，是 vi 的祖先。基于行的编辑用 Ex 命令。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 27 | 结识 Vim 的命令行模式 / Meet Vim’s Command Line | `:` 进命令行跑 Ex；`/` 查找和 `<C-r>=` 也进命令行。命令行里仍可用 `<C-w>` `<C-r>` 等 | `:`；`:` 与 `/` 有 nvim-cmp 补全 | 内置 / 插件 |
| 28 | 在一行或多个连续行上执行命令 / Execute a Command on One or More Consecutive Lines | 用行号、`.`、`$`、`%` 或查找地址指定范围，再 `p`、`:s` 等 | `:范围` 手打；界面是 `<leader>sp` 在当前文件中搜索、`<leader>sr` 替换 | 命令 / 插件 |
| 29 | 使用 `:t` `:m` 进行复制和移动行 / Duplicate or Move Lines Using ‘:t’ and ‘:m’ | `:t`（`:copy`）把行复制到地址下；`:m`（`:move`）把行挪走 | 手打 | 命令 |
| 30 | 在指定范围上执行普通模式命令 / Run Normal Mode Commands Across a Range | `:'<,'>normal .` 或 `:%normal A;`，对范围内每一行跑一条普通命令 | 手打。不录宏也能批量改 | 命令 |
| 31 | 重复上次的 Ex 命令 / Repeat the Last Ex Command | `:@:` 再跑上一条 Ex；`:@@` 再重复；顺带提到 `:bn` `:bp` | 手打 | 命令 |
| 32 | 自动补全 Ex 命令 / Tab-Complete Your Ex Commands | `<Tab>` 轮候选；`<C-d>` 列出全部；`wildmenu` 下用 Tab / `<C-n>` `<C-p>` 走列表 | `<Tab>`，以及 cmdline cmp | 插件 |
| 33 | 把当前单词插入到命令行 / Insert the Current Word at the Command Prompt | `<C-r><C-w>` 把光标下的词填进命令行；可先 `*` 再 `:%s//<C-r><C-w>/g` | 同上；`<leader>fs` 搜索当前单词、`<leader>sw` 搜索当前单词 | 内置 / 插件 |
| 34 | 回溯历史命令 / Recall Commands from History | `:` 后 `<Up>` 翻历史；`q:` 打开可编辑的命令行窗口 | `q:` `q/`（先 `q` 再 `:`，和单独 `q` 录宏不同） | 内置 |
| 35 | 运行 Shell 命令 / Run Commands in the Shell | `:!{cmd}` 调外部程序；`:read !` / `:write !` 把缓冲区当标准输入或接标准输出 | `<leader>/` 终端；`<leader>ts` 发送当前行到终端，可视模式同键「发送选中内容到终端」 | 插件 |

## 第二部分 文件

### 第 6 章 管理多个文件

缓冲区列表记录打开的所有文件；参数列表用来分组；Ex 命令可作用到每个文件；标签页分割窗口。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 36 | 用缓冲区列表管理打开的文件 / Track Open Files with the Buffer List | 磁盘上是文件，内存里是缓冲区。`:ls` 列出，`%` 当前、`#` 轮换；`:bnext` 等切换 | `<leader>fb` 缓冲区列表；`<leader>be` 缓冲区浏览器；`[b` / `]b` 与 `<leader>[` / `<leader>]`；`<leader>b` 关闭当前 buffer。`<C-^>` 交替缓冲 | 插件 / 内置 |
| 37 | 用参数列表将缓冲区分组 / Group Buffers into a Collection with the Argument List | `:args` 查看或指定一组文件，供 `:argdo` 统一处理 | 手打（技巧 69 跨文件宏靠它） | 命令 |
| 38 | 管理隐藏缓冲区 / Manage Hidden Files | 改过的缓冲有 `+`；未保存切走会挡。`hidden` 允许隐藏；退出时再决定写或丢 | `hidden` 已开；保存用 `S`；全部保存并退出 `<leader>Q` | 已配置 |
| 39 | 将工作区切分成窗口 / Divide Your Workspace into Split Windows | 窗口并排显示多个缓冲区。笔记正文：`<C-w>v` 垂直切分，`<C-w>s` 水平切分 | `si/sk/sj/sl`、`<leader>i/k/j/l`、`sh`/`sv`、`<leader>q` 关窗口 | 改键 |
| 40 | 用标签页将窗口分组 / Organize Your Window Layouts with Tab Pages | 标签页是容纳多个窗口的工作区，不是和缓冲一一对应；`:lcd` 设窗口本地目录 | `showtabline=0`，用 winbuf 的分屏顶栏，没有 `:tabedit` 键 | 插件 |

### 第 7 章 打开及保存文件

打开文件、配置 `path` 后用 `:find`、用 netrw 看目录树；无写权限或目录不存在时再处理保存。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 41 | 用 `:edit` 命令打开文件 / Open a File by Its Filepath Using ‘:edit’ | 绝对或相对路径打开。`:edit %<Tab>` 展开当前文件路径，`%:h` 是其所在目录 | `<leader>rc` 打开 nvim 配置；一般 `:e` | 改键 / 命令 |
| 42 | 使用 `:find` 打开文件 / Open a File by Its Filename Using ‘:find’ | 配好 `path`（如 `set path+=app/**`）后按文件名查找，不必先写路径 | `<leader>ff` 查找文件，`<leader>fr` 最近文件 | 插件 |
| 43 | 使用 netrw 管理文件系统 / Explore the File System with netrw | `:edit .` 或 `:Explore` 打开目录浏览器 | `<leader>e` / `<leader>fe` 文件浏览器（根目录），`<leader>E` / `<leader>fE` 文件浏览器（当前文件） | 插件 |
| 44 | 把文件保存到不存在的目录中 / Save Files to Nonexistent Directories | `<C-g>` 看路径；目录不存在时 `:!mkdir -p %:h` 再建目录保存 | `sp` 显示路径；`:!mkdir` 手打 | 改键 / 命令 |
| 45 | 以超级用户权限保存文件 / Save a File as the Super User | 只读打开改了很久才发现不能写时，用 `:write !sudo tee % > /dev/null` | 当前是 Windows，无对应键 | 未配置 |

## 第三部分 更快的移动和跳转

学习在文件内、文件间快速跳转。动作命令、操作符待决模式见 `:h motion`。

### 第 8 章 用动作命令在文档中快速跳转

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 46 | 让手指保持在本位行上 / Keep Your Fingers on the Home Row | ASDF 所在行是盲打停留行；用 `h j k l`，戒掉方向键 | 移动是 `j/k/i/l`；`I`/`K` 一次 5 行。连按会被 hardtime 拦住 | 改键 |
| 47 | 区分实际行和屏幕行 / Distinguish Between Real Lines and Display Lines | `wrap` 时一行可占多屏。`gj` `gk` `g0` `g$` 走屏幕行 | 仍是两键内置命令（`wrap=false`，通常重合） | 内置 |
| 48 | 基于单词移动 / Move Word-Wise | `w` `b` `e` `ge` 按词；`W` 按空白分隔的 WORD | 向前 `L`，向后 `J`，词尾 `e`/`ge`；WORD 尾的 `E` 被行尾占用 | 改键 / 挡住 |
| 49 | 对字符串进行查找 / Find by Character | 当前行内 `f`/`F`/`t`/`T`；`;` 同向、`,` 反向再找 | 同上 | 内置 |
| 50 | 通过查找进行移动 / Search to Navigate | `/` `?` 当动作；`n` `N` 到下一/上一处 | `/` `?` 可用；`n`/`N` 居中 | 内置 / 改键 |
| 51 | 用精确的文本对象选择选取 / Trace Your Selection with Precision Text Objects | `i)` `a"` `it` `at` 等按结构选，不靠数字符 | 同上（which-key 的 text_objects 会提示） | 内置 |
| 52 | 删除周边，修改内部 / Delete Around, or Change Inside | `iw` 改词内部，`aw` 连空白一起删，避免残留空格 | 同上 | 内置 |
| 53 | 设置位置标记，以便快速跳回 / Mark Your Place and Snap Back to It | `m{a-z}` 打标，`'{mark}` 跳回 | 同上；`<leader>fm` 标记列表 | 内置 / 插件 |
| 54 | 在匹配括号间跳转 / Jump Between Matching Parentheses | `%` 在配对括号间跳 | `%` | 内置 |

### 第 9 章 在文件间跳转

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 55 | 遍历跳转列表 / Traverse the Jump List | 定义、搜索、换文件等会入跳转列表；`<C-o>` 回、`<C-i>` 进 | `<A-[>` 前进、`<A-]>` 后退；`<leader>fj` 跳转列表 | 改键 / 插件 |
| 56 | 遍历改变列表 / Traverse the Change List | `:changes` 看改过的位置；`g;` `g,` 走改变列表；`` `. `` 上次修改，`gi` 上次插入 | 同上 | 内置 |
| 57 | 跳转到光标下的文件 / Jump to the Filename Under the Cursor | `gf` 把光标下的路径当文件打开，依赖 `path` | `gf`；代码跳转用 `gd` 跳转到定义、`<leader>ld` LSP 定义 | 内置 / 插件 |
| 58 | 用全局位置标记在文件间快速跳转 / Snap Between Files Using Global Marks | 大写标记跨文件；`` `{A-Z} `` 跳到该文件该位置 | 同上；列表仍是 `<leader>fm` | 内置 / 插件 |

## 第四部分 寄存器

寄存器是保存文本的容器，也用来录宏。

### 第 10 章 复制和粘贴

Vim 有几十个寄存器。粘贴可面向行或字符。可视粘贴和系统剪贴板见后几条。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 59 | 用无名寄存器实现删除、复制和粘贴 / Delete, Yank, and Put with Vim’s Unnamed Register | `x` `d` `y` `p` `P` 走无名寄存器；`xp` `ddp` `yyp` 做交换或复制行 | 同上。复制后会短暂高亮（`TextYankPost`） | 内置 |
| 60 | 深入理解 Vim 寄存器 / Grok Vim’s Registers | `"a` 具名；`"0` 最近一次 yank；`"_` 黑洞删除；`"+` 系统剪贴板 | 普通模式按 `"`、插入模式按 `<C-r>` 时 which-key 列出寄存器 | 内置 |
| 61 | 用寄存器中的内容替换高亮选取的文本 / Replace a Visual Selection with a Register | 可视 `p` 用寄存器盖住选区，同时把选区写回无名寄存器，所以 `u` 后再 `p` 无效 | 可视模式 `p` | 内置 |
| 62 | 把寄存器中的内容粘贴出来 / Paste from a Register | `p`/`P` 在后/前贴；`gp`/`gP` 贴完光标在末尾；插入用 `<C-r>{寄存器}` | 同上 | 内置 |
| 63 | 与系统粘贴板进行交互 / Interact with the System Clipboard | `"+` 与系统剪贴板；`pastetoggle` 避免粘贴时被自动缩进打乱 | `clipboard=unnamed` 已开，普通 `y`/`p` 走系统剪贴板（[lua/basic.lua](../lua/basic.lua)） | 已配置 |

### 第 11 章 宏

宏是 `.` 的加强版，适合相似的行、段落、文件。回放分串行找下一处，和并行对每行/每文件跑一次。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 64 | 宏的读取和执行 / Record and Execute a Macro | `q{寄存器}` 开始，再 `q` 停；`@{寄存器}` 播放，`@@` 再播刚才那条；`:reg a` 查看 | `qa` / `q` / `@a` / `@@` | 内置 |
| 65 | 规范光标位置、直达目标以及终止宏 / Normalize, Strike, Abort | 录时每条指令都要可重复：开头归位（`0`/`n`/`gg`），用 `w`/`f` 直达，动作失败则宏停（可 `1000@a`） | 宏里用 `0`、`f`、`L`/`J`、`E` | 内置 |
| 66 | 加次数回放宏 / Play Back with a Count | 数字加在 `@` 前连续播放；笔记也写了 `qq;.q` 这种把 `.` 录进宏的用法 | `5@a` | 内置 |
| 67 | 在连续的文本行上重复修改 / Repeat a Change on Contiguous Lines | 对连续行用 `:normal @a`（或先 `0` 归位再录），并行于每一行，不是串行找下一处 | 选中后 `:'<,'>normal @a` | 命令 |
| 68 | 给宏追加命令 / Append Commands to a Macro | `qA`（大写）往寄存器 `a` 末尾加按键，不必整段重录 | `qA` | 内置 |
| 69 | 在一组文件中执行宏 / Act Upon a Collection of Files | `:argdo normal @a` 对参数列表每个文件跑宏，再 `:argdo write` 或 `:wall` | 手打。搜索用 `<leader>fg`，替换用 `<leader>sr`，这两处不执行宏 | 命令 / 插件 |
| 70 | 用迭代求值的方式给列表编号 / Evaluate an Iterator to Number Items in a List | `:let i=0`，宏里 `<C-r>=i` 插入当前值再 `:let i=i+1` | 宏里 `<C-r>=i` 配 `:let i=i+1` | 内置 |
| 71 | 编辑宏的内容 / Edit the Contents of a Macro | `:put a` 把宏当文本贴出，改完 `"ay$` 存回寄存器 | `:put a` 后 `"ay$` | 命令 |

用本配置的键录一条「行尾加分号并到下一行」：

1. `qa` 开始
2. `E` 到行尾（书上是 `$`）
3. `a;<Esc>`
4. `k` 到下一行（书上是 `j`）
5. `q` 停止
6. `@a` 播放，接着 `@@` 或 `10@a`

录错就 `u` 撤销播放结果，用 `qA` 补按键，或 `:put a` 改文本后再存回寄存器。

## 第五部分 模式

pattern 用来写正则或原义查找。substitute 和 global 是两条强 Ex 命令。

### 第 12 章 按模式匹配和按原义匹配

查找是替换的前提。`very magic` / `very nomagic`、原义开关、零宽度定界符见各条。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 72 | 调整查找模式的大小写敏感性 / Tune the Case Sensitivity of Search Patterns | 模式里写 `\c` 不区分、`\C` 区分，覆盖这次查找 | `ignorecase` + `smartcase` 已开；强制用 `\c` `\C` | 已配置 |
| 73 | 使用 `\v` 模式进行正则表达式查找 / Use the \v Pattern Switch for Regex Searches | very magic：括号、`+`、`|` 少写反斜杠 | 在 `/` 里写 | 内置 |
| 74 | 完全匹配字符串时，使用 `\V` 查找 / Use the \V Literal Switch for Verbatim Searches | very nomagic：几乎按字面匹配 | 在 `/` 里写 | 内置 |
| 75 | 使用圆括号获取子匹配 / Use Parentheses to Capture Submatches | 括号抓住子串，替换里用 `\1` | 在 `/` 或 `:s` 里写 | 内置 |
| 76 | 使用 `\<` `\>` 界定单词边界 / Stake the Boundaries of a Word | 只匹配完整单词，避免改到词的一部分 | 在 `/` 里写 | 内置 |
| 77 | 界定匹配的边界（`\zs` `\ze`） / Stake the Boundaries of a Match | `\zs` `\ze` 标出真正要改的那段，前后只定位 | 在 `/` 里写 | 内置 |
| 78 | 转义问题字符 / Escape Problem Characters | 按字面搜 `?` 等时要转义（笔记标题「转移」即转义） | 在 `/` 里写 | 内置 |

### 第 13 章 查找

查找可补全、统计、预览。复杂模式靠历史迭代。也可查找当前选区。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 79 | 查找命令入门 / Meet the Search Command | `/` 正向、`?` 反向；`n`/`N` 继续 | `/` `?` 可用；`n`/`N` 居中 | 内置 / 改键 |
| 80 | 高亮查找匹配 / Highlight Search Matches | `hlsearch` 高亮所有匹配；`noh` 或 `<C-l>` 关掉 | `hlsearch` 已开；关掉高亮用 `<leader><CR>` | 已配置 |
| 81 | 在执行查找前预览第一处匹配 / Preview the First Match Before Execution | `incsearch` 边输入边跳到第一处 | `incsearch` 已开 | 已配置 |
| 82 | 统计当前模式的匹配个数 / Count the Matches for the Current Pattern | `:%s///gn` 只计数，不改文本 | 手打 | 命令 |
| 83 | 将光标偏移到查找匹配的结尾 / Offset the Cursor to the End of a Search Match | `/pattern/e` 让光标停在匹配末尾 | 手打 | 命令 |
| 84 | 对完整的查找匹配进行操作 / Operate on a Complete Search Match | 三种做法：数字符 `gU3l`；`gU//e` 会改查找偏移，不能靠 `n` 重复；可重复的是 `gUfl` 再 `n.` | `gUfl` 再 `n.` | 内置 |
| 85 | 利用查找历史，迭代完成复杂的模式 / Create Complex Patterns by Iterating upon Search History | 在 `q/` 里改上次模式，逐步凑出复杂正则再 `:s` | `q/` | 内置 |
| 86 | 查找当前高亮选区中的文本 / Search for the Current Visual Selection | 可视里 yank 再 `/<C-r>"`，把选区当搜索词 | `<leader>fs` 搜索当前单词；可视 `<leader>sw` 搜索当前选择；`<leader>fz` 当前缓冲区模糊搜索 | 插件 |

### 第 14 章 替换

替换命令中的查找域可以为空。支持跨文件。替换域可写脚本表达式。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 87 | 结识 substitute 命令 / Meet the Substitute Command | `:[range]s/{pattern}/{string}/[flags]` 的形状和常用标志 | 手打，或 `<leader>sr` 替换 | 命令 / 插件 |
| 88 | 在文件范围内查找并替换每一处匹配 / Find and Replace Every Match in a File | `:%s/old/new/g` 全文每一处都换 | 手打，或 `<leader>sp` 在当前文件中搜索 | 命令 / 插件 |
| 89 | 手动控制每一次替换操作 / Eyeball Each Substitution | 加 `c` 标志，每一处先确认 | 手打 | 命令 |
| 90 | 重用上次的查找模式 / Reuse the Last Search Pattern | `:s` 查找域留空，用上次 `/` 的模式 | 手打 | 命令 |
| 91 | 用寄存器的内容替换 / Replace with the Contents of a Register | 替换域写 `<C-r>0`，避免特殊字符难转义 | 手打 | 命令 |
| 92 | 重复上一次 substitute 命令 / Repeat the Previous Substitute Command | `g&`、`:&&`、`~` 在新范围或新标志下再跑上次 `:s` | 手打 | 命令 |
| 93 | 使用子匹配重排 CSV 文件的字段 / Rearrange CSV Fields Using Submatches | 先搜出各列，`:%s//\3,\2,\1` 重排 | 手打 | 命令 |
| 94 | 在替换过程中执行算术运算 / Perform Arithmetic on the Replacement | 替换域 `\=submatch(0)-1` 之类对匹配做运算 | 手打 | 命令 |
| 95 | 交换两个或更多的单词 / Swap Two or More Words | 用字典 `\={...}[submatch(1)]` 一次对调，避免 A→B 再把新 B 换回去 | 手打 | 命令 |
| 96 | 在多个文件中执行查找与替换 / Find and Replace Across Multiple Files | `:argdo %s` 或先 `:vimgrep` 再在结果上替换 | `<leader>fg` 实时搜索，再在 spectre 里替换；`:argdo %s` 仍可手打 | 插件 / 命令 |

界面：`<leader>sr` 替换，`<leader>sw` 搜索当前单词，`<leader>sp` 在当前文件中搜索（[lua/plugins/search_and_replace_nvim-spectre.lua](../lua/plugins/search_and_replace_nvim-spectre.lua)）。

### 第 15 章 global 命令

global 把 Ex 和模式匹配合在一起，在匹配行上跑命令。书里把它和点范式、宏并列。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 97 | 结识 global 命令 / Meet the Global Command | `:[range]g/{pattern}/{cmd}`；`g!` 或 `:v` 是不匹配的行 | 手打 | 命令 |
| 98 | 删除所有包含模式的文本行 / Delete Lines Containing a Pattern | `:g/模式/d` 删匹配行；`:v/模式/d` 删不匹配的行 | 手打 | 命令 |
| 99 | 将 TODO 项收集至寄存器 / Collect TODO Items in a Register | `:g/TODO/yank` 一类命令，把匹配行收集进寄存器 | 手打 | 命令 |
| 100 | 将 CSS 文件中所有规则的属性按照字母排序 / Alphabetize the Properties of Each Rule in a CSS File | `:g/{/ .+1,/}/-1 sort` 对每个规则块内部排序 | 手打 | 命令 |

选用顺序：同一处改一次用 `.`；同一套按键走多行用宏；整块文本符合正则用 `:s` 或 `<leader>sr`；只处理匹配行用 `:g`。

## 第六部分 工具

Vim 内可以调用 make、grep 等外部程序，也提供拼写检查和自动补全。本配置里后几章多用插件做同类事。

### 第 16 章 通过 ctags 建立索引，并用其浏览源代码

ctags 用来跳到函数和类的定义，结果也可供补全。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 101 | 结识 ctags / Meet ctags | 外部程序扫源码，生成 tags 文件 | 无 ctags。用 `gd` 跳转到定义、`<leader>ld` LSP 定义 | 插件 |
| 102 | 配置 Vim 使用 ctags / Configure Vim to Work with ctags | `:set tags?` 看路径；改代码后 `:!ctags -R` 重建 | 同上 | 插件 |
| 103 | 使用 Vim 的标签跳转命令 / Navigate Keyword Definitions with Vim’s Tag Navigation Commands | `<C-]>` 到定义，`<C-t>` 回来；`g<C-]>` / `:tjump` 有多处时选 | `<leader>ls` 文档符号、`<leader>lw` 工作区符号、`<leader>ft` Treesitter 符号、`<leader>O` 打开代码大纲 | 插件 |

### 第 17 章 编译代码，并通过 Quickfix 列表浏览错误信息

Quickfix 保存文件名、行号和消息，供在编译错误之间跳。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 104 | 不用离开 Vim 也能编译代码 / Compile Code Without Leaving Vim | `:make` 编译，错误进 Quickfix，`:cnext` 下一条 | `<leader>or` 选择并运行任务，`<leader>of` 运行当前文件模板，`<leader>oo` 切换任务列表 | 插件 |
| 105 | 浏览 Quickfix 列表 / Browse the Quickfix List | `:cnext` `:cprev` `:copen` `:cc N` 等在条目间跳 | `<leader>fq` 快速修复列表；诊断 `]d`/`[d`、`<leader>cd` 行诊断、`<leader>cq` 诊断列表、`<leader>fd` 诊断信息 | 插件 |
| 106 | 回溯以前的 Quickfix 列表 / Recall Results from a Previous Quickfix List | `:colder` `:cnewer` 换到更早或更新的那一份结果 | 手打 | 命令 |
| 107 | 定制外部编译器 / Customize the External Compiler | `errorformat` 教 Vim 如何从编译器输出里拆出行号 | 交给 overseer 模板 | 插件 |
| — | （本配置补充，不是书上技巧） | 把 Git hunk 送进 Quickfix | `<leader>ghq` Git: 所有 Hunks 到 Quickfix | 插件 |

### 第 18 章 通过 grep、vimgrep 以及其他工具对整个工程进行查找

`:grep` 调外部程序，也可换成 ack。`:vimgrep` 用 Vim 正则搜多文件。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 108 | 不必离开 Vim 也能调用 grep / Call grep Without Leaving Vim | `:grep` 在工程里搜，结果进 Quickfix | `<leader>fg` 实时搜索 | 插件 |
| 109 | 定制 grep 程序 / Customize the grep Program | `grepprg` `grepformat` 指定用哪套程序和输出格式 | snacks.picker 使用 `rg` | 插件 |
| 110 | 使用 Vim 内部的 Grep / Grep with Vim’s Internal Search Engine | `:vimgrep` 按 Vim 正则搜多文件 | `<leader>fs` 搜索当前单词，`<leader>rs` 恢复上次搜索 | 插件 |

### 第 19 章 自动补全

补全来源可以是缓冲区、头文件、标签。第 1 版到技巧 117 为止，没有第 2 版多出来的「词序列补全」。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 111 | 结识 Vim 的关键字自动补全 / Meet Vim’s Keyword Autocompletion | `<C-n>` `<C-p>` 用已有关键字补全 | nvim-cmp 的 `<Tab>` / `<S-Tab>` 选择，`<C-Space>` 弹出，`<CR>` 确认。`<C-n>` `<C-p>` 仍是 Vim 自带补全 | 插件 / 内置 |
| 112 | 与自动补全的弹出式菜单进行交互 / Work with the Autocomplete Pop-Up Menu | 菜单里 `<C-n>` 向下、`<C-p>` 向上 | 同上 | 插件 |
| 113 | 掌握关键字的来龙去脉 / Understand the Source of Keywords | `<C-x><C-n>` 当前缓冲、`<C-x><C-i>` 包含文件、`<C-x><C-]>` tags | cmp 来源是 LSP、LuaSnip、Buffer、Path | 插件 |
| 114 | 使用字典中的单词进行自动补全 / Autocomplete Words from the Dictionary | `<C-x><C-k>` 从拼写字典补；常先 `:set spell` | 无单独键；可先 `:set spell` | 部分 |
| 115 | 自动补全整行文本 / Autocomplete Entire Lines | 补出与已有行相同的一整行 | 无单独映射 | 未配置 |
| 116 | 自动补全文件名 / Autocomplete Filenames | `<C-x><C-f>` 按路径补文件名 | cmp 的 Path 源 | 插件 |
| 117 | 根据上下文自动补全 / Autocomplete with Context Awareness | `<C-x><C-o>` omni，按文件类型上下文补 | cmp 的 LSP 源 | 插件 |

### 第 20 章 利用 Vim 的拼写检查器，查找并更正拼写错误

可按语言换字典；插入模式也能改拼写；单词表可 `zg`/`zw` 增减。

| 技巧 | 标题 | 作用 | 本配置 | 状态 |
|------|------|------|--------|------|
| 118 | 对你的工作进行拼写检查 / Spell Check Your Work | `:set spell` 后 `]s` `[s` 跳到错词，`z=` 选建议 | which-key 在 `z=` 时给出建议 | 部分 |
| 119 | 使用其他拼写字典 / Use Alternate Spelling Dictionaries | `:set spelllang=en_us` 等换地区字典 | 手打 | 命令 |
| 120 | 将单词添加到拼写文件中 / Add Words to the Spell File | `zg` 标为正确，`zw` 标为错误，写入拼写文件 | 手打，要先打开 spell | 命令 |
| 121 | 在插入模式下更正拼写错误 / Fix Spelling Errors from Insert Mode | 插入里 `<C-x>s` 纠正当前词 | 手打，要先打开 spell | 命令 |

## 自动化：从点命令到宏、再到工程级替换

书上第 11 章把宏写成「`.` 的加强版」：一次改不完、又还没到能写成一条正则时，就录按键再回放。回放有两种走法（[技巧 67](#第-11-章-宏)，[O'Reilly 对串行/并行的说明](https://www.oreilly.com/library/view/practical-vim-2nd/9781680501629/f_0102.xhtml)）：

- **串行**：在普通模式 `@a` / `10@a`。上一次结束时光标必须已经站在下一处目标上。中途动作失败（例如 `f{` 找不到），后面全部停。适合「改完必须走到下一处」的链。
- **并行**：先定范围，再 `:normal @a`。每一行（或每个文件）单独开一次 `@a`，一行失败不影响下一行。[Learn-Vim](https://yongfu.name/Learn-Vim/chapters/ch09_macros.md.html) 也按这个口径写。

选用顺序：一处小改用 `.` → 同一套按键、目标形状差不多用宏 → 文本能写成模式用 `:s` / `<leader>sr` → 只处理匹配行用 `:g`。

宏相关键没改：`q`、`@`、`@@`、`.`。录的时候用本配置的移动：行尾 `E`、下一行 `k`、上一词 `J`、下一词 `L`。按 `"` 时 which-key 能看到寄存器里录了什么。

### 1. 点命令：改一次，其余用 `.`

适用：每处都是同一种修改，下一处用一键就能走到（技巧 6 的点范式）。

1. 先改第一处，保证整段是**一次**修改（进插入到 `<Esc>` 算一次；不要在插入里回车续行，见技巧 8）。
2. 一键到下一处：`k` 下一行、`;` 同行下一个 `f`、`n` 下一处搜索（会 `zz` 居中）。
3. `.` 再改。错了 `u`。

手改同词：光标在词上 `*`，`cw` 改完 `<Esc>`，然后 `n.`。需要确认再用 `:%s/旧/新/gc`。

### 2. 录宏并串行回放

适用：一次要按好几下，但下一处仍能一键走到。

1. 光标放到**第一处还没改**的位置。
2. `qa` 开始（寄存器用 `a`～`z`，别用正在用的 yank 寄存器）。
3. 先归位再直达（技巧 65）：行首 `0`、文件头 `gg`、或已经 `/` 过就 `n`。用 `f` / `L` / `J` / `E`，不要连按 `j j j`。
4. 做完这一处该做的修改。
5. **最后一步**走到下一处（例如 `k` 到下一行）。这样 `@a` 才能接着跑。
6. `q` 停止。`:reg a` 查看。
7. `@a` 播一次。对了再用 `@@`，或 `20@a`。次数多一点没关系：动作失败宏会停（可 `1000@a`）。

行尾加分号、再下一行（本配置键）：

1. `qa`
2. `E`
3. `a;<Esc>`
4. `k`
5. `q`
6. `@a`，然后 `@@` 或 `10@a`

录漏了：`qA`（大写）往 `a` 末尾追加按键。要大改：`:put a` 把宏贴成文本，改完 `"ay$` 存回（技巧 71）。播错了先 `u` 撤播放结果，不要在错的文本上继续 `@`。

把 `.` 收进宏：`qq;.q`，之后 `@q`（技巧 66 笔记）。

### 3. 并行：对每一行跑一次宏（一行失败不影响下一行）

适用：很多行要做同一套事，但中间可能有行对不上（没有那个字符、已经是目标格式）。串行 `99@a` 会在第一处失败后整段停掉；并行对每一行单独 `@a`。

先录**只处理当前行**的宏，末尾**不要** `k` 到下一行（并行由范围负责换行）：

1. `qa`
2. `0`
3. 这一行的修改（例如 `f.` `r)` `Lw~`）
4. `q`

再定范围并回放：

- 可视选中那些行（`V` 再 `i`/`k`），`:` 会变成 `:'<,'>`，补上 `normal @a` 回车。
- 或手打 `:10,40normal @a`、`:%normal @a`。
- 只处理匹配行：先 `/模式`，再 `:g//normal @a`（技巧 97：`:g` 的模式留空就用上次查找）。

`:normal` 后面是普通模式键序列，不一定是宏。例如 `:%normal A;` 是每行行尾进插入加分号（技巧 30），不必先 `q`。

### 4. 跨文件跑宏

适用：同一套按键要落到一组文件，而不是一条 `:s` 能写完。

并行（推荐先用这个，避免第一个文件跑两遍，技巧 69）：

1. `:args *.c` 或 `:args **/*.lua` 填参数列表，`:args` 查看。
2. `:first`，在**第一个文件**上按「第 2 节」录宏。录的时候**不要** `:w`。
3. `:edit!` 丢掉第一个文件这次改动（否则下一步会再跑一遍）。
4. `:argdo normal @a`
5. `:wall` 或 `:argdo update`

串行：宏末尾加上 `:wnext`（保存并到参数列表下一个文件），然后 `100@a`。文件用完后 `:next` 失败，宏停。

本配置 `hidden` 已开，切文件不会被「未保存」挡住。`<leader>fg` / `<leader>sr` **不会**替你执行宏，只负责搜和替换文本。

### 5. 用模式批量改（不必录宏）

文本形状稳定时，正则比宏短。

当前文件：

- `:%s/旧/新/g` 全部换。
- `:%s/旧/新/gc` 每一处问（技巧 89）。
- 先 `/旧` 确认高亮，再 `:%s//新/g`（查找域空 = 上次模式，技巧 90）。
- 只删匹配行：`:g/模式/d`；只留匹配行：`:v/模式/d`（技巧 98）。
- 匹配行上跑普通命令：`:g/TODO/normal A;`。

一组文件：`:argdo %s/旧/新/ge | update`（`e` 表示某文件没有匹配也不报错）。

### 6. 界面：spectre 工程级替换（类似「先搜再批改」）

键在 [lua/plugins/search_and_replace_nvim-spectre.lua](../lua/plugins/search_and_replace_nvim-spectre.lua)。leader 是空格。面板里的 `<leader>R` 是「空格再 R」，**不是**普通模式那个重载配置的 `R`。

打开：

| 键 | 做什么 |
|----|--------|
| `<leader>sr` | 打开 / 关掉替换面板（工程） |
| `<leader>sw` | 用光标下的词打开；可视模式则用选区 |
| `<leader>sp` | 只在当前文件里搜光标下的词 |

面板里怎么做（[nvim-spectre](https://github.com/nvim-pack/nvim-spectre)）：

1. 在 Search 行输入模式，Replace 行输入替换文本。用 `<Esc>` 离开插入（不要用 `<C-c>`）。
2. 结果出现在下面。`dd` 排除或重新纳入某一处，再批量替换时不会动被排除的。
3. 看某一处：光标放到结果行回车（本配置映射是「跳转到文件」）。
4. 先换一处：`<leader>rc`。确认无误再 `<leader>R` 换全部纳入的项。
5. 需要先当列表看、不立刻换：`<leader>q` 送到 quickfix，再用 `<leader>fq` 快速修复列表跳。

面板内其它键：`ti` 忽略大小写，`th` 搜隐藏文件，`tu` 实时更新，`<leader>o` 选项，`<leader>l` 恢复上次搜索。

官方说明：spectre **几乎不能靠 `u` 整批撤**，先提交或备份再 `<leader>R`。换完若缓冲还是旧内容，对该文件 `:e` 重读。

### 7. 先搜、再自己决定怎么改

要看分布、还不想写替换式：

1. `<leader>fg` 实时搜索（snacks.picker + `rg`），进结果再改。
2. 只在当前缓冲扫行：`<leader>fz`。
3. 光标下的词：`<leader>fs`。
4. 已经在 quickfix 里：`<leader>fq`。

搜到之后仍可用第 1～3 节：`n.` 或录宏再 `@a`。这是「搜索当动作、修改用点/宏」，不是 spectre 那种一次换完。

