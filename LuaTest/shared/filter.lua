-- 横線の長さをそろえる
function HorizontalRule()
  return pandoc.RawBlock("latex", "\\noindent\\rule{1.0\\linewidth}{0.4pt}")
end

-- 最大横並び数
local max_per_row = 5

-- 枚数に応じた画像幅（LaTeX用）
local width_tbl = {
  [1] = "0.60\\linewidth",
  [2] = "0.48\\linewidth",
  [3] = "0.31\\linewidth",
  [4] = "0.23\\linewidth",
  [5] = "0.18\\linewidth"
}

-- 1枚のときの高さ制限
local height1 = "0.8\\textheight"

function Para(el)
  -- 画像だけで構成された段落かチェック
  for _, inl in ipairs(el.content) do
    if inl.t ~= 'Image' and inl.t ~= 'Space' and inl.t ~= 'SoftBreak' then
      return nil  -- 他の要素が混じっていたら無視
    end
  end

  -- 画像抽出
  local images = {}
  for _, inl in ipairs(el.content) do
    if inl.t == 'Image' then
      table.insert(images, inl)
    end
  end

  local blocks = {}
  local i = 1
  local total = #images

  while i <= total do
    local remaining = total - i + 1
    local group_size = math.min(remaining, max_per_row)
    local group = {}
    for j = i, i + group_size - 1 do
      table.insert(group, images[j])
    end

    local tex = { "\\begin{center}" }

    for _, im in ipairs(group) do
      local src = im.src or im.target or im.c[2][1]

      if group_size == 1 then
        if total == 1 then
          -- 全体が1枚だけ → 大きく表示（高さあり）
          tex[#tex+1] = string.format(
            "\\includegraphics[width=\\dimexpr%s\\relax,height=%s,keepaspectratio]{%s}",
            width_tbl[1], height1, src)
        else
          -- 折り返しの1枚 → 5枚分のサイズで揃える
          tex[#tex+1] = string.format(
            "\\includegraphics[width=\\dimexpr%s\\relax]{%s}",
            width_tbl[max_per_row], src)
        end
      else
        -- 2〜5枚 → 枚数に応じたサイズ
        tex[#tex+1] = string.format(
          "\\includegraphics[width=\\dimexpr%s\\relax]{%s}",
          width_tbl[group_size], src)
      end
    end

    tex[#tex+1] = "\\end{center}"
    table.insert(blocks, pandoc.RawBlock("latex", table.concat(tex, "\n")))

    i = i + group_size
  end

  return blocks
end
