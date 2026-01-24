-- filters/gh_pdf_conditionals.lua
-- Purpose:
--   - Strip "GitHub-only" sections from Pandoc output (so they don't appear in PDF)
--   - Extract "PDF-only" sections (hidden in HTML comments) and inject them as LaTeX
--
-- Markup in README.md:
--   <!-- BEGIN: GitHub-only ... --> ... <!-- END: GitHub-only ... -->
--   <!-- BEGIN: PDF-only ... --> ... <!-- END: PDF-only ... -->

local mode = nil         -- nil | "github_only" | "pdf_only"
local pdf_buffer = {}

local function is_begin(el_text, label)
  return el_text:match("BEGIN:%s*" .. label) ~= nil
end

local function is_end(el_text, label)
  return el_text:match("END:%s*" .. label) ~= nil
end

local function flush_pdf_buffer_as_latex()
  if #pdf_buffer == 0 then
    return {}
  end
  local latex = table.concat(pdf_buffer, "\n")
  pdf_buffer = {}
  return pandoc.RawBlock("latex", latex)
end

-- We’ll drop any block-level content while inside GitHub-only or PDF-only regions.
-- For PDF-only regions, we collect raw HTML comment content lines and emit them as LaTeX on END.
local function handle_block(el)
  -- Detect our BEGIN/END markers (they arrive as RawBlock("html", "...") via Pandoc)
  if el.t == "RawBlock" and el.format == "html" then
    local t = el.text

    -- BEGIN markers
    if is_begin(t, "GitHub%-only") then
      mode = "github_only"
      return {} -- remove marker
    end
    if is_begin(t, "PDF%-only") then
      mode = "pdf_only"
      pdf_buffer = {}
      return {} -- remove marker
    end

    -- END markers
    if is_end(t, "GitHub%-only") then
      mode = nil
      return {} -- remove marker
    end
    if is_end(t, "PDF%-only") then
      mode = nil
      return flush_pdf_buffer_as_latex() -- replace region with LaTeX
    end

    -- If we're inside PDF-only, treat *every* HTML RawBlock as a line of LaTeX to inject.
    if mode == "pdf_only" then
      table.insert(pdf_buffer, t)
      return {}
    end

    -- Otherwise leave HTML RawBlock alone (rare in GitHub README, but safe)
    return nil
  end

  -- While inside either region:
  -- - GitHub-only: drop everything
  -- - PDF-only: drop everything (we only inject what we captured from html RawBlocks)
  if mode == "github_only" or mode == "pdf_only" then
    return {}
  end

  return nil
end

-- Apply to common block types
function RawBlock(el) return handle_block(el) end
function Para(el) return handle_block(el) end
function Plain(el) return handle_block(el) end
function Header(el) return handle_block(el) end
function BulletList(el) return handle_block(el) end
function OrderedList(el) return handle_block(el) end
function BlockQuote(el) return handle_block(el) end
function HorizontalRule(el) return handle_block(el) end
function CodeBlock(el) return handle_block(el) end
function Div(el) return handle_block(el) end
function Table(el) return handle_block(el) end
