-- year-separation-debug.lua
-- Adds year headers to bibliography entries
-- Debug version with extensive logging

io.stderr:write("DEBUG [year-separation]: Filter loaded\n")

-- Extract year from a bibliography entry
local function extract_year_from_entry(blocks)
  local text = pandoc.utils.stringify(blocks)

  -- Try multiple patterns to extract year
  -- Pattern 1: (2024) - year in parentheses
  local year = text:match("%((%d%d%d%d)%)")
  if year then
    return tonumber(year)
  end

  -- Pattern 2: 2024; or 2024. - year followed by punctuation
  year = text:match("(%d%d%d%d)[;%.,]")
  if year then
    return tonumber(year)
  end

  -- Pattern 3: 2024 followed by a space
  year = text:match("(%d%d%d%d)%s")
  if year then
    return tonumber(year)
  end

  return nil
end

-- Process bibliography divs and add year headers
function Div(div)
  -- Check if this is a bibliography div
  if div.identifier and (div.identifier:match("^refs") or div.classes:includes("references")) then
    io.stderr:write("DEBUG [year-separation]: Processing bibliography div: " .. div.identifier .. "\n")
    io.stderr:write("DEBUG [year-separation]: Div has " .. #div.content .. " blocks\n")

    local new_content = {}
    local current_year = nil
    local entries_by_year = {}

    -- First pass: group entries by year
    for i, block in ipairs(div.content) do
      if block.t == "Div" and block.classes:includes("csl-entry") then
        local year = extract_year_from_entry(block.content)

        io.stderr:write("DEBUG [year-separation]: Entry " .. i .. " - extracted year: " .. (year or "nil") .. "\n")

        if year then
          if not entries_by_year[year] then
            entries_by_year[year] = {}
          end
          table.insert(entries_by_year[year], block)
        else
          -- If we can't extract year, add to "unknown" group
          if not entries_by_year[0] then
            entries_by_year[0] = {}
          end
          table.insert(entries_by_year[0], block)
        end
      else
        -- Not a csl-entry, might be other content - keep it
        table.insert(new_content, block)
      end
    end

    -- Get sorted list of years (descending)
    local years = {}
    for year, _ in pairs(entries_by_year) do
      if year > 0 then  -- Skip unknown year group for now
        table.insert(years, year)
      end
    end
    table.sort(years, function(a, b) return a > b end)

    io.stderr:write("DEBUG [year-separation]: Found " .. #years .. " distinct years\n")

    -- Second pass: add year headers and entries
    for _, year in ipairs(years) do
      io.stderr:write("DEBUG [year-separation]: Adding header for year " .. year .. " with " .. #entries_by_year[year] .. " entries\n")

      -- Add year header
      local year_header = pandoc.Header(3, {pandoc.Str(tostring(year))})
      table.insert(new_content, year_header)

      -- Add entries for this year
      for _, entry in ipairs(entries_by_year[year]) do
        table.insert(new_content, entry)
      end
    end

    -- Add unknown year entries at the end if any
    if entries_by_year[0] and #entries_by_year[0] > 0 then
      io.stderr:write("DEBUG [year-separation]: Adding " .. #entries_by_year[0] .. " entries with unknown year\n")
      local unknown_header = pandoc.Header(3, {pandoc.Str("Year Unknown")})
      table.insert(new_content, unknown_header)

      for _, entry in ipairs(entries_by_year[0]) do
        table.insert(new_content, entry)
      end
    end

    -- Replace div content
    div.content = new_content
    io.stderr:write("DEBUG [year-separation]: New content has " .. #new_content .. " blocks\n")

    return div
  end

  return nil
end

return {
  {Div = Div}
}
