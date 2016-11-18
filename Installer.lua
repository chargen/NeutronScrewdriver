-- This file is downloaded by the install script (see readme.md). It runs when the computer is rebooted (it's named startup by the download script).

function fetch_upgrade()

  --helper function to download a URL into a file
  function download_file(name)

    print("Downloading: '" .. name);

    local response = http.get("https://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/" .. name);
    if response.getResponseCode ~= 200 then
      print(" -> Failed!");
      os.sleep(10);
      return false;
    end

    local file = fs.open("/ns-upgrade/" .. name, "w");
    file.write(response.readAll());
    file.flush();
    file.close();

    response.close();

    return true;
  end

  if fs.exists("/ns-upgrade") then
    fs.delete("/ns-upgrade");
  end
  fs.makeDir("/ns-upgrade");

  --fetch manifest from github
  local manifest_request = http.get("https://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/manifest.lua");
  if manifest_request.getResponseCode() ~= 200 then
    return false;
  end
  local manifest = loadstring(manifest_request.readAll());
  manifest = manifest();

  --fetch upgrade from github
  for k, v in ipairs(manifest) do
    download_file(v.file)
  end

  return true;
end

function apply_upgrade()

  --Check for the upgrade directory
  if (not fs.exists("/ns-upgrade")) then
    return false;
  end

  --Load the update manifest
  local manifest = loadstring("/ns-upgrade/manifest.lua");
  manifest = manifest();

  --An upgrade is pending, copy over the files from upgrade directory (according to manifest of files)
  --todo!

  --Delete upgrade directory
  fs.delete("/ns-upgrade");

end

function boot()
  if not fetch_upgrade() then
    print("Failed to fetch upgrade. Trying again in 30 seconds...");
    os.sleep(30);
  end

  --if not apply_upgrade() then
  --  print("Failed to apply upgrade. Trying again in 30 seconds...")
  --  os.sleep(30);
  --end

  --We've completed applying the upgrade (which includes replacing this startup script with one which boots the actual OS).
  --os.reboot();
end

boot();
