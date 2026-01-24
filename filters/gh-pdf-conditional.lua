-- filters/gh_pdf_conditionals.lua

local mode = nil
local pdf_buffer = {}

local function is_begin(text, label)
  return text:match("BEGIN:%s*" .. label)
end

local function is_end(text, label)
  return text:match("END:%s*" .. label)
end

function RawBlock(el)
  if el.format == "html" then
    -- BEGIN blocks
    if is_begin(el.text, "GitHub%-only") then
      mode = "github"
      return {}
    end
    if is_begin(el.text, "PDF%-only") then
      mode = "pdf"
      pdf_buffer = {}
      return {}
    end

    -- END blocks
    if is_end(el.text, "GitHub%-only") then
      mode = nil
      return {}
    end
    if is_end(el.text, "PDF%-only") then
      mode = nil
      local latex = table.concat(pdf_buffer, "\n")
      return pandoc.RawBlock("latex", latex)
    end

    -- Collect PDF-only content
    if mode == "pdf" then
      table.insert(pdf_buffer, el.text)
      return {}
    end
  end

  return nil
end

-- Drop all content inside GitHub-only or PDF-only blocks
function Para(_)       if mode then return {} end end
function Plain(_)      if mode then return {} end end
function BulletList(_) if mode then return {} end end
function OrderedList(_)if mode then return {} end end
function Header(_)     if mode then return {} end end
function Div(_)        if mode then return {} end end
