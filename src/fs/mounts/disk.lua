local module = {}

module.create_disk_mount = function(side)
  if not peripheral.getType(side) == "disk" then
    return nil;
  end

  local path = disk.getMountPath(side);

  local fs_mount = fs.CreateFilesystemMount(path);

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

  function mk_mount_fn(name, ...)

  end

  local mount = {};
end

return module;
