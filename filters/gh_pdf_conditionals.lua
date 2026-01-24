-- filters/gh_pdf_conditionals.lua
-- - Drops content between GitHub-only markers
-- - Injects LaTeX from multiline PDF-only HTML comments
-- - Works whether HTML comments appear as RawBlock OR RawInline

local dropping = false

local function extract_pdf_only(text)
  local body = text:match("BEGIN:%s*PDF%-only.-\n(.-)\nEND:%s*PDF%-only")
  if body and #body > 0 then
    return pandoc.RawBlock("latex", body)
  end
end

local function is_begin_github(text)
  return text:match("BEGIN:%s*GitHub%-only") ~= nil
end

local function is_end_github(text)
  return text:match("END:%s*GitHub%-only") ~= nil
end

local function process_inlines(inlines)
  local out = {}
  for _, il in ipairs(inlines) do
    if il.t == "RawInline" and il.format == "html" then
      local t = il.text
      if is_begin_github(t) then dropping = true end
      if is_end_github(t) then dropping = false end
      -- Always remove the marker inline itself
    else
      if not dropping then
        table.insert(out, il)
      end
    end
  end
  return out
end

function Pandoc(doc)
  local out = {}
  dropping = false

  for _, b in ipairs(doc.blocks) do
    -- Handle HTML comments as block-level raw HTML
    if b.t == "RawBlock" and b.format == "html" then
      local injected = extract_pdf_only(b.text)
      if injected then
        table.insert(out, injected)
        goto continue
      end

      if is_begin_github(b.text) then dropping = true; goto continue end
      if is_end_github(b.text) then dropping = false; goto continue end

      -- Other raw HTML: keep only if not dropping
      if not dropping then table.insert(out, b) end
      goto continue
    end

    -- While dropping, still scan for END markers that may appear inline
    if b.t == "Para" then
      b.content = process_inlines(b.content)
      if not dropping and #b.content > 0 then table.insert(out, b) end
      goto continue
    end

    if b.t == "Plain" then
      b.content = process_inlines(b.content)
      if not dropping and #b.content > 0 then table.insert(out, b) end
      goto continue
    end

    -- Any other block: keep only if not dropping
    if not dropping then
      table.insert(out, b)
    end

    ::continue::
  end

  doc.blocks = out
  return doc
end