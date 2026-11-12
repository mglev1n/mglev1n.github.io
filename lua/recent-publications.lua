-- first-senior-author-filter.lua
-- Filters bibliography to show only publications where Levin is first or senior author
-- Runs citeproc first with all citations, then filters the #refs div
-- Each entry that is kept is then laid out in three lines (title, authors, venue)

io.stderr:write("\n=== FIRST/SENIOR AUTHOR FILTER ===\n")

-- lua/publication-entry.lua corrects the references before citeproc runs, builds
-- the three-line entry, and emphasises Levin's name. Both filters load it from the
-- folder this file is in, much as source() does in R.
local pub = dofile(pandoc.path.join({pandoc.path.directory(PANDOC_SCRIPT_FILE), "publication-entry.lua"}))

local n_recent = 5  -- default

-- Run citeproc on a document
local function run_citeproc(doc)
  doc = pub.prepare_references(doc)  -- preprints, institution names
  io.stderr:write("Running citeproc...\n")
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  else
    local args = {'--from=json', '--to=json', '--citeproc'}
    local result = pandoc.utils.run_json_filter(doc, 'pandoc', args)
    return result or pandoc.Pandoc({})
  end
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

-- Extract year from a formatted citation entry - multiple patterns for maximum flexibility
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
        return y
      end
    end
  end

  return nil
end

-- Does the authorship note say that Levin shares first or senior authorship?
-- The note must use sharing language (equal contribution, joint supervision) and
-- must itself name Levin, by initials (MGL, ML) or by surname. %f[%a] and %f[%A]
-- mark the start and end of a word, so "ML" does not match inside "MLK" and "Levin"
-- does not match "Levine".
local function shares_first_or_senior(note)
  if not note then
    return false
  end
  local sharing = note:match("[Cc]ontributed equally") or
                  note:match("[Ee]qual contribution") or
                  note:match("[Cc]o%-first") or
                  note:match("[Cc]o%-senior") or
                  note:match("[Jj]ointly supervis") or
                  note:match("[Cc]o%-supervis") or
                  note:match("[Jj]ointly directed")
  if not sharing then
    return false
  end
  local names_levin = note:match("%f[%a]MGL%f[%A]") or
                      note:match("%f[%a]ML%f[%A]") or
                      note:match("%f[%a]Levin%f[%A]")
  return names_levin ~= nil
end

-- Decide whether an entry belongs on the home page: Levin is the first author, the
-- last author, or shares one of those roles according to the authorship note.
-- The author names come from the entry's markers (lua/publication-entry.lua), one
-- whole name at a time, and each is compared with Levin's name exactly. An entry
-- without markers cannot be judged and is left out.
local function qualifies_for_inclusion(entry_div)
  local names, note = pub.authors_and_note(entry_div)
  if not names or #names == 0 then
    return false, false, false, false
  end

  local first = pub.is_levin(names[1])
  local senior = pub.is_levin(names[#names])
  local equal = shares_first_or_senior(note)

  return first or senior or equal, first, senior, equal
end

-- Main processing function
function Pandoc(doc)
  io.stderr:write("\nProcessing document...\n")

  -- Get n_recent from metadata if available
  if doc.meta.params and doc.meta.params.n_recent then
    n_recent = tonumber(pandoc.utils.stringify(doc.meta.params.n_recent)) or 5
  end
  io.stderr:write("n_recent = " .. n_recent .. "\n")

  -- Run citeproc to generate bibliography
  doc = run_citeproc(doc)

  -- Find the #refs div
  local refs_div = get_refs_div(doc)

  if not refs_div then
    io.stderr:write("WARNING: No #refs div found after citeproc\n")
    return doc
  end

  io.stderr:write("Found #refs div with " .. #refs_div.content .. " blocks\n")
  io.stderr:write("DEBUG: refs_div.identifier = " .. (refs_div.identifier or "nil") .. "\n")
  io.stderr:write("DEBUG: refs_div classes = " .. table.concat(refs_div.classes, ", ") .. "\n")

  -- Filter entries for first/senior author and collect with years
  local qualifying_entries = {}

  for _, block in ipairs(refs_div.content) do
    if block.t == "Div" and block.classes:includes("csl-entry") then
      -- The citation style puts marker characters in each entry (see
      -- lua/publication-entry.lua). The authorship check uses them to read the author
      -- names. The year is read from the entry's text, so it gets a copy without the
      -- markers, which reads as one plain citation:
      -- "12. Authors. Title. Journal. Year;Vol:Pages. doi:10.1/xyz. Authorship Note: ..."
      local plain = pub.without_markers(block)
      local qualifies, is_first, is_senior, is_equal = qualifies_for_inclusion(block)

      if qualifies then
        local year = extract_year(plain.content)
        table.insert(qualifying_entries, {
          block = block,
          plain = plain,
          position = #qualifying_entries + 1,  -- place in the bibliography, which is newest first
          year = year or 0,
          is_first = is_first,
          is_senior = is_senior,
          is_equal = is_equal
        })

        local preview = pandoc.utils.stringify(plain.content):sub(1, 80)
        io.stderr:write("  INCLUDED: " .. preview .. "... (year=" .. (year or "unknown") ..
                       ", first=" .. tostring(is_first) .. ", senior=" .. tostring(is_senior) ..
                       ", equal=" .. tostring(is_equal) .. ")\n")
      else
        local preview = pandoc.utils.stringify(plain.content):sub(1, 60)
        io.stderr:write("  EXCLUDED: " .. preview .. "...\n")
      end
    end
  end

  io.stderr:write("\nTotal qualifying entries: " .. #qualifying_entries .. "\n")

  -- Sort by year (descending)
  -- Within a year, keep the bibliography's own order (newest first). Lua's sort does
  -- not keep the order of entries that compare equal, so the position breaks the tie;
  -- without it the choice among papers from the same year was arbitrary.
  table.sort(qualifying_entries, function(a, b)
    if a.year ~= b.year then
      return a.year > b.year
    end
    return a.position < b.position
  end)

  -- Take only N most recent
  local keep_count = math.min(n_recent, #qualifying_entries)
  local new_content = {}

  local one_paragraph_count = 0

  for i = 1, keep_count do
    -- Lay the entry out in three lines: title, authors, venue. The home page shows
    -- neither the citation number nor the authorship note. (The entry has already
    -- been selected, so the equal-contribution check above has read the note.)
    local entry, done = pub.format(qualifying_entries[i].block, {show_number = false, show_note = false})
    if not done.three_lines then one_paragraph_count = one_paragraph_count + 1 end

    table.insert(new_content, entry)
    local preview = pandoc.utils.stringify(qualifying_entries[i].plain.content):sub(1, 60)
    io.stderr:write("  KEEPING #" .. i .. ": " .. preview .. "... (year=" .. qualifying_entries[i].year .. ")\n")
  end

  io.stderr:write("\n=== Filtered to " .. keep_count .. " first/senior author publications ===\n")
  if one_paragraph_count > 0 then
    io.stderr:write("WARNING: " .. one_paragraph_count .. " entries have no part markers and are shown " ..
                    "as one paragraph. Is the csl file templates/american-medical-association-no-et-al-v2.csl?\n")
  end

  -- Replace the refs div by rebuilding doc.blocks (recursive to handle nesting)
  local refs_found = 0
  local function replace_refs(blocks)
    local result = {}
    for _, block in ipairs(blocks) do
      if block.t == "Div" and block.identifier == "refs" then
        refs_found = refs_found + 1
        io.stderr:write("DEBUG: Found refs div in block replacement (count=" .. refs_found .. ")\n")
        io.stderr:write("DEBUG: Replacing refs div with " .. #new_content .. " entries\n")
        -- Create a new div with filtered content
        local filtered_div = pandoc.Div(new_content, {id = "refs-index", class = "references csl-bib-body hanging-indent"})
        table.insert(result, filtered_div)
      elseif block.t == "Div" and block.content then
        -- Recursively process nested divs
        block.content = replace_refs(block.content)
        table.insert(result, block)
      else
        table.insert(result, block)
      end
    end
    return result
  end

  doc.blocks = replace_refs(doc.blocks)

  io.stderr:write("DEBUG: Total refs divs found and replaced: " .. refs_found .. "\n")
  io.stderr:write("DEBUG: doc.blocks now has " .. #doc.blocks .. " blocks\n")

  return doc
end

return {{Pandoc = Pandoc}}
