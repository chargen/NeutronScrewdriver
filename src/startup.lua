function init_filesystem()
  local fs = dofile("ns/fs.lua");
end

function boot()
  --Prevent the startup script from being terminated
  local pullEvent = os.pullEvent
  os.pullEvent = os.pullEventRaw

  --Override default print function with one which prefixes with a given string
  local prefix = "";
  local default_print = print;
  print = function(v)
    print(prefix .. tostring(v));
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

    default_print("-> Loading " .. name);
    prefix = " | " .. short_name .. ": ";

    load_func();

    prefix = "";
    default_print("<- Loaded " .. name);
  end

  default_print("Loading Neutron Screwdriver");
  pretty_load("File System", "FS", init_filesystem);

  --restore default print
  print = default_print;

  --Allow scripts to be interrupted again
  os.pullEvent = pullEvent
end

boot();
