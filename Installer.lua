-- This file is downloaded by the install script (see readme.md). It runs when the computer is rebooted (it's named startup by the download script).

function fetch_upgrade()

  --helper function to download a URL into a file
  function download_file(url, path)
    local response = http.get("http://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/" .. url);
    if manifest_request.getResponseCode ~= 200 then
      return false;
    end

    local file = fs.open(path, "r");
    file.write(response.readAll());

    file.close();
    response.close();

    return true;
  end

  --Check for the upgrade directory. If we've already fetched it do nothing
  if (not fs.exists("/ns-upgrade")) then

    --fetch manifest from github
    local manifest_request = http.get("http://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/src/manifest.lua");
    if manifest_request.getResponseCode ~= 200 then
      return false;
    end
    local manifest = dofile(manifest_request.readAll());

    --fetch upgrade from github
    for k, v in ipairs(manifest) do
      download_file(v.file, "/ns-upgrade/" .. v.file)
      print(v);
      os.sleep(1);
    end

    --we've fetched the update, reboot. This is the startup script so it will run again and apply the update
    os.reboot();

  end
end

function apply_upgrade()

  --Check for the upgrade directory
  if (not fs.exists("/ns-upgrade")) then
    return false;
  end

  --Load the update manifest
  local manifest = dofile("/ns-upgrade/manifest.lua");

  --An upgrade is pending, copy over the files from upgrade directory (according to manifest of files)
  --todo!

  --Delete upgrade directory
  fs.delete("/ns-upgrade");

end

function boot()
  fetch_upgrade();

  --if not apply_upgrade() then
  --  print("Failed to apply upgrade. Trying again in 30 seconds...")
  --  os.sleep(30);
  --end

  --We've completed applying the upgrade (which includes replacing this startup script with one which boots the actual OS).
  --os.reboot();
end
