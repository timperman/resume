-- filters/gh_pdf_conditionals.lua
-- 1) Remove blocks between:
--    <!-- BEGIN: GitHub-only ... -->   and   <!-- END: GitHub-only ... -->
-- 2) Extract LaTeX from multiline comment blocks:
--    <!-- BEGIN: PDF-only ...
--       ...latex...
--       END: PDF-only ... -->

local function extract_pdf_only_from_multiline_comment(text)
  -- Captures everything between the BEGIN line and the END line inside a single HTML comment RawBlock.
  -- Your README uses: <!-- BEGIN: PDF-only ... <newline> ... <newline> END: PDF-only ... -->
  local body = text:match("BEGIN:%s*PDF%-only.-\n(.-)\nEND:%s*PDF%-only")
  if body and #body > 0 then
    return pandoc.RawBlock("latex", body)
  end
  return nil
end

function Pandoc(doc)
  local out = {}
  local dropping_github_only = false

  for _, b in ipairs(doc.blocks) do
    if b.t == "RawBlock" and b.format == "html" then
      local t = b.text

      -- PDF-only multiline comment: inject LaTeX into output
      local injected = extract_pdf_only_from_multiline_comment(t)
      if injected then
        table.insert(out, injected)
        goto continue
      end

      -- GitHub-only begin/end markers (these are separate HTML comment lines in your README)
      if t:match("BEGIN:%s*GitHub%-only") then
        dropping_github_only = true
        goto continue
      end
      if t:match("END:%s*GitHub%-only") then
        dropping_github_only = false
        goto continue
      end

      -- Any other raw HTML: keep it (rare)
      if not dropping_github_only then
        table.insert(out, b)
      end
      goto continue
    end

    -- Drop everything while inside GitHub-only region
    if not dropping_github_only then
      table.insert(out, b)
    end

    ::continue::
  end

  doc.blocks = out
  return doc
end
