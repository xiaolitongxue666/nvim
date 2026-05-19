# 如何查看和管理当前 LSP

本配置使用 **nvim-lspconfig** + **mason.nvim** + **mason-lspconfig**，并采用 Neovim 0.11+ 的 `vim.lsp.config` / `vim.lsp.enable` API。下面说明如何查看和管理 LSP。

---

## 一、查看当前 LSP

### 1. 查看当前缓冲区已附加的 LSP 客户端

在 Neovim 中执行：

```vim
:LspInfo
```

会打开 LSP 信息窗口，显示：

- 当前 buffer 已附加的**语言服务器**（如 `lua_ls`、`pyright`）
- 各服务器的**根目录**、**cmd**、**能力**等
- 若未附加，会提示可能原因（如文件类型未匹配、服务器未安装等）

若没有 `:LspInfo` 命令（旧版 Neovim），可用 Lua 查看已附加的 client：

```vim
:lua print(vim.inspect(vim.lsp.get_clients({ bufnr = 0 })))
```

或在命令栏执行：

```vim
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do print(c.name) end
```

### 2. 查看所有已配置并启用的 LSP 服务器（Neovim 0.11+）

配置里通过 `vim.lsp.config(server, config)` 和 `vim.lsp.enable(server)` 注册的服务器，可通过：

```vim
:lua print(vim.inspect(vim.lsp.get_configs()))
```

查看当前已注册的配置表（键为服务器名，如 `lua_ls`、`pyright`）。

### 3. 查看诊断（错误/警告）

- **当前行诊断浮窗**：`<leader>cd`（在 `lsp_server_nvim-lspconfig.lua` 中绑定）
- **下一个/上一个诊断**：`]d` / `[d`
- **诊断列表**：`<leader>cq`（填入 location list）

---

## 二、管理 LSP：安装 / 卸载 / 更新（Mason）

通过 **Mason** 管理 LSP 服务器、DAP、linter、formatter 等。

### 1. 打开 Mason 界面

- 命令：`:Mason`
- 键位：`<leader>cm`（即 `\cm`，leader 默认为 `\`）

在 Mason 窗口中可以：

- 浏览所有可用包（LSP、DAP、linter、formatter 等）
- **安装**：光标移到未安装的包，按 `i`
- **卸载**：光标移到已安装的包，按 `X`
- **更新单个包**：按 `u`
- **更新所有包**：按 `U`
- **检查过期**：按 `C`
- **按语言过滤**：`<C-f>`

### 2. 更新 Mason 注册表

- 命令：`:MasonUpdate`
- 键位：`<leader>cM`

用于更新可用包列表，安装新包前建议先执行一次。

### 3. 当前配置中已启用的 LSP 服务器

在 `lua/plugins/lsp_server_nvim-lspconfig.lua` 的 `servers` 中显式配置了：

| 服务器名     | 语言/用途   |
|-------------|------------|
| `lua_ls`    | Lua        |
| `pyright`   | Python     |
| `ruff_lsp`  | Python（检查/格式） |
| `rust_analyzer` | Rust   |
| `clangd`    | C/C++      |
| `bashls`    | Bash       |
| `jsonls`    | JSON       |
| `yamlls`    | YAML       |
| `marksman`  | Markdown   |

`mason-lspconfig` 的 `ensure_installed` 会确保上述部分服务器通过 Mason 自动安装（如 lua_ls、bashls、clangd、pyright、rust_analyzer、jsonls、yamlls、marksman）；`ruff_lsp` 等在 mason-tool-installer 或 Mason 中单独安装。

---

## 三、常用 LSP 键位（当前配置）

在已附加 LSP 的 buffer 中可用（来自 `lsp_server_nvim-lspconfig.lua`）：

| 键位 | 功能 |
|------|------|
| `gd` | 跳转到定义 |
| `gD` | 跳转到声明 |
| `gr` | 查找引用 |
| `gI` | 跳转到实现 |
| `gy` | 跳转到类型定义 |
| `D` | 悬停文档 |
| `gK` | 签名帮助（normal） |
| `<c-k>` | 签名帮助（insert） |
| `<leader>cr` | 重命名 |
| `<leader>ca` | 代码操作（normal/visual） |
| `<leader>cf` | 格式化 |
| `<leader>wa` | 添加工作区文件夹 |
| `<leader>wr` | 移除工作区文件夹 |
| `<leader>wl` | 列出工作区文件夹 |
| `<leader>cd` | 当前行诊断浮窗 |
| `]d` / `[d` | 下一个/上一个诊断 |
| `<leader>cq` | 诊断列表 |

---

## 四、添加或关闭某个 LSP 服务器

### 添加新服务器（例如新语言）

1. 在 Mason 中确认该 LSP 是否可用：`:Mason`，搜索并安装（如 `texlab`）。
2. 在 `lua/plugins/lsp_server_nvim-lspconfig.lua` 的 `opts.servers` 里增加一项，例如：

   ```lua
   servers = {
       -- ... 现有配置 ...
       texlab = {},  -- 或按需写 settings/init_options
   },
   ```

3. 若使用 mason-lspconfig 的 `ensure_installed`，在 `lua/plugins/lsp_server_manager_mason-lspconfig.lua` 里把该服务器名加入列表，便于首次自动安装。

### 临时关闭某个 LSP

- **只对当前会话**：可用 `:LspStop <client_id>` 或 Lua 中 detach 当前 buffer 的 client（一般用不到）。
- **长期关闭某服务器**：在 `lua/plugins/lsp_server_nvim-lspconfig.lua` 的 `servers` 中**删除或注释**对应服务器配置，并**不要**对该服务器调用 `vim.lsp.enable(server)`（当前是循环里对 `opts.servers` 中每一项都 `vim.lsp.config` + `vim.lsp.enable`，删掉该 server 即不再启用）。

---

## 五、排查“没有 LSP”的常见点

1. **`:LspInfo` 显示未 attach**  
   - 看文件类型是否被该服务器匹配（如 `.lua` → lua_ls）。  
   - 确认该 LSP 已安装：在 Mason 里查看对应包是否已安装。

2. **Mason 里没有某个 LSP**  
   - 先 `:MasonUpdate` 更新注册表再搜索。  
   - 若仍没有，说明 mason 未收录该 LSP，需自行安装并在 lspconfig 里配置 cmd。

3. **Neovim 版本**  
   - 本配置使用 `vim.lsp.config` / `vim.lsp.enable`，需要 **Neovim 0.11.0+**。  
   - 若版本不足，会收到错误提示，需升级 Neovim。

4. **诊断不显示**  
   - 确认 `vim.diagnostic.config` 已生效（配置里在 lspconfig 的 config 中调用了）。  
   - 用 `<leader>cd` 或 `:lua vim.diagnostic.show()` 看是否有诊断数据。

---

以上内容对应你当前的 `lua/plugins/lsp_server_nvim-lspconfig.lua`、`lsp_server_manager_mason.lua`、`lsp_server_manager_mason-lspconfig.lua` 配置。若你之后改了插件或键位，只需对照修改“键位”和“添加/关闭服务器”两节即可。
