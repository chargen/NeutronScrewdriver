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
      return _fs.exists(_fs.combine(root, path));
    end,

    makeDir = function(path)
      return _fs.makeDir(_fs.combine(root, path));
    end,

    find = function(path)
      return _fs.find(_fs.combine(root, path));
    end,
  };
end

function create_fs()

  --list of mounted paths (Path => Accessor)
  local mounts = {};

  --an accessor for the root of the system (path parameter is always ignored, since this is the root by definition)
  local rootAccessor = {
    list = function(_)
      local result = {};
      for p, _ in pairs(mounts) do
        table.insert(p);
      end
      return result;
    end,

    --[[ todo:
      open function(path, mode)
      isReadonly function(path)
      delete function(path)
      isDir function(path)
      getFreeSpace function(path)
      getDrive function(path)
      getSize function(path)
      exists function(path)
      makeDir function(path)
      find function(path)
    ]]
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

    --open
    --isReadonly
    --delete
    --isDir
    --getFreeSpace
    --getDrive

    function list(path)
      local parts, mount, status = GetMount(path);
      if mount then
        return mount:list(table.concat(parts, "/"));
      else
        return nil, "status";
      end
    end,

    --exists
    --makeDir
    --find

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

  --Replace the system "fs" API with our own
  _G["fs"] = fs;

  --Mount the root of the internal HDD to the path "hdd"
  fs.mount("hdd", CreateFilesystemMount("/"));

end
create_fs();
