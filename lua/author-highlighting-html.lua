-- author-highlighting-html-debug.lua
-- Highlights "Levin" name variations in HTML output
-- Debug version with extensive logging

-- Configuration: Exact patterns that include "Levin"
local levin_patterns = {
  "Levin MG",
  "Levin M",
  "Levin",
  "Levin MG,",
  "Levin MG.",
  "Levin M,",
  "Levin M.",
  "MG Levin",
  "M Levin",
  "Levin, MG",
  "Levin, M",
}

-- Create lookup table for exact matches
local levin_lookup = {}
for _, pattern in ipairs(levin_patterns) do
  levin_lookup[pattern] = true
end

io.stderr:write("DEBUG [author-highlighting]: Filter loaded\n")

-- Track context - set when we see "Levin" to help identify related initials
local levin_context = false
local context_distance = 0
local entries_processed = 0
local levin_found = 0

-- Function to check if text should be highlighted
local function should_highlight(text)
  -- Always highlight exact Levin patterns
  if levin_lookup[text] then
    levin_context = true
    context_distance = 0
    return true
  end

  -- Pattern matching for Levin variations
  if text:find("Levin") then
    levin_context = true
    context_distance = 0
    if text:match("^Levin,?%s+M?G?[%.,]?$") or
       text:match("^M?G?%s+Levin[%.,]?$") or
       text:match("^Levin[%.,]?$") then
      return true
    end
  end

  -- Highlight standalone initials ONLY if we recently saw "Levin"
  if levin_context and context_distance <= 3 then
    if text == "MG" or text == "MG," or text == "MG." or
       text == "M" or text == "M," or text == "M." then
      return true
    end
  end

  return false
end

-- Function to update context
local function update_context()
  if levin_context then
    context_distance = context_distance + 1
    if context_distance > 5 then
      levin_context = false
      context_distance = 0
    end
  end
end

-- Walk through inline elements and highlight Levin names
local function highlight_levin_in_inlines(inlines)
  local new_inlines = {}

  for i, elem in ipairs(inlines) do
    if elem.t == "Str" then
      local text = elem.text

      if should_highlight(text) then
        levin_found = levin_found + 1
        io.stderr:write("DEBUG [author-highlighting]: Found Levin variant: '" .. text .. "'\n")
        table.insert(new_inlines, pandoc.Strong({pandoc.Str(text)}))
      else
        table.insert(new_inlines, elem)
      end

      update_context()
    else
      table.insert(new_inlines, elem)
    end
  end

  return new_inlines
end

-- Process bibliography divs
function Div(div)
  -- Check if this is a bibliography div
  if div.identifier and (div.identifier:match("^refs") or div.classes:includes("references")) then
    io.stderr:write("DEBUG [author-highlighting]: Processing bibliography div: " .. div.identifier .. "\n")

    -- Walk through all content
    for i, block in ipairs(div.content) do
      entries_processed = entries_processed + 1

      -- Reset context for each bibliography entry
      levin_context = false
      context_distance = 0

      if block.t == "Div" and block.classes:includes("csl-entry") then
        io.stderr:write("DEBUG [author-highlighting]: Processing entry " .. entries_processed .. "\n")

        -- Walk through the entry content
        block.content = pandoc.walk_block(block, {
          Para = function(para)
            para.content = highlight_levin_in_inlines(para.content)
            return para
          end,
          Plain = function(plain)
            plain.content = highlight_levin_in_inlines(plain.content)
            return plain
          end
        }).content
      end
    end

    io.stderr:write("DEBUG [author-highlighting]: Processed " .. entries_processed .. " entries, found " .. levin_found .. " Levin instances\n")
    return div
  end

  return nil
end

return {
  {Div = Div}
}
