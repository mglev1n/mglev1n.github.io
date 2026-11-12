-- bibliography-processor.lua
-- Manually runs citeproc, then adds year headers and lays each entry out in
-- three lines (title, authors, venue)
-- Leverages the fact that citeproc already sorts entries by year

io.stderr:write("\n=== BIBLIOGRAPHY PROCESSOR ===\n")

-- lua/publication-entry.lua corrects the references before citeproc runs, builds
-- the three-line entry, and emphasises Levin's name. Both filters load it from the
-- folder this file is in, much as source() does in R.
local pub = dofile(pandoc.path.join({pandoc.path.directory(PANDOC_SCRIPT_FILE), "publication-entry.lua"}))

-- Run citeproc on a document
local function citeproc(doc)
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
  local one_paragraph_count = 0
  local year_count = 0
  local entries_without_year = 0
  local undated = {}  -- entries with no usable date, listed after all the others

  for _, block in ipairs(refs_div.content) do
    if block.t == "Div" and block.classes:includes("csl-entry") then
      entry_count = entry_count + 1

      -- The year comes from the reference's date field (year_of in
      -- lua/publication-entry.lua). A reference with no usable date is never given
      -- a year guessed from other numbers in the entry: it is set aside and listed
      -- at the end, under "Undated".
      local year = pub.year_of(block)

      if not year then
        entries_without_year = entries_without_year + 1
      elseif year ~= current_year then
        -- The year changed: add a header
        io.stderr:write("  Adding year header: " .. year .. "\n")
        table.insert(new_content, pandoc.Header(3, {pandoc.Str(tostring(year))}))
        current_year = year
        year_count = year_count + 1
      end

      -- Lay the entry out in three lines: title, authors, venue. This also puts the
      -- citation number ("12.") in its own span, which the stylesheet sets in a
      -- gutter beside the entry, emphasises Levin's name, and puts the authorship
      -- note after the venue.
      local entry, done = pub.format(block, {show_number = true, show_note = true})
      if done.levin then total_highlighted = total_highlighted + 1 end
      if not done.three_lines then one_paragraph_count = one_paragraph_count + 1 end

      -- Add the entry
      if year then
        table.insert(new_content, entry)
      else
        table.insert(undated, entry)
      end
    end
  end

  if #undated > 0 then
    table.insert(new_content, pandoc.Header(3, {pandoc.Str("Undated")}))
    for _, entry in ipairs(undated) do
      table.insert(new_content, entry)
    end
  end

  io.stderr:write("Processed " .. entry_count .. " entries\n")
  io.stderr:write("Added " .. year_count .. " year headers\n")
  io.stderr:write("Emphasised Levin in " .. total_highlighted .. " entries\n")

  if entries_without_year > 0 then
    io.stderr:write("WARNING: " .. entries_without_year .. " entries have no date and are listed under Undated\n")
  end

  if one_paragraph_count > 0 then
    io.stderr:write("WARNING: " .. one_paragraph_count .. " entries have no part markers and are shown " ..
                    "as one paragraph. Is the csl file templates/american-medical-association-no-et-al-v2.csl?\n")
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
