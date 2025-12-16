-- bibliography-processor.lua
-- Manually runs citeproc, then adds year headers and author highlighting
-- Leverages the fact that citeproc already sorts entries by year

io.stderr:write("\n=== BIBLIOGRAPHY PROCESSOR ===\n")

-- Levin name patterns for exact matches
local levin_patterns = {
  "Levin MG", "Levin M", "Levin", "Levin MG,", "Levin MG.",
  "Levin M,", "Levin M.", "MG Levin", "M Levin", "Levin, MG", "Levin, M"
}

local levin_lookup = {}
for _, pattern in ipairs(levin_patterns) do
  levin_lookup[pattern] = true
end

-- Context tracking for multi-element highlighting
local levin_context = false
local context_distance = 0

-- Run citeproc on a document
local function citeproc(doc)
  io.stderr:write("Running citeproc...\n")
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  else
    local args = {'--from=json', '--to=json', '--citeproc'}
    local result = pandoc.utils.run_json_filter(doc, 'pandoc', args)
    return result or pandoc.Pandoc({})
  end
end

-- Extract year from entry - multiple patterns for maximum flexibility
local function extract_year(blocks)
  local text = pandoc.utils.stringify(blocks)

  -- Try multiple patterns in order of specificity
  local patterns = {
    -- Traditional formats with volume/issue
    "%.%s*(%d%d%d%d);",           -- . 2025;14(23)
    "%.%s*(%d%d%d%d):",           -- . 2025:347

    -- Online-first / no volume formats
    "%.%s*(%d%d%d%d)%.:e",        -- . 2025.:e038921 (article ID)
    "%.%s*(%d%d%d%d)%.%s+doi:",   -- . 2025. doi:
    "%.%s*(%d%d%d%d)%.%s+http",   -- . 2025. http (URL follows)

    -- General formats
    "%.%s*(%d%d%d%d)%.",          -- . 2025.
    ",?%s*(%d%d%d%d)%.",          -- , 2025. or 2025.
    "%((%d%d%d%d)%)",             -- (2025)

    -- Fallback: any 4-digit number that could be a year
    -- This will match standalone years in various contexts
    "[^%d](%d%d%d%d)[^%d]",       -- Any 4 digits not adjacent to other digits
  }

  for _, pattern in ipairs(patterns) do
    local year = text:match(pattern)
    if year then
      local y = tonumber(year)
      -- Sanity check: year should be reasonable
      if y >= 1900 and y <= 2100 then
        io.stderr:write("  Extracted year " .. y .. " using pattern: " .. pattern .. "\n")
        return y
      end
    end
  end

  -- If no pattern matched, log the text for debugging
  io.stderr:write("  WARNING: Could not extract year from: " .. text:sub(1, 100) .. "...\n")
  return nil
end

-- Check if text should be highlighted
local function should_highlight(text)
  -- Exact match
  if levin_lookup[text] then
    levin_context = true
    context_distance = 0
    return true
  end

  -- Pattern matching for Levin
  if text:find("Levin") then
    levin_context = true
    context_distance = 0
    if text:match("^Levin,?%s+M?G?[%.,]?$") or
       text:match("^M?G?%s+Levin[%.,]?$") or
       text:match("^Levin[%.,]?$") then
      return true
    end
  end

  -- Highlight standalone initials if we recently saw "Levin"
  if levin_context and context_distance <= 3 then
    if text == "MG" or text == "MG," or text == "MG." or
       text == "M" or text == "M," or text == "M." then
      return true
    end
  end

  return false
end

-- Update context distance
local function update_context()
  if levin_context then
    context_distance = context_distance + 1
    if context_distance > 5 then
      levin_context = false
      context_distance = 0
    end
  end
end

-- Reset context (for new entries)
local function reset_context()
  levin_context = false
  context_distance = 0
end

-- Highlight Levin with context tracking
local function highlight_with_context(elem)
  if elem.t == "Str" then
    local highlight = should_highlight(elem.text)
    update_context()

    if highlight then
      return pandoc.Strong({pandoc.Str(elem.text)})
    end
  end
  return elem
end

-- Get the #refs div
local function get_refs_div(doc)
  local refs_div = nil
  doc:walk({
    Div = function(div)
      if div.identifier == "refs" then
        refs_div = div
      end
    end
  })
  return refs_div
end

-- Main processing function
function Pandoc(doc)
  io.stderr:write("\nProcessing document...\n")

  -- Run citeproc to generate bibliography
  doc = citeproc(doc)

  -- Find the #refs div
  local refs_div = get_refs_div(doc)

  if not refs_div then
    io.stderr:write("WARNING: No #refs div found after citeproc\n")
    return doc
  end

  io.stderr:write("Found #refs div with " .. #refs_div.content .. " blocks\n")

  -- Process entries sequentially, adding year headers when year changes
  local new_content = {}
  local current_year = nil
  local entry_count = 0
  local total_highlighted = 0
  local year_count = 0
  local entries_without_year = 0

  for _, block in ipairs(refs_div.content) do
    if block.t == "Div" and block.classes:includes("csl-entry") then
      entry_count = entry_count + 1
      reset_context()  -- Reset context for each entry

      -- Extract year from this entry
      local year = extract_year(block.content)

      if not year then
        entries_without_year = entries_without_year + 1
      end

      -- If year changed, add a header
      if year and year ~= current_year then
        io.stderr:write("  Adding year header: " .. year .. "\n")
        table.insert(new_content, pandoc.Header(3, {pandoc.Str(tostring(year))}))
        current_year = year
        year_count = year_count + 1
      end

      -- Highlight Levin and style authorship notes - walk through content with context tracking
      local entry_highlights = 0
      block.content = block.content:walk({
        Str = function(elem)
          local result = highlight_with_context(elem)
          if result.t == "Strong" then
            entry_highlights = entry_highlights + 1
          end
          return result
        end,
        -- Wrap authorship notes in a span for styling
        Emph = function(elem)
          local text = pandoc.utils.stringify(elem)
          -- Check if this is an authorship note
          if text:match("Authorship Note:") then
            return pandoc.Span(elem.content, {class = "authorship-note"})
          end
          return elem
        end,
        -- Reset context at paragraph boundaries
        Para = function(para)
          reset_context()
          return nil  -- continue walking
        end
      })

      total_highlighted = total_highlighted + entry_highlights

      -- Add the entry
      table.insert(new_content, block)
    end
  end

  io.stderr:write("Processed " .. entry_count .. " entries\n")
  io.stderr:write("Added " .. year_count .. " year headers\n")
  io.stderr:write("Highlighted " .. total_highlighted .. " author instances\n")

  if entries_without_year > 0 then
    io.stderr:write("WARNING: " .. entries_without_year .. " entries without detectable year\n")
  end

  -- Update the refs div in the document
  doc = doc:walk({
    Div = function(div)
      if div.identifier == "refs" then
        div.content = new_content
        return div
      end
    end
  })

  io.stderr:write("Bibliography processing complete!\n\n")

  return doc
end

return {{Pandoc = Pandoc}}
