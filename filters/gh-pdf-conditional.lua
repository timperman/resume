-- filters/gh_pdf_conditionals.lua
-- Handles:
--  - GitHub-only blocks (removed)
--  - PDF-only blocks embedded inside a single multiline HTML comment
--
-- Markup:
-- <!-- BEGIN: PDF-only name
--   ...latex...
-- END: PDF-only name -->

local function extract_pdf_only(text)
  local body = text:match("BEGIN:%s*PDF%-only.-\n(.-)\nEND:%s*PDF%-only")
  if body then
    return pandoc.RawBlock("latex", body)
  end
end

function RawBlock(el)
  if el.format ~= "html" then
    return nil
  end

  -- Drop GitHub-only blocks entirely
  if el.text:match("BEGIN:%s*GitHub%-only") then
    return {}
  end

  -- Extract PDF-only blocks and inject as LaTeX
  local latex = extract_pdf_only(el.text)
  if latex then
    return latex
  end

  return nil
end

function Para(_) return nil end
function Plain(_) return nil end
