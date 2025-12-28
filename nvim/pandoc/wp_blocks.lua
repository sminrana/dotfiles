-- Pandoc Lua filter to wrap HTML output in Gutenberg block comments
-- Maps common elements to WordPress blocks for better editor fidelity

local function wrap_block(name, attrs, inner)
  local prefix = "<!-- wp:" .. name
  if attrs and attrs ~= "" then
    prefix = prefix .. " " .. attrs
  end
  prefix = prefix .. " -->\n"
  local suffix = "\n<!-- /wp:" .. name .. " -->\n"
  return pandoc.RawBlock("html", prefix .. inner .. suffix)
end

function Header(el)
  local level = el.level
  local attr = string.format('{"level":%d}', level)
  local html = pandoc.write(pandoc.Pandoc({ pandoc.Para({ pandoc.Str("") }) }), 'html') -- dummy to get writer
  local htag = string.format("h%d", level)
  local inner = pandoc.write(pandoc.Pandoc({ pandoc.Header(level, el.content, el.attr) }), 'html')
  -- inner already includes <hN>...</hN>
  return wrap_block("heading", attr, inner)
end

function Para(el)
  local inner = pandoc.write(pandoc.Pandoc({ pandoc.Para(el.content) }), 'html')
  return wrap_block("paragraph", nil, inner)
end

function BlockQuote(el)
  local inner = pandoc.write(pandoc.Pandoc({ pandoc.BlockQuote(el.content) }), 'html')
  return wrap_block("quote", nil, inner)
end

function CodeBlock(el)
  local lang = nil
  -- language may be in el.classes (first class typically)
  if el.classes and #el.classes > 0 then
    lang = el.classes[1]
  end
  local pre_classes = { 'wp-block-code' }
  local code_class = ''
  local lang_attr = ''
  if lang then
    table.insert(pre_classes, 'line-numbers')
    table.insert(pre_classes, 'language-' .. lang)
    code_class = ' class="language-' .. lang .. '"'
    lang_attr = ' lang="' .. lang .. '"'
  end
  local pre_class_str = table.concat(pre_classes, ' ')
  local html = string.format('<pre class="%s" tabindex="0"><code%s%s>%s</code></pre>', pre_class_str, code_class, lang_attr, pandoc.text.escape(el.text))
  return wrap_block("code", nil, html)
end

local function list_items_to_html(items)
  local html_items = {}
  for _, item in ipairs(items) do
    local inner = pandoc.write(pandoc.Pandoc(item), 'html')
    table.insert(html_items, '<li><!-- wp:list-item -->' .. inner .. '<!-- /wp:list-item --></li>')
  end
  return table.concat(html_items, "\n")
end

function BulletList(items)
  local inner = '<ul>\n' .. list_items_to_html(items) .. '\n</ul>'
  return wrap_block("list", '{"ordered":false}', inner)
end

function OrderedList(items)
  local inner = '<ol>\n' .. list_items_to_html(items) .. '\n</ol>'
  return wrap_block("list", '{"ordered":true}', inner)
end

function Image(el)
  local alt = pandoc.utils.stringify(el.caption)
  local src = el.src or (el.target or "")
  local html = string.format('<figure><img src="%s" alt="%s"/></figure>', src, alt)
  return wrap_block("image", nil, html)
end

function Figure(el)
  local inner = pandoc.write(pandoc.Pandoc(el.content), 'html')
  inner = '<figure>' .. inner .. '</figure>'
  return wrap_block("image", nil, inner)
end

-- Fallback: leave other blocks as-is
function RawBlock(el)
  return el
end

function Div(el)
  return el
end

-- Tables
local function render_table(tbl)
  local html = {}
  table.insert(html, '<figure class="wp-block-table"><table>')
  -- Header
  if tbl.headers and #tbl.headers > 0 then
    table.insert(html, '<thead><tr>')
    for _, h in ipairs(tbl.headers) do
      local cell = pandoc.write(pandoc.Pandoc({ pandoc.Para(h) }), 'html')
      cell = cell:gsub('^<p>', ''):gsub('</p>$', '')
      table.insert(html, '<th>' .. cell .. '</th>')
    end
    table.insert(html, '</tr></thead>')
  end
  -- Body
  if tbl.rows and #tbl.rows > 0 then
    table.insert(html, '<tbody>')
    for _, row in ipairs(tbl.rows) do
      table.insert(html, '<tr>')
      for _, c in ipairs(row) do
        local cell = pandoc.write(pandoc.Pandoc({ pandoc.Para(c) }), 'html')
        cell = cell:gsub('^<p>', ''):gsub('</p>$', '')
        table.insert(html, '<td>' .. cell .. '</td>')
      end
      table.insert(html, '</tr>')
    end
    table.insert(html, '</tbody>')
  end
  table.insert(html, '</table></figure>')
  return table.concat(html, '')
end

function Table(el)
  -- Pandoc 2.10+ table AST can be complex; use built html writer
  local html = pandoc.write(pandoc.Pandoc({ el }), 'html')
  -- Wrap result in wp-block-table figure if not already
  if not html:match('wp%-block%-table') then
    html = html:gsub('^<table>', '<figure class="wp-block-table"><table>')
    html = html:gsub('</table>$', '</table></figure>')
  end
  return wrap_block('table', nil, html)
end
