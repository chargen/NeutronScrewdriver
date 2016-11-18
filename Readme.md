# NeutronScrewdriver

NeutronScrewdriver is an operating system for the Minecraft [ComputerCraft](http://www.computercraft.info/wiki/Main_Page) mod.

## Installation

To install NeutronScrewdriver you need to get all the files onto your computer. The easiest way to do this is to use the install script, this requires the HTTP API to be enabled in computercraft.

You need to get the installer onto your computer somehow. To do this place the following into a file called "ns-install" on a floppy disk:

```
local content = http.get("https://raw.githubusercontent.com/martindevans/NeutronScrewdriver/master/Installer.lua").readAll()
if not content then
  error("Could not connect to website")
end
local file = fs.open("startup", "w");
file.write(content);
file.flush();
file.close();

os.reboot()
```

When you run ns-install it will download an update, reboot the computer and apply the update.

## Features

 - Filesystem drivers
 - Cryptography API

## Repo Layout

The "src" directory is merged into the root directory of a computer when it is installed.
