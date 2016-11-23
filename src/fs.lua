function create_fs()
  --list of mounted paths (Path => Accessor)
  local mounts = {};

  --Save the normal computercraft FS table
  local _fs = fs;

  --Create a mount which accesses part of the normal filesystem under some path
  local function CreateFilesystemMount(root)
    return {
      root = function()
        return root;
      end,

      open = function(path, mode)
        return _fs.open(_fs.combine(root, path), mode);
      end,

      isReadonly = function(path)
        return _fs.isReadonly(_fs.combine(root, path));
      end,

      delete = function(path)
        return _fs.delete(_fs.combine(root, path));
      end,

      isDir = function(path)
        return _fs.isDir(_fs.combine(root, path));
      end,

      getFreeSpace = function(path)
        return _fs.getFreeSpace(_fs.combine(root, path));
      end,

      getDrive = function(path)
        return _fs.getDrive(_fs.combine(root, path));
      end,

      getSize = function(path)
        return _fs.getSize(_fs.combine(root, path));
      end,

      list = function(path)
        return _fs.list(_fs.combine(root, path));
      end,

      exists = function(path)
        local p = _fs.combine(root, path);
        print("exists" .. " @ " .. p);
        return _fs.exists(p);
      end,

      makeDir = function(path)
        return _fs.makeDir(_fs.combine(root, path));
      end,

      find = function(path)
        return _fs.find(_fs.combine(root, path));
      end,
    };
  end

  --an accessor for the root of the system
  --in all the root accessor methods the 'path' parameter is ignored. This is because it accesses the root, so the path must always be "/"
  local rootAccessor = {

    --Simply list all the mount points
    list = function(_)
      local result = {};
      for p, _ in pairs(mounts) do
        table.insert(result, p);
      end
      return result;
    end,

    --todo: open function(path, mode)

    isReadonly = function(_)
      return true;
    end,

    delete = function(_)
      return nil;
    end,

    isDir = function(_)
      return true;
    end,

    getFreeSpace = function(_)
      return 0;
    end,

    getDrive = function(_)
      --This can be one of:
      -- - hdd (stored on this machine)
      -- - rom (stored in rom on this machine)
      -- - <side> (the side the floppy drive is attached to)
      -- It's debateable exactly what the right response is here!
      return "rom";
    end,

    getSize = function(_)
      return 0;
    end,

    exists = function(_)
      return true;
    end,

    makeDir = function(_)
      --The semantics of this function is to silently fail is the path cannot be created (e.g. because it collides with a filename)
    end

    --todo: find function(wildcard)
  };

  --Split a path on the / path separator
  local function SplitPath(path)
    local parts = {};
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part);
    end
    return parts;
  end

  --Given a complete file path, find the appropriate mount to satisfy this path
  --Return the path into the mount, the mount, and the error
  local function GetMount(path)
    local parts = SplitPath(path);

    --Attempting to access the root
    if #parts == 0 then
      return parts, rootAccessor, "ok";
    end

    --Find the mount for the first part of this path
    local mount = mounts[parts[1]];
    table.remove(parts, 1);

    --No such mount!
    if not mount then
      return parts, nil, "not found";
    end

    return parts, mount, "ok";
  end

  function make_mount_func(name, default, func)
    return function(path)
      local parts, mount, status = GetMount(path);
      if mount then
        local f = func(mount);
        f(table.concat(parts, "/"))
      else
        return default;
      end
    end
  end

  local fs = {

    --Mount an accessor at a given path. An accessor must implement:
    --[[
      open function(path, mode)
      isReadonly function(path)
      delete function(path)
      isDir function(path)
      getFreeSpace function(path)
      getDrive function(path)
      getSize function(path)
      list function(path)
      exists function(path)
      makeDir function(path)
      find function(path)
    ]]
    mount = function(path, accessor)
      if mounts[path] ~= nil then
        error("There is already a mount at '" .. path .. "'");
      end

      mounts[path] = accessor;
    end,

    unmount = function(path)
      mounts[path] = nil;
    end,

    --Pass these functions directly onto the relevant mount point
    open         = make_mount_func("open",         nil, function(m) return m.open end),
    isReadonly   = make_mount_func("isReadnly",    nil, function(m) return m.isReadonly end),
    delete       = make_mount_func("delete",       nil, function(m) return m.delete end),
    isDir        = make_mount_func("isDir",        nil, function(m) return m.isDir end),
    getFreeSpace = make_mount_func("getFreeSpace", nil, function(m) return m.getFreeSpace end),
    getDrive     = make_mount_func("getDrive",     nil, function(m) return m.getDrive end),
    getSize      = make_mount_func("getSize",      nil, function(m) return m.getSize end),
    list         = make_mount_func("list",         nil, function(m) return m.list end),
    exists       = make_mount_func("exists",       nil, function(m) return m.exists end),
    makeDir      = make_mount_func("makeDir",      nil, function(m) return m.makeDir end),
    find         = make_mount_func("find",         nil, function(m) return m.find end),

    move = function(from, to)
      error("Not Implemented!");
    end,

    copy = function(from, to)
      error("Not Implemented!");
    end,

    complete = function(partial, path, incFiles, incSlash)
      return {};  --Not Implemented!
    end,

    --These function are not really anything to do with FS. They operate purely on paths
    getName = _fs.getName,
    combine = _fs.combine,
    getDir = _fs.getDir
  }

  --Mount the root of the internal HDD to the path "hdd"
  fs.mount("rom", CreateFilesystemMount("/rom"));
  print("Mounted local ROM @ /rom");

  return fs;

end
return create_fs();
