function search(frag, query)
  local path = string.gsub(frag, "?", query);

  if fs.exists(path) and not fs.isDir(path) then
    return path;
  end

  return nil;
end

return function(g)
  g._LOADED = {};
  g.require = function(query)
    local loaded = g._LOADED[query];
    if loaded == nil then

      --Search path (or default)
      local search_path = g.LUA_PATH or "?;?.lua";

      --Split the path into parts
      local parts = {};
      for part in string.gmatch(search_path, "[^;]+") do
          table.insert(parts, part);
          print(part);
      end

      --Now iterate the parts, seeing if it matches a file
      for _, p in parts do
        loaded = search(p, query);
        if loaded then
          break;
        end
      end

      --Save whatever we found
      g._LOADED[path] = loaded;

    end
    return loaded;
  end
end
