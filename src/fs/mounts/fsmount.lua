local module = {};

--Create a mount which accesses part of the parent filesystem under some path inside the new file system
function module.create(pfs, root)

  local verbose = false;

  function make_path_func(name)
    return function(path)
      local p = pfs.combine(root, path);
      local f = pfs[name];
      local r = f(p);
      if verbose then print(name .. " @ " .. p .. " == " .. tostring(r)); end
      return r;
    end
  end

  return {
    root = function()
      return root;
    end,

    open = function(path, mode)
      if verbose then
        print("Open(" .. tostring(mode) .. ") @ " .. tostring(path))
      end
      return pfs.open(pfs.combine(root, path), mode);
    end,

    isReadonly = make_path_func("isReadonly"),
    delete = make_path_func("delete"),
    isDir = make_path_func("isDir"),
    getFreeSpace = make_path_func("getFreeSpace"),
    getDrive = make_path_func("getDrive"),
    getSize = make_path_func("getSize"),
    list = make_path_func("list"),
    exists = make_path_func("exists"),
    makeDir = make_path_func("makeDir"),
    find = make_path_func("find")
  };
end

return module;
