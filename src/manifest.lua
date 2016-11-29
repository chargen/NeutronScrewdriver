--This is a list of all files in NeutronScrewdriver with associated metadata
return {
  {
    --Path to the file (relative to 'src' directory)
    file = "demo.lua",

    --Preinstall function (string:content, string:path) -> (string:content, string:path)
    --Content of file and path of file can be modified here
    pre = function(content, path)
      return string.gsub(content, "Hello", "Goodbye"), path;
    end,

    --Merge function (string:old, string:new) -> string:content
    --Given the old content of the file, and the new content of the file merges them to produce the content to install
    merge = function(content_old, content_new)
      return content_new .. " patched"
    end,
  },

  {
    file = "startup.lua",
    pre = function(content, path) return content, "startup"; end  --Rename to "startup"
  },

  { file = "fs/fs.lua" },
  { file = "fs/mounts/disk.lua" },
  { file = "fs/mounts/fsmount.lua" },

  { file = "rq/require.lua" },

  { file = "sh/sh.lua" }
};
