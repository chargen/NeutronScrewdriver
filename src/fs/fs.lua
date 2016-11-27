function create_fs()
  --list of mounted paths (Path => Accessor)
  local mounts = {};

  --Save the normal computercraft FS table
  local _fs = _G.fs;

  --Create a mount which accesses part of the normal filesystem under some path
  local function CreateFilesystemMount(root)

    local verbose = false;

    function make_path_func(name)
      return function(path)
        local p = _fs.combine(root, path);
        local f = _fs[name];
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
        print("Open(" .. tostring(mode) .. ") @ " .. tostring(path))
        return _fs.open(_fs.combine(root, path), mode);
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

    open = function(_, _)
      --There are no files in the root, so all open calls will fail
      return nil;
    end,

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
      return nil;
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
        return f(table.concat(parts, "/"))
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
    open = function(path, mode)
      local parts, mount, status = GetMount(path);
      if mount then
        return mount.open(table.concat(parts, "/"), mode);
      else
        return default;
      end
    end,
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

  --Mount the root of the internal ROM to the path "rom"
  fs.mount("rom", CreateFilesystemMount("/rom"));
  print("Mounted local ROM @ /rom");

  --Test requireing things
  local mod = dofile("ns/fs/test.lua");
  mod.hello_world();

  return fs;

end
return create_fs();
