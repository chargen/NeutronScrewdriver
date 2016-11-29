local function init_filesystem()
  local fs = require("ns/fs/fs.lua")
  fs.inject(_G);

  --Mount the root of the internal ROM to the path "rom"
  g.fs.mount("rom", fsmount.create(pfs, "/rom"));
  print("Mounted local ROM @ /rom");

  --Create disk mounts for sides where disks are present
  --todo: ^
end

local function init_shell()
  dofile("ns/sh/sh.lua").inject(_G);
end

local function init_network()

end

local function boot()
  --Prevent the startup script from being terminated
  local pullEvent = os.pullEvent
  os.pullEvent = os.pullEventRaw

  --Override default print function with one which prefixes with a given string
  local prefix = "";
  local default_print = print;
  print = function(v)
    default_print(prefix .. tostring(v));
  end

  --Create a utility function for running a load in the context of a pretty print
  function pretty_load(name, short_name, load_func)
    --[[ e.g. this will result in something like this:

    -> Loading File System
     | FS: Mounted Root
     | FS: Mounted Disk 'Left'
     | FS: Mounted Network 'Machine'
    <- Loaded File System

    This assumes loaders simply call print). If loaders mess with term.write and term.blit the formatting may break
    ]]

    prefix = "";
    print("-> Loading " .. name);
    prefix = " | " .. short_name .. ": ";

    local inject = load_func();
    inject(_G);

    prefix = "";
    print("<- Loaded " .. name);
  end

  default_print("Loading Neutron Screwdriver");

  --Loader initialization is different (because it can't rely on the loader!)
  pretty_load("Loader", "RQ", function() return dofile("ns/rq/require.lua"); end);

  pretty_load("File System", "FS", init_filesystem);
  --pretty_load("Shell", "SH", init_shell);
  --pretty_load("Network", "NT", init_network)

  --restore default print
  print = default_print;

  --Allow scripts to be interrupted again
  os.pullEvent = pullEvent
end

boot();
