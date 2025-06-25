-- 横線の長さをそろえる
function HorizontalRule()
  return pandoc.RawBlock("latex", "\\noindent\\rule{1.0\\linewidth}{0.4pt}")
end

-- CodeBlock の表示スタイル
function CodeBlock(block)
  if FORMAT == "latex" then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[mycode]
]] .. block.text .. [[
\end{tcolorbox}
]])
  else
    return block
  end
end

--デバッグ関数
function debugHeader(el)
  print(string.format("----- DEBUG: Header (level=%d) が検出されました -----", el.level))
  for i, inl in ipairs(el.content) do
    print(string.format("  inl[%d].t = %s", i, inl.t))

    -- 画像なら src と alt を表示
    if inl.t == "Image" then
      local alt = pandoc.utils.stringify(inl.caption)
      local src = inl.src or "N/A"
      print("    ├─ src:", src)
      print("    └─ alt:", alt)

    -- 文字列 (Str) ならテキストを表示
    elseif inl.t == "Str" then
      print("    └─ text = " .. inl.text)

    -- その他、調べたい型があれば同様に表示
    end
  end
  print("----- DEBUG END (Header)-----")
end

function debugInlines(el)
  print("----- DEBUG: Para/Plainブロックが検出されました -----")
  for i, inl in ipairs(el.content) do
    print(string.format("  inl[%d].t = %s", i, inl.t))

    -- 画像なら src と alt を表示
    if inl.t == "Image" then
      local alt = pandoc.utils.stringify(inl.caption)
      local src = inl.src or "N/A"
      print("    ├─ src:", src)
      print("    └─ alt:", alt)

    -- 文字列 (Str) ならテキストを表示
    elseif inl.t == "Str" then
      print("    └─ text = " .. inl.text)

    -- その他、調べたい型があれば同様に表示
    end
  end
  print("----- DEBUG END (Para/Plain)-----")
end

function debugPlain(el)
  print("----- DEBUG: Plainブロックが検出されました -----")
  for i, inl in ipairs(el.content) do
    print(string.format("  inl[%d].t = %s", i, inl.t))

    -- 画像なら src と alt を表示
    if inl.t == "Image" then
      local alt = pandoc.utils.stringify(inl.caption)
      local src = inl.src or "N/A"
      print("    ├─ src:", src)
      print("    └─ alt:", alt)

    -- 文字列 (Str) ならテキストを表示
    elseif inl.t == "Str" then
      print("    └─ text = " .. inl.text)

    -- その他、調べたい型があれば同様に表示
    end
  end
  print("----- DEBUG END (Plain)-----")
end


-- 最大横並び数
local max_per_row = 5

-- 枚数に応じた画像幅（LaTeX用）
local width_tbl = {
  [1] = "0.50\\linewidth",
  [2] = "0.48\\linewidth",
  [3] = "0.31\\linewidth",
  [4] = "0.23\\linewidth",
  [5] = "0.18\\linewidth"
}

-- 1枚のときの高さ制限
local height1 = "0.5\\textheight"

function image_changer(el)
    -- 画像だけで構成された段落かチェック
  for i, inl in ipairs(el.content) do
    if inl.t  ~= 'Image' and inl.t ~= 'Space' and inl.t ~= 'SoftBreak' then
        print(string.format("  Image_inl[%d].t = %s", i, inl.t))
        return nil
    end
  end


--   -- 画像だけで構成された段落かチェック
--   for i, inl in ipairs(el.content) do
--     if inl.t == 'Image' then
--       -- ALTテキストを取得して文字列に変換
--       local alt = pandoc.utils.stringify(inl.caption)
--       -- ALTテキストがある場合は偽とみなす
--       if alt ~= "" then
--           print(string.format("  Image_inl[%d].t = %s", i, inl.t))
--         return nil
--       end
--     elseif inl.t ~= 'Space' and inl.t ~= 'SoftBreak' then
--         print(string.format("  Space_inl[%d].t = %s", i, inl.t))
--       return nil
--     end
--   end

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

    local tex = { "\\begin{figure}[H]" }

    for _, im in ipairs(group) do
      local src = im.src or im.target or im.c[2][1]
      local alt = im.caption or im.content or im.c[1][1]

      alt = pandoc.utils.stringify(alt)

      if group_size == 1 then
        if total == 1 then
          -- 全体が1枚だけ → 大きく表示（高さあり）
          tex[#tex+1] = string.format(
            "\\centering\n\\includegraphics[width=\\dimexpr%s\\relax,height=%s,keepaspectratio]{%s}\n\\caption{%s}",
            width_tbl[1], height1, src, alt)
        else
          -- 折り返しの1枚 → 5枚分のサイズで揃える
          tex[#tex+1] = string.format(
            "\\begin{minipage}[c]{0.5\\hsize}\n\\centering\n\\includegraphics[width=\\dimexpr%s\\relax]{%s}\n\\caption{%s}\n\\end{minipage}",
            width_tbl[max_per_row], src, alt)
        end
        else
          -- 2〜5枚 → 枚数に応じたサイズ
          tex[#tex+1] = string.format(
            "\\begin{minipage}[c]{0.5\\hsize}\n\\centering\n\\includegraphics[width=\\dimexpr%s\\relax]{%s}\n\\caption{%s}\n\\end{minipage}",
            width_tbl[group_size], src, alt)
        end
    end

    tex[#tex+1] = "\\end{figure}"
    table.insert(blocks, pandoc.RawBlock("latex", table.concat(tex, "\n")))

    i = i + group_size
  end
  return blocks
end

-- ヘッダブロックをデバッグ表示
function Header(el)
    debugHeader(el)
    return image_changer(el)
end


function Para(el)
    debugInlines(el)
    return image_changer(el)
end

-- Plain(改行のみの段落扱い)ブロックも確認したい場合
function Plain(el)
    debugPlain(el)
    return image_changer(el)
end

