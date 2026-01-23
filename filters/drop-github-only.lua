-- Removes content between HTML comments:
-- <!-- BEGIN: GitHub-only ... --> ... <!-- END: GitHub-only ... -->
local in_block = false

function RawBlock(el)
  if el.format == "html" then
    if el.text:match("BEGIN:%s*GitHub%-only") then
      in_block = true
      return {}
    end
    if el.text:match("END:%s*GitHub%-only") then
      in_block = false
      return {}
    end
  end
  return nil
end

function Para(el)
  if in_block then return {} end
  return nil
end

function Plain(el)
  if in_block then return {} end
  return nil
end
