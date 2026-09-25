/*
 * 目录生成：
 * 1. 给正文里的 h2 / h3 / h4 分配稳定 id（sec-1、sec-2 ……）
 * 2. 用它们拼出右侧目录，并加一个可点击的锚点
 * 3. 滚动时高亮当前小节
 *
 * 之所以在浏览器里生成，是因为 kramdown 对中文标题生成的 id 会退化成 "1-"
 * 甚至空字符串，锚点会互相冲突。
 */
(function () {
  'use strict';

  /*
   * 取标题文本。
   * 标题里可能含公式：MathJax 会就地把公式渲染出来，同时把原文留在一个隐藏的
   * 预览节点里，直接读 textContent 会把同一个公式读两遍（如 "X(f,i)X(f,i)"）。
   * 所以先克隆一份、剔掉隐藏副本与脚本，再取文本；若 MathJax 还没渲染完，
   * 此时拿到的是原始 "$$X(f,i)$$"，去掉 $ 同样是 "X(f,i)"。
   */
  function headingText(heading) {
    var clone = heading.cloneNode(true);
    // script 是 MathJax 留的原文；MathJax_Preview 是渲染前的占位副本；
    // MJX_Assistive_MathML / mjx-assistive-mml 是给读屏软件用的隐藏副本（v2 / v3）。
    var junk = clone.querySelectorAll(
      'script, .MathJax_Preview, .MJX_Assistive_MathML, .mjx-assistive-mml, .header-anchor'
    );
    Array.prototype.forEach.call(junk, function (node) {
      if (node.parentNode) {
        node.parentNode.removeChild(node);
      }
    });
    return clone.textContent.replace(/\$/g, '').replace(/\s+/g, ' ').trim();
  }

  function buildToc() {
    var body = document.querySelector('.post-body');
    var list = document.getElementById('toc-list');
    if (!body || !list) {
      return;
    }

    var headings = body.querySelectorAll('h2, h3, h4');
    if (!headings.length) {
      var empty = document.getElementById('toc-empty');
      if (empty) { empty.hidden = false; }
      // 书籍侧栏里的标题是书名，空了也不能藏；只有文章目录才藏
      var toc = document.getElementById('toc');
      if (toc && toc.hasAttribute('data-hide-title-when-empty')) {
        var title = document.getElementById('toc-title');
        if (title) { title.hidden = true; }
      }
      return;
    }

    var links = [];
    Array.prototype.forEach.call(headings, function (heading, i) {
      var id = 'sec-' + (i + 1);
      var text = headingText(heading);
      heading.id = id;

      var anchor = document.createElement('a');
      anchor.className = 'heading-anchor';
      anchor.href = '#' + id;
      anchor.setAttribute('aria-label', '本节锚点');
      anchor.textContent = '#';
      heading.appendChild(anchor);

      var item = document.createElement('li');
      item.className = 'lvl-' + ({ H2: 1, H3: 2, H4: 3 })[heading.tagName];

      var link = document.createElement('a');
      link.href = '#' + id;
      link.textContent = text;
      item.appendChild(link);
      list.appendChild(item);
      links.push(link);
    });

    highlightOnScroll(headings, links);
  }

  function highlightOnScroll(headings, links) {
    if (!('IntersectionObserver' in window)) {
      return;
    }
    var active = -1;
    function setActive(index) {
      if (index === active) {
        return;
      }
      if (active >= 0 && links[active]) {
        links[active].classList.remove('is-active');
      }
      active = index;
      if (active >= 0 && links[active]) {
        links[active].classList.add('is-active');
      }
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var index = Array.prototype.indexOf.call(headings, entry.target);
        if (entry.isIntersecting) {
          setActive(index);
        }
      });
    }, { rootMargin: '-10% 0px -70% 0px', threshold: 0 });

    Array.prototype.forEach.call(headings, function (heading) {
      observer.observe(heading);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', buildToc);
  } else {
    buildToc();
  }
})();
