function init_filesystem()
  local fs = dofile("ns/fs.lua");
end

function boot()
  --Prevent the startup script from being terminated
  local pullEvent = os.pullEvent
  os.pullEvent = os.pullEventRaw

  print("Loading Neutron Screwdriver");

  print(" -> Loading File System");
  init_filesystem();

  --Allow scripts to be interrupted again
  os.pullEvent = pullEvent
end

boot();
