# SleepingRaccoon.github.io

个人技术博客，用 Jekyll + Markdown 写，由 GitHub Pages 自动构建。

## 目录结构

```
.
├── _config.yml          # 站点配置（标题、permalink、collections、kramdown 等）
├── _data/books.yml      # 首页两个模块（书）的标题、简介、链接
├── _layouts/
│   ├── default.html     # 页面外壳：头部导航、页脚、MathJax、目录脚本
│   ├── post.html        # 文章模板：标题、日期、标签、右侧目录
│   ├── book.html        # 模块首页模板（一本书的目录页）
│   ├── doc.html         # 模块内文档模板：左侧是整本书的篇目树
│   └── page.html        # 单页模板（如「关于」）
├── _posts/              # 所有文章，文件名必须是 YYYY-MM-DD-英文短名.md
├── _radar/              # 模块《雷达信号处理入门》的文档
├── _cuda/               # 模块《CUDA 在雷达信号处理中的应用》的文档
├── radar/index.html     # 模块首页 /radar/
├── cuda/index.html      # 模块首页 /cuda/
├── assets/
│   ├── css/site.css     # 全部样式
│   └── js/toc.js        # 生成目录（h2/h3/h4）+ 滚动高亮
├── index.html           # 首页：模块卡片 + 文章列表
├── about.md             # 关于页
└── 404.html             # 404 页
```

## 模块（两本书）

首页上半部分是两个模块，各自相当于一本独立的书，互不依赖，各自有目录、篇目和章节层级：

| 模块 | 网址 | 文档目录 |
| :--- | :--- | :--- |
| 雷达信号处理入门 | `/radar/` | `_radar/` |
| CUDA 在雷达信号处理中的应用 | `/cuda/` | `_cuda/` |

**新增一篇**：在对应目录下放一个 `.md`，导航和目录页会自动收录，`layout` 不用写：

```yaml
---
title: 中频采样
order: 2                # 篇目顺序，小的在前
description: 一句话摘要，显示在模块目录页。
---
```

正文用 `##` / `###` / `####` 写多级标题，侧栏会自动把**整本书的篇目**和**当前篇的章节**
拼成一棵树，层级对应当前篇的标题层级。

**新增一个模块**（第三本书）：在 `_config.yml` 的 `collections` 里加一项、
在 `_data/books.yml` 里加一条、再建一个 `_新key/` 目录和 `<url>/index.html`（三行 front matter）即可。

## 写一篇新文章

1. 在 `_posts/` 下新建文件，文件名格式 `YYYY-MM-DD-英文短名.md`
   （日期决定发布时间，短名会成为网址 `/posts/英文短名/`）。
2. 开头写 front matter：

   ```yaml
   ---
   title: "文章标题"
   date: 2026-09-16 10:00:00 +0800
   categories: 雷达
   tags: [雷达, 信号处理]
   description: 一句话摘要，会显示在首页列表里。
   ---
   ```

   `layout` 不用写，`_config.yml` 里的 defaults 会自动套用文章模板。
3. 正文用 Markdown，`##` / `###` 标题会被 `assets/js/toc.js` 自动收集成右侧目录，
   所以**不要再手写目录**，也不要重复写一级标题（`#`），文章标题由模板渲染。

## 公式与代码

- 行内公式：`$$f_{IF}$$`
- 独立公式（`$$` 单独占一行）：

  ```
  $$
  s_{IF}(t) = A\cos(2\pi f_{IF} t)
  $$
  ```

- kramdown 只把 `$$...$$` 当作数学，构建时会转成 MathJax 认识的 `\(...\)` / `\[...\]`，
  由 `_layouts/default.html` 里的 MathJax 渲染（加载自 cdnjs）。
- 注意：单个 `$` 在 kramdown 里是**普通文本**，写 `$f_c$` 不会变成公式；
  也不要直接写 `\( ... \)`、`\[ ... \]`，kramdown 会把 `\[` 转义成普通方括号。
- 代码块用三个反引号并标注语言，Rouge 会做语法高亮。

## 本地预览（可选）

没有 Ruby 环境也能直接写：提交后 GitHub Pages 会构建。想本地预览可以装 Ruby 后：

```bash
gem install github-pages
bundle exec jekyll serve   # 或者 jekyll serve
```

或者用官方镜像：

```bash
docker run --rm -v "$PWD":/srv/jekyll -p 4000:4000 -it jekyll/jekyll jekyll serve
```

## 部署

仓库 Settings → Pages → Source 选择 **Deploy from a branch**，
分支选 `main`、目录选 `/ (root)`。之后每次 push 到 `main`，
GitHub Pages 会自动用 Jekyll 构建并发布到 <https://sleepingraccoon.github.io>。
