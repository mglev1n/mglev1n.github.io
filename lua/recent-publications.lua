-- recent-publications.lua
-- Sets nocite metadata to only include N most recent publications
-- Runs BEFORE citeproc to limit which citations get processed

local n_recent = 5  -- default

-- Parse a BibTeX file and extract entries with years
local function parse_bibtex_file(filepath)
  local entries = {}
  local file = io.open(filepath, "r")

  if not file then
    io.stderr:write("WARNING: Could not open bibliography file: " .. filepath .. "\n")
    return entries
  end

  local current_key = nil
  local current_year = nil
  local in_entry = false

  for line in file:lines() do
    -- Match entry start: @article{key, or @book{key,
    local key = line:match("^%s*@%w+%s*{%s*([^,]+)")
    if key then
      -- Save previous entry if we have one
      if current_key and current_year then
        table.insert(entries, {key = current_key, year = current_year})
      end
      -- Start new entry
      current_key = key
      current_year = nil
      in_entry = true
    end

    -- Match year field: year = {2024} or year = 2024,
    if in_entry and not current_year then
      local year = line:match("year%s*=%s*{?(%d%d%d%d)}?,?")
      if year then
        current_year = tonumber(year)
      end
    end

    -- Detect end of entry (closing brace at start of line)
    if line:match("^}") then
      if current_key and current_year then
        table.insert(entries, {key = current_key, year = current_year})
      end
      in_entry = false
      current_key = nil
      current_year = nil
    end
  end

  -- Don't forget last entry if file doesn't end with }
  if current_key and current_year then
    table.insert(entries, {key = current_key, year = current_year})
  end

  file:close()

  io.stderr:write("DEBUG: Parsed " .. #entries .. " entries from " .. filepath .. "\n")
  return entries
end

-- Main filter function
function Meta(meta)
  -- Get n_recent parameter
  if meta.params and meta.params.n_recent then
    n_recent = tonumber(pandoc.utils.stringify(meta.params.n_recent)) or 5
  end

  io.stderr:write("DEBUG: n_recent = " .. n_recent .. "\n")

  -- Get bibliography file path
  local bib_file = nil
  if meta.bibliography then
    if meta.bibliography.t == "MetaInlines" then
      bib_file = pandoc.utils.stringify(meta.bibliography)
    elseif meta.bibliography.t == "MetaString" then
      bib_file = meta.bibliography
    elseif type(meta.bibliography) == "string" then
      bib_file = meta.bibliography
    end
  end

  if not bib_file then
    io.stderr:write("WARNING: No bibliography file found in metadata\n")
    return meta
  end

  io.stderr:write("DEBUG: Bibliography file = " .. bib_file .. "\n")

  -- Parse the bib file
  local entries = parse_bibtex_file(bib_file)

  if #entries == 0 then
    io.stderr:write("WARNING: No entries found in bibliography file\n")
    return meta
  end

  -- Sort entries by year (descending)
  table.sort(entries, function(a, b)
    return a.year > b.year
  end)

  -- Take only the N most recent
  local recent_keys = {}
  local keep_count = math.min(n_recent, #entries)

  for i = 1, keep_count do
    table.insert(recent_keys, "@" .. entries[i].key)
    io.stderr:write("DEBUG: Keeping entry " .. i .. ": " .. entries[i].key .. " (" .. entries[i].year .. ")\n")
  end

  -- Set nocite to only include recent entries
  if #recent_keys > 0 then
    local nocite_str = table.concat(recent_keys, "; ")
    meta.nocite = pandoc.MetaInlines(pandoc.read(nocite_str).blocks[1].content)
    io.stderr:write("DEBUG: Set nocite to: " .. nocite_str .. "\n")
  end

  return meta
end

return {{Meta = Meta}}
