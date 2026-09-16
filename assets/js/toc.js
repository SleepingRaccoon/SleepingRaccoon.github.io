/*
 * 目录生成：
 * 1. 给正文里的 h2 / h3 分配稳定 id（sec-1、sec-2 ……）
 * 2. 用它们拼出右侧目录，并加一个可点击的锚点
 * 3. 滚动时高亮当前小节
 *
 * 之所以在浏览器里生成，是因为 kramdown 对中文标题生成的 id 会退化成 "1-"
 * 甚至空字符串，锚点会互相冲突。
 */
(function () {
  'use strict';

  function buildToc() {
    var body = document.querySelector('.post-body');
    var list = document.getElementById('toc-list');
    if (!body || !list) {
      return;
    }

    var headings = body.querySelectorAll('h2, h3');
    if (!headings.length) {
      var empty = document.getElementById('toc-empty');
      var title = document.getElementById('toc-title');
      if (empty) { empty.hidden = false; }
      if (title) { title.hidden = true; }
      return;
    }

    var links = [];
    Array.prototype.forEach.call(headings, function (heading, i) {
      var id = 'sec-' + (i + 1);
      var text = heading.textContent.trim();
      heading.id = id;

      var anchor = document.createElement('a');
      anchor.className = 'heading-anchor';
      anchor.href = '#' + id;
      anchor.setAttribute('aria-label', '本节锚点');
      anchor.textContent = '#';
      heading.appendChild(anchor);

      var item = document.createElement('li');
      item.className = heading.tagName === 'H3' ? 'lvl-2' : 'lvl-1';

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
