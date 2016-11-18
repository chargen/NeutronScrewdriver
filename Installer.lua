-- This file is downloaded by the install script (see readme.md). It runs when the computer is rebooted (it's named startup by the download script).

function http_get(url)
  return http.get(url .. "?" .. math.random(10000));
end

function fetch_upgrade()

  --helper function to download a URL into a file
  function download_file(name)

    print("Downloading: " .. name);

    local response = http_get("https://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/" .. name);
    if response.getResponseCode() ~= 200 then
      print(" -> Failed!");
      os.sleep(10);
      return false;
    end

    local file = fs.open("/ns-upgrade/" .. name, "w");
    file.write(response.readAll());
    file.flush();
    file.close();
    print(" -> Complete")

    response.close();

    return true;
  end

  if fs.exists("/ns-upgrade") then
    fs.delete("/ns-upgrade");
  end
  fs.makeDir("/ns-upgrade");

  --fetch manifest from github
  local manifest_request = http_get("https://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/manifest.lua");
  if manifest_request.getResponseCode() ~= 200 then
    return false;
  end
  local manifest_content = manifest_request.readAll();
  local manifest = loadstring(manifest_content);
  manifest = manifest();

  --Save manifest to disk
  local m_handle = fs.open("/ns-upgrade/manifest.lua", "w");
  m_handle.write(manifest_content);
  m_handle.flush();
  m_handle.close();

  --fetch upgrade from github
  for k, v in ipairs(manifest) do
    download_file(v.file)
  end

  return true;
end

function apply_upgrade()

  function read_file(name)
    local path = "/ns-upgrade/" .. name;
    if not fs.exists(path) then
      error("Cannot find file: " .. path);
    end

    local handle = fs.open(path, "r");
    local content = handle.readAll();
    handle.close();

    return content;
  end

  --Check for the upgrade directory
  if (not fs.exists("/ns-upgrade")) then
    return false;
  end

  --Load the update manifest
  local manifest = dofile("/ns-upgrade/manifest.lua");

  --An upgrade is pending, copy over the files from upgrade directory (according to manifest of files)
  for k, v in ipairs(manifest) do

    -- Read the complete contents of the file
    local content = read_file(v.file);
    local path = v.file;

    -- Apply preinstall function
    if v.pre and type(v.pre) == "function" then
      content, path = v.pre(content, path);
    end

    --Make relative to the ns directory (except for startup file, that's special and has to go in the root)
    if path ~= "startup" then
      path = "/ns/" .. path;
    end

    --Check if the destination file already exists and apply patch function
    if v.merge and type(v.merge) == "function" and fs.exists(path) then
      local oldHandle = fs.open(path, "r");
      local oldContent = oldHandle.readAll();
      oldHandle.close();

      print("Upgrading: " .. path);

      content = v.merge(oldContent, content);
    else
      print("Not upgrading: " .. tostring(path) .. "Merge: " .. tostring(v.merge) .. "type: " .. type(v.merge) .. "exist: " .. tostring(fs.exists(path)));
    end

    --Put in place (delete, create)
    if fs.exists(path) then
      fs.delete(path);
    end
    print("Installing: " .. path);
    local handle = fs.open(path, "w");
    handle.write(content);
    handle.flush();
    handle.close();

  end

  --Delete upgrade directory
  fs.delete("/ns-upgrade");

  --Success!
  return true;

end

function boot()
  if not fetch_upgrade() then
    print("Failed to fetch upgrade. Trying again in 30 seconds...");
    os.sleep(30);
  end

  if not apply_upgrade() then
    print("Failed to apply upgrade. Trying again in 30 seconds...")
    os.sleep(30);
  end

  --We've completed applying the upgrade (which includes replacing this startup script with one which boots the actual OS).
  print("Upgraded. Rebooting...")
  os.sleep(5);
  os.reboot();
end

boot();
