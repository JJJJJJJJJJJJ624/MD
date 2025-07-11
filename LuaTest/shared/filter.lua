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

-- --デバッグ関数
-- function debugHeader(el)
--   print(string.format("----- DEBUG: Header (level=%d) が検出されました -----", el.level))
--   for i, inl in ipairs(el.content) do
--     print(string.format("  inl[%d].t = %s", i, inl.t))
--
--     -- 画像なら src と alt を表示
--     if inl.t == "Image" then
--       local alt = pandoc.utils.stringify(inl.caption)
--       local src = inl.src or "N/A"
--       print("    ├─ src:", src)
--       print("    └─ alt:", alt)
--
--     -- 文字列 (Str) ならテキストを表示
--     elseif inl.t == "Str" then
--       print("    └─ text = " .. inl.text)
--
--     -- その他、調べたい型があれば同様に表示
--     end
--   end
--   print("----- DEBUG END (Header)-----")
-- end
--
-- function debugInlines(el)
--   print("----- DEBUG: Para/Plainブロックが検出されました -----")
--   for i, inl in ipairs(el.content) do
--     print(string.format("  inl[%d].t = %s", i, inl.t))
--
--     -- 画像なら src と alt を表示
--     if inl.t == "Image" then
--       local alt = pandoc.utils.stringify(inl.caption)
--       local src = inl.src or "N/A"
--       print("    ├─ src:", src)
--       print("    └─ alt:", alt)
--
--     -- 文字列 (Str) ならテキストを表示
--     elseif inl.t == "Str" then
--       print("    └─ text = " .. inl.text)
--
--     -- その他、調べたい型があれば同様に表示
--     end
--   end
--   print("----- DEBUG END (Para/Plain)-----")
-- end
--
-- function debugPlain(el)
--   print("----- DEBUG: Plainブロックが検出されました -----")
--   for i, inl in ipairs(el.content) do
--     print(string.format("  inl[%d].t = %s", i, inl.t))
--
--     -- 画像なら src と alt を表示
--     if inl.t == "Image" then
--       local alt = pandoc.utils.stringify(inl.caption)
--       local src = inl.src or "N/A"
--       print("    ├─ src:", src)
--       print("    └─ alt:", alt)
--
--     -- 文字列 (Str) ならテキストを表示
--     elseif inl.t == "Str" then
--       print("    └─ text = " .. inl.text)
--
--     -- その他、調べたい型があれば同様に表示
--     end
--   end
--   print("----- DEBUG END (Plain)-----")
-- end
--
--
-- -- 最大横並び数
-- local max_per_row = 5
--
-- -- 枚数に応じた画像幅（LaTeX用）
-- local width_tbl = {
--   [1] = "0.50\\linewidth",
--   [2] = "0.48\\linewidth",
--   [3] = "0.31\\linewidth",
--   [4] = "0.23\\linewidth",
--   [5] = "0.18\\linewidth"
-- }
--
-- -- 1枚のときの高さ制限
-- local height1 = "0.5\\textheight"
--
-- function image_changer(el)
--     -- 画像だけで構成された段落かチェック
--   for i, inl in ipairs(el.content) do
--     if inl.t  ~= 'Image' and inl.t ~= 'Space' and inl.t ~= 'SoftBreak' then
--         print(string.format("  Image_inl[%d].t = %s", i, inl.t))
--         return nil
--     end
--   end
--
--
-- --   -- 画像だけで構成された段落かチェック
-- --   for i, inl in ipairs(el.content) do
-- --     if inl.t == 'Image' then
-- --       -- ALTテキストを取得して文字列に変換
-- --       local alt = pandoc.utils.stringify(inl.caption)
-- --       -- ALTテキストがある場合は偽とみなす
-- --       if alt ~= "" then
-- --           print(string.format("  Image_inl[%d].t = %s", i, inl.t))
-- --         return nil
-- --       end
-- --     elseif inl.t ~= 'Space' and inl.t ~= 'SoftBreak' then
-- --         print(string.format("  Space_inl[%d].t = %s", i, inl.t))
-- --       return nil
-- --     end
-- --   end
--
--   -- 画像抽出
--   local images = {}
--   for _, inl in ipairs(el.content) do
--     if inl.t == 'Image' then
--       table.insert(images, inl)
--     end
--   end
--
--   local blocks = {}
--   local i = 1
--   local total = #images
--
--   while i <= total do
--     local remaining = total - i + 1
--     local group_size = math.min(remaining, max_per_row)
--     local group = {}
--     for j = i, i + group_size - 1 do
--       table.insert(group, images[j])
--     end
--
--     local tex = { "\\begin{figure}[H]" }
--
--     for _, im in ipairs(group) do
--       local src = im.src or im.target or im.c[2][1]
--       local alt = im.caption or im.content or im.c[1][1]
--
--       alt = pandoc.utils.stringify(alt)
--
--       if group_size == 1 then
--         if total == 1 then
--           -- 全体が1枚だけ → 大きく表示（高さあり）
--           tex[#tex+1] = string.format(
--             "\\centering\n\\includegraphics[width=\\dimexpr%s\\relax,height=%s,keepaspectratio]{%s}\n\\caption{%s}",
--             width_tbl[1], height1, src, alt)
--         else
--           -- 折り返しの1枚 → 5枚分のサイズで揃える
--           tex[#tex+1] = string.format(
--             "\\begin{minipage}[b]{%s}\n\\centering\n\\includegraphics[width=\\dimexpr1.00\\linewidth\\relax]{%s}\n\\caption{%s}\n\\end{minipage}",
--             width_tbl[max_per_row], src, alt)
--         end
--         else
--           -- 2〜5枚 → 枚数に応じたサイズ
--           tex[#tex+1] = string.format(
--             "\\begin{minipage}[b]{%s}\n\\centering\n\\includegraphics[width=\\dimexpr1.00\\linewidth\\relax]{%s}\n\\caption{%s}\n\\end{minipage}",
--             width_tbl[max_per_row], src, alt)
--         end
--     end
--
--     tex[#tex+1] = "\\end{figure}"
--     table.insert(blocks, pandoc.RawBlock("latex", table.concat(tex, "\n")))
--
--     i = i + group_size
--   end
--   return blocks
-- end

-- -- ヘッダブロックをデバッグ表示
-- function Header(el)
--     debugHeader(el)
--     return image_changer(el)
-- end
--
-- function Para(el)
--     debugInlines(el)
--     return image_changer(el)
-- end
--
-- -- Plain(改行のみの段落扱い)ブロックも確認したい場合
-- function Plain(el)
--     debugPlain(el)
--     return image_changer(el)
-- end


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--[[
LaTeX 変換用 Pandoc Lua フィルタ
 - 段落内で画像が複数連続 -> まとめて figure 環境にする
 - 上限は5枚まで、それを超える場合は改めて別の figure 環境に分割
 - 1枚だけの場合は height=... で高さ制限
 - 2～5枚の場合は width_tbl を参考に minipage 横並び
]]

-- １つの figure に入れる画像の最大枚数
local max_per_figure = 3

-- 画像枚数に応じた幅設定 (2～5 枚)
local width_tbl = {
  [1] = "0.50\\textwidth",
  [2] = "0.48\\textwidth",
  [3] = "0.31\\textwidth",
  [4] = "0.23\\textwidth",
  [5] = "0.18\\textwidth"
}

-- 画像を LaTeX コードへ変換
-- count は「今回まとめる枚数」
local function make_image_latex(src, caption, count)
    local cap = pandoc.utils.stringify(caption)
  if count == 1 then
    -- 1枚だけ: height=… で高さ制限
    return string.format([[\begin{figure}[H]
    \centering
    \includegraphics[keepaspectratio, height=0.3\textheight]{%s}
    \caption{%s}
\end{figure}]], src, cap)
  else
    -- 2枚以上: 指定した幅で minipage を使う
    local width = width_tbl[count] or width_tbl[5] -- 5枚以上は強制的に5と同じ幅
    return string.format([[\begin{minipage}[b]{%s}
    \centering
    \includegraphics[keepaspectratio, width=\textwidth]{%s}
    \caption{%s}
\end{minipage}]], width, src, cap)
  end
end

-- chunk_size 枚ごとに figure ブロックを作る
local function create_figure_blocks(images, chunk_size)
  local blocks = {}
  local chunk = {}

  local function flush_chunk()
    if #chunk == 1 then
      -- 1枚だけのとき
      local im = chunk[1]
      local latex_str = make_image_latex(im.src, im.caption, 1)
      table.insert(blocks, pandoc.RawBlock("latex", latex_str))
--       table.insert(blocks, latex_str)
    elseif #chunk > 1 then
      -- 2枚以上のとき
      local lines = {"\\begin{figure}[H]", "\\centering"}
      local count = #chunk
      for _, img in ipairs(chunk) do
        table.insert(lines, make_image_latex(img.src, img.caption, count))
      end
      table.insert(lines, "\\end{figure}")
      table.insert(blocks, pandoc.RawBlock("latex", table.concat(lines, "\n")))
--       table.insert(blocks, table.concat(lines, "\n"))
    end
    chunk = {}
  end

  for _, inl in ipairs(images) do
    table.insert(chunk, inl)
    if #chunk == chunk_size then
      flush_chunk()
    end
  end
  -- 残りの画像があれば吐き出す
  if #chunk > 0 then
    flush_chunk()
  end
  return blocks
end







--[[
LaTeX 変換用 Pandoc Lua フィルタ
 - 段落内で画像が複数連続 -> まとめて figure 環境にする
 - 上限は5枚まで、それを超える場合は改めて別の figure 環境に分割
 - 1枚だけの場合は height=... で高さ制限
 - 2～5枚の場合は width_tbl を参考に minipage 横並び
]]

-- １つの figure に入れる画像の最大枚数
local max_per_figure = 3

-- 画像枚数に応じた幅設定 (2～5 枚)
local width_tbl = {
  [1] = "0.50\\textwidth",
  [2] = "0.48\\textwidth",
  [3] = "0.31\\textwidth",
  [4] = "0.23\\textwidth",
  [5] = "0.18\\textwidth"
}

-- 画像を LaTeX コードへ変換
-- count は「今回まとめる枚数」
local function make_image_latex(src, caption, count)
    local cap = pandoc.utils.stringify(caption)
  if count == 1 then
    -- 1枚だけ: height=… で高さ制限
    return string.format([[\begin{figure}[H]
    \centering
    \includegraphics[keepaspectratio, height=0.3\textheight]{%s}
    \caption{%s}
\end{figure}]], src, cap)
  else
    -- 2枚以上: 指定した幅で minipage を使う
    local width = width_tbl[count] or width_tbl[5] -- 5枚以上は強制的に5と同じ幅
    return string.format([[\begin{minipage}[b]{%s}
    \centering
    \includegraphics[keepaspectratio, width=\textwidth]{%s}
    \caption{%s}
\end{minipage}]], width, src, cap)
  end
end

-- chunk_size 枚ごとに figure ブロックを作る
local function create_figure_blocks(images, chunk_size)
  local blocks = {}
  local chunk = {}

  local function flush_chunk()
    if #chunk == 1 then
      -- 1枚だけのとき
      local im = chunk[1]
      local latex_str = make_image_latex(im.src, im.caption, 1)
      table.insert(blocks, pandoc.RawBlock("latex", latex_str))
--       table.insert(blocks, latex_str)
    elseif #chunk > 1 then
      -- 2枚以上のとき
      local lines = {"\\begin{figure}[H]", "\\centering"}
      local count = #chunk
      for _, img in ipairs(chunk) do
        table.insert(lines, make_image_latex(img.src, img.caption, count))
      end
      table.insert(lines, "\\end{figure}")
      table.insert(blocks, pandoc.RawBlock("latex", table.concat(lines, "\n")))
--       table.insert(blocks, table.concat(lines, "\n"))
    end
    chunk = {}
  end

  for _, inl in ipairs(images) do
    table.insert(chunk, inl)
    if #chunk == chunk_size then
      flush_chunk()
    end
  end
  -- 残りの画像があれば吐き出す
  if #chunk > 0 then
    flush_chunk()
  end
  return blocks
end

local function transform_images_in_inlines(inlines)
  -- latex 以外のときは変換しない
  if not FORMAT:match("latex") then
    return inlines
  end

  local newInlines = {}
  local imageBuffer = {}

  local function flush_images()
    if #imageBuffer > 0 then
      local figs = create_figure_blocks(imageBuffer, max_per_figure)
      for _, f in ipairs(figs) do
        -- figure ブロックを 1 つずつインライン要素として挿入
        table.insert(newInlines, f)
      end
      imageBuffer = {}
    end
  end

  for _, inl in ipairs(inlines) do
    if inl.t == "Image" then
      table.insert(imageBuffer, inl)
    else
      -- テキストが来たら、一旦画像ブロックを吐き出してからそのまま挿入
      flush_images()
      table.insert(newInlines, inl)
    end
  end
  -- 最終的に残った画像をまとめて出力
  if newInlines[#newInlines] ~= pandoc.SoftBreak() and newInlines[#newInlines] ~= pandoc.LineBreak() and newInlines[#newInlines] ~= nil and #imageBuffer > 0 then
      table.insert(newInlines, pandoc.SoftBreak())
  end
  flush_images()

  return newInlines
end

local function sprit_Block_Inline(mixInline, fun)
    local Inlines = {}
    local return_var = {}

    for _, inl in ipairs(mixInline) do
        if pandoc.utils.type(inl) == 'Block' then
            table.insert(return_var, fun(Inlines))
            Inlines = {}
            table.insert(return_var, inl)
        else
            table.insert(Inlines, inl)
        end
    end

    table.insert(return_var, fun(Inlines))

    return return_var
end

local function transform_images_in_block(el)
  if not FORMAT:match("latex") then
    return nil
  end

  local replacedInlines = transform_images_in_inlines(el.content)

  print("#####\n")
  print(dump(replacedInlines))
  print("#####\n")

  if el.t == "Para" then
    return sprit_Block_Inline(replacedInlines, pandoc.Para)
  elseif el.t == "Plain" then
    return sprit_Block_Inline(replacedInlines, pandoc.Plain)
  elseif el.t == "Header" then
    return pandoc.Header(el.level, replacedInlines, el.attr)
  end
  return nil
end

function Header(el)
  return transform_images_in_block(el)
end

function Para(el)
  return transform_images_in_block(el)
end

function Plain(el)
  return transform_images_in_block(el)
end

-- codeblock-to-lstlisting.lua
function CodeBlock(el)
  return pandoc.RawBlock("latex", "\\begin{tcolorbox}[mycode]\n\\begin{lstlisting}\n" .. el.text .. "\n\\end{lstlisting}\n\\end{tcolorbox}")
end


-- 丸数字 → 通常数字へのマッピング（①〜⑳）
-- 丸数字のマッピング表
local maru_map = {
  ["①"] = "1", ["②"] = "2", ["③"] = "3", ["④"] = "4", ["⑤"] = "5",
  ["⑥"] = "6", ["⑦"] = "7", ["⑧"] = "8", ["⑨"] = "9", ["⑩"] = "10",
  ["⑪"] = "11", ["⑫"] = "12", ["⑬"] = "13", ["⑭"] = "14", ["⑮"] = "15",
  ["⑯"] = "16", ["⑰"] = "17", ["⑱"] = "18", ["⑲"] = "19", ["⑳"] = "20"
}

-- 置換処理：LaTeX用に丸数字を置き換える
function replace_maru(text)
  for k, v in pairs(maru_map) do
      print(text)
    text = text:gsub(k, "\\maru{" .. v .. "}")
  end
  return text
end

-- -- Para（段落）と Plain（箇条書き等）を対象に処理
-- function Para(el)
--   local raw = pandoc.utils.stringify(el)
--   local replaced = replace_maru(raw)
--   if replaced ~= raw then
--     return transform_images_in_block(pandoc.RawInline("latex", replaced))
--   end
-- end
--
-- function Plain(el)
--   local raw = pandoc.utils.stringify(el)
--   local replaced = replace_maru(raw)
--   if replaced ~= raw then
--     return transform_images_in_block(pandoc.RawInline("latex", replaced))
--   end
-- end