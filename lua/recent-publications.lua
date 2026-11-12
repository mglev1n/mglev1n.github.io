-- first-senior-author-filter.lua
-- Filters bibliography to show only publications where Levin is first or senior author
-- Runs citeproc first with all citations, then filters the #refs div
-- Each entry that is kept is then laid out in three lines (title, authors, venue)

io.stderr:write("\n=== FIRST/SENIOR AUTHOR FILTER ===\n")

-- lua/publication-entry.lua builds the three-line entry and emphasises Levin's
-- name. Both filters load it from the folder this file is in, much as source()
-- does in R.
local pub = dofile(pandoc.path.join({pandoc.path.directory(PANDOC_SCRIPT_FILE), "publication-entry.lua"}))

local n_recent = 5  -- default

-- Levin name patterns for matching in formatted citations
local levin_patterns = {
  "Levin MG", "Levin M", "Levin", "Levin MG,", "Levin MG.",
  "Levin M,", "Levin M.", "MG Levin", "M Levin"
}

-- Mark preprints so that the CSL can print their server ("medRxiv. Preprint. 2026.").
-- Zotero exports a preprint to BibTeX as @misc with the server name as publisher.
-- Pandoc reads that as a reference with no type and no journal, so the CSL has no
-- venue to print and cannot tell the entry from any other untyped one. A preprint
-- is recognised here by a server name containing "rxiv" (medRxiv, bioRxiv, arXiv)
-- in its publisher or journal. It goes to citeproc as CSL type "article", with the
-- bare server name as publisher. References in the metadata take precedence over
-- bibliography entries with the same id, so all other entries still come straight
-- from the bibliography file.
-- lua/bibliography-processor.lua has the same function: change both together.
local function retype_preprints(doc)
  local preprints = pandoc.List()
  for _, ref in ipairs(pandoc.utils.references(doc)) do
    local venue = pandoc.utils.stringify(ref.publisher or "") .. " " ..
                  pandoc.utils.stringify(ref["container-title"] or "")
    local server = venue:match("%a*[Rr][Xx][Ii][Vv]%a*")
    if server then
      ref.type = "article"
      ref.publisher = server
      preprints:insert(ref)
    end
  end
  io.stderr:write("Retyped " .. #preprints .. " preprints\n")
  doc.meta.references = preprints
  return doc
end

-- Run citeproc on a document
local function run_citeproc(doc)
  doc = retype_preprints(doc)
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

-- Check if Levin is first author in formatted citation
local function is_first_author(text)
  -- Skip citation number if present (e.g., "22. ")
  local text_without_number = text:gsub("^%d+%.%s*", "")

  -- First author appears at the start, before the first comma
  local first_author_section = text_without_number:match("^([^,]+),")
  if not first_author_section then
    -- Try without comma (single author case)
    first_author_section = text_without_number:match("^([^%.]+)%.")
  end

  if first_author_section then
    for _, pattern in ipairs(levin_patterns) do
      if first_author_section:match(pattern) then
        io.stderr:write("  First author match: " .. first_author_section .. "\n")
        return true
      end
    end
  end

  return false
end

-- Check if Levin is senior (last) author in formatted citation
local function is_senior_author(text)
  -- Skip citation number if present
  local text_without_number = text:gsub("^%d+%.%s*", "")

  -- Senior author is the LAST author (before title/period)
  -- Extract the author section (everything before first period after authors)
  local author_section = text_without_number:match("^([^%.]+)%.")
  if not author_section then
    return false
  end

  -- Count commas to determine number of authors
  local _, comma_count = author_section:gsub(",", "")

  -- If no commas = single author, so first = senior
  if comma_count == 0 then
    return is_first_author(text)
  end

  -- For multiple authors (1+ commas), find the last author
  local last_author = author_section:match(",%s*([^,]+)$")
  if last_author then
    for _, pattern in ipairs(levin_patterns) do
      if last_author:match(pattern) then
        io.stderr:write("  Senior author match: " .. last_author .. "\n")
        return true
      end
    end
  end

  return false
end

-- Check authorship note for equal contribution
local function has_equal_contribution_note(text)
  -- Check for equal contribution language
  local has_equal_language = text:match("[Cc]ontributed equally") or
                             text:match("[Ee]qual contribution") or
                             text:match("co%-first") or
                             text:match("co%-senior")

  if not has_equal_language then
    return false
  end

  -- Check if Levin (or initials) is mentioned in the note
  -- Look for: ML, MG, M Levin, Levin M, Levin MG, etc.
  local levin_initials = {
    "ML[^a-z]", "MG[^a-z]", "M Levin", "Levin M", "Levin MG", "MG Levin"
  }

  for _, pattern in ipairs(levin_initials) do
    if text:match(pattern) then
      io.stderr:write("  Equal contribution note found with Levin mention\n")
      return true
    end
  end

  -- Also check for full patterns from before
  local patterns = {
    "Equal contribution as first",
    "equal contribution as first",
    "Equal contribution as senior",
    "equal contribution as senior"
  }

  for _, pattern in ipairs(patterns) do
    if text:match(pattern) then
      io.stderr:write("  Equal contribution note found\n")
      return true
    end
  end

  return false
end

-- Determine if entry qualifies (first or senior author)
local function qualifies_for_inclusion(entry_div)
  local text = pandoc.utils.stringify(entry_div.content)

  local first = is_first_author(text)
  local senior = is_senior_author(text)
  local equal = has_equal_contribution_note(text)

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
      -- lua/publication-entry.lua). The checks below read the entry's text, so they
      -- get a copy without the markers, which reads as one plain citation:
      -- "12. Authors. Title. Journal. Year;Vol:Pages. doi:10.1/xyz. Authorship Note: ..."
      local plain = pub.without_markers(block)
      local qualifies, is_first, is_senior, is_equal = qualifies_for_inclusion(plain)

      if qualifies then
        local year = extract_year(plain.content)
        table.insert(qualifying_entries, {
          block = block,
          plain = plain,
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
  table.sort(qualifying_entries, function(a, b)
    return a.year > b.year
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
