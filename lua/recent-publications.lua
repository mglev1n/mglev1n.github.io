-- recent-publications.lua
-- Filters bibliography to show only N most recent publications

local n_recent = 5  -- default

-- Get parameter from metadata
function Meta(meta)
  if meta.params and meta.params.n_recent then
    n_recent = tonumber(pandoc.utils.stringify(meta.params.n_recent)) or 5
  end
  return meta
end

-- Extract year from citation
local function get_year(cite)
  if cite.issued and cite.issued['date-parts'] then
    local date_parts = cite.issued['date-parts'][1]
    if date_parts and date_parts[1] then
      return tonumber(date_parts[1])
    end
  end
  return 0
end

-- Filter references to most recent N
function Pandoc(doc)
  if not doc.meta.references then
    return doc
  end
  
  local refs = doc.meta.references
  local ref_list = {}
  
  -- Convert to list and extract years
  for i, ref in ipairs(refs) do
    table.insert(ref_list, {
      ref = ref,
      year = get_year(ref),
      index = i
    })
  end
  
  -- Sort by year (descending), then by original index
  table.sort(ref_list, function(a, b)
    if a.year ~= b.year then
      return a.year > b.year
    else
      return a.index < b.index
    end
  end)
  
  -- Keep only N most recent
  local recent_refs = {}
  for i = 1, math.min(n_recent, #ref_list) do
    table.insert(recent_refs, ref_list[i].ref)
  end
  
  doc.meta.references = recent_refs
  return doc
end

return {
  {Meta = Meta},
  {Pandoc = Pandoc}
}
