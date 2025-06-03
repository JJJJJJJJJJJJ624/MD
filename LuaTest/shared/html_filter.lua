-- 画像のみの段落(Para)を検出して、HTML出力時は<div>＋<figure>構造へ変換。
-- altテキストが空でも <figcaption> は常に出力する。

function Para(el)
  -- 画像だけで構成されているか確認
  local images = {}
  for _, inl in ipairs(el.content) do
    if inl.t == "Image" then
      table.insert(images, inl)
    elseif inl.t ~= "Space" and inl.t ~= "SoftBreak" then
      return nil  -- 他の要素が混じっていたら変換対象外
    end
  end

  -- 画像がなければ何もしない
  if #images == 0 then
    return nil
  end

  -- 出力先がHTML以外のときはスルー（LaTeX等の処理用には別途実装可能）
  if not FORMAT:match("html") then
    return nil
  end

  -- figure 要素群を <div class="image-group"> にまとめる
  local figureBlocks = {}
  for _, img in ipairs(images) do
    local altText = pandoc.utils.stringify(img.caption)  -- altテキスト（キャプション）
    -- 空の altText でも figcaption を必ず出力
    local figureHtml = string.format([[
<figure>
  <img src="%s" alt="%s" />
  <figcaption>%s</figcaption>
</figure>]], img.src, altText, altText)

    table.insert(figureBlocks, pandoc.RawBlock("html", figureHtml))
  end

  return pandoc.Div(figureBlocks, {class = "image-group"})
end