-- filters/gh_pdf_conditionals.lua
-- Supports:
-- 1) GitHub-only blocks with separate BEGIN/END HTML comments (stateful; drops enclosed content)
-- 2) PDF-only blocks embedded inside a SINGLE multiline HTML comment (extracts and injects LaTeX)
-- 3) PDF-only blocks with separate BEGIN/END comments (optional; stateful collect/inject)

local mode = nil          -- nil | "github" | "pdf"
local pdf_buffer = {}

local function has_begin(text, label) return text:match("BEGIN:%s*" .. label) end
local function has_end(text, label)   return text:match("END:%s*" .. label) end

local function extract_multiline_pdf_only(text)
  -- Match content between BEGIN: PDF-only ... newline ... newline END: PDF-only
  local body = text:match("BEGIN:%s*PDF%-only.-\n(.-)\nEND:%s*PDF%-only")
  if body and #body > 0 then
    return pandoc.RawBlock("latex", body)
  end
end

local function drop_if_inside()
  if mode == "github" or mode == "pdf" then
    return {}
  end
  return nil
end

function RawBlock(el)
  if el.format ~= "html" then
    return nil
  end

  -- 1) PDF-only multiline comment: BEGIN and END in the same RawBlock
  local injected = extract_multiline_pdf_only(el.text)
  if injected then
    return injected
  end

  -- 2) GitHub-only stateful markers (BEGIN/END are separate comments)
  if has_begin(el.text, "GitHub%-only") then
    mode = "github"
    return {}
  end
  if has_end(el.text, "GitHub%-only") then
    mode = nil
    return {}
  end

  -- 3) PDF-only stateful markers (if you ever use split comments)
  if has_begin(el.text, "PDF%-only") then
    mode = "pdf"
    pdf_buffer = {}
    return {}
  end
  if has_end(el.text, "PDF%-only") then
    mode = nil
    local latex = table.concat(pdf_buffer, "\n")
    pdf_buffer = {}
    return pandoc.RawBlock("latex", latex)
  end

  -- While collecting split PDF-only, accumulate html raw text lines
  if mode == "pdf" then
    table.insert(pdf_buffer, el.text)
    return {}
  end

  -- Otherwise, keep unrelated HTML raw blocks (rare)
  return nil
end

-- Drop all block content while inside GitHub-only or split PDF-only sections
function Para(_)       return drop_if_inside() end
function Plain(_)      return drop_if_inside() end
function Header(_)     return drop_if_inside() end
function BulletList(_) return drop_if_inside() end
function OrderedList(_)return drop_if_inside() end
function Div(_)        return drop_if_inside() end
function BlockQuote(_) return drop_if_inside() end
function Table(_)      return drop_if_inside() end
function CodeBlock(_)  return drop_if_inside() end
