-- diagnostic-refs.lua
-- Shows detailed structure of the refs div after citeproc

io.stderr:write("\n=== REFS DIV DIAGNOSTIC ===\n")

function Div(div)
  if div.identifier == "refs" or div.classes:includes("references") then
    io.stderr:write("Found bibliography div!\n")
    io.stderr:write("  ID: " .. (div.identifier or "none") .. "\n")
    io.stderr:write("  Classes: " .. table.concat(div.classes, ", ") .. "\n")
    io.stderr:write("  Number of child blocks: " .. #div.content .. "\n\n")

    if #div.content > 0 then
      io.stderr:write("Child block details:\n")
      for i = 1, math.min(3, #div.content) do
        local child = div.content[i]
        io.stderr:write("  Block " .. i .. ": " .. child.t)

        if child.t == "Div" then
          io.stderr:write(" (id='" .. (child.identifier or "") .. "'")
          if #child.classes > 0 then
            io.stderr:write(", classes=" .. table.concat(child.classes, ","))
          end
          io.stderr:write(", " .. #child.content .. " children)")

          -- Show content preview
          if #child.content > 0 then
            local preview = pandoc.utils.stringify(child.content):sub(1, 100)
            io.stderr:write("\n    Preview: " .. preview .. "...")
          end
        end

        io.stderr:write("\n")
      end

      if #div.content > 3 then
        io.stderr:write("  ... and " .. (#div.content - 3) .. " more blocks\n")
      end
    else
      io.stderr:write("  (div is empty - citeproc may not have run yet)\n")
    end

    io.stderr:write("\n=== END DIAGNOSTIC ===\n\n")
  end

  return nil
end

return {{Div = Div}}
