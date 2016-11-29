local module = {};

local fsmount = require("ns/fs/mounts/fsmount");

--Split a path on the / path separator, return table of parts
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

--Helper function for making mount point functions which just pass to an function on the mount with the same name
local function make_mount_func(name, default, func)
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

module.inject = function(g)
  --Save the parent FS table
  local pfs = g.fs;

  --list of mounted paths (Path => Accessor)
  local mounts = {};

  --an accessor specifically for the path / (which is simply a directory of all the mount points)
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

  --Create the object we're going to substitute for FS
  g.fs = {
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
  };
end

return module;
