local M = {}

-- Largely inspired by https://github.com/nvim-tree/nvim-tree.lua/blob/master/lua/nvim-tree/utils.lua

M.path_separator = package.config:sub(1, 1)
M.quicknote_path_separator = "%%"
M.root_dir = (M.path_separator == "\\") and "C:/" or "/"

M.is_unix = vim.fn.has("unix") == 1
M.is_macos = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
M.is_wsl = vim.fn.has("wsl") == 1
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

-- Get dir of current file
function M.get_current_file_directory()
	local source = debug.getinfo(1, "S").source
	local path = source:sub(2) -- Remove the "@" at the start of the source path
	return path:match("(.*" .. M.path_separator .. ")")
end

-- Open file in read-only buffer
--- @param filename string
function M.open_readonly(filename)
	vim.cmd.edit(vim.fn.fnameescape(filename))
	vim.bo.readonly = true
	vim.bo.modifiable = false
end

-- Get the name (no path) of the quicknotes file
--- @return string
function M.get_qn_fname()
	local cwd = M.path_remove_trailing(vim.fn.getcwd())
	local path, _ = M.path_join({ M.path_remove_leading(cwd), "quicknotes.md" })
		:gsub(M.path_separator, M.quicknote_path_separator)
	return path
end

-- Get the path of a project for which the quicknote name was given
-- (Reverses get_qn_fname)
--- @param name string
--- @return string
function M.get_qn_project(name)
	-- remove stuff after last `%%`
	local global_path = M.root_dir .. name:gsub(M.quicknote_path_separator, M.path_separator)
	local dir = global_path:match("^(.+)" .. M.path_separator .. ".+$")
	return dir
end

-- Checks whether the quicknote name is correct (it should end with %quicknotes.md)
--- @param name string
--- @return boolean
function M.is_name_quicknotes(name)
  local match = name:match("^.+" .. M.quicknote_path_separator .. "quicknotes.md")
  return match ~= nil
end

-- Path operations

-- Check if given file exists
--- @param name string
--- @return boolean
function M.file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

-- Remove trailing path separator chars ("dir/" --> "dir")
---@param path string
---@return string
function M.path_remove_trailing(path)
	local p, _ = path:gsub(M.path_separator .. "$", "")
	return p
end

-- Remove path separator at the beginning of the string
---@param path string
---@return string
function M.path_remove_leading(path)
	local p, _ = path:gsub("^" .. M.path_separator, "")
	return p
end

---@param paths string[]
---@return string
function M.path_join(paths)
	return table.concat(vim.tbl_map(M.path_remove_trailing, paths), M.path_separator)
end

---@param path string
---@return string[]
function M.path_split(path)
	local t = {}
	for str in string.gmatch(path, "([^" .. M.path_separator .. "]+)") do
		table.insert(t, str)
	end
	return t
end

-- Get the basename of the given path.
---@param path string
---@return string
function M.path_basename(path)
	path = M.path_remove_trailing(path)
	local i = path:match("^.*()" .. M.path_separator)
	if not i then
		return path
	end
	return path:sub(i + 1, #path)
end

-- Create file. Need to ensure the file does not exists before calling this function.
--- @param file string
--- @return boolean
function M.create_file(file)
	local ok, fd = pcall(vim.loop.fs_open, file, "w", 420)
	if not ok or type(fd) ~= "number" then
		-- TODO: format error correctly
		print("Could not create file '" .. file .. "'")
		return false
	end
	vim.loop.fs_close(fd)
	return true
end

-- Delete file
--- @param file string
--- @return boolean
function M.delete_file(file)
	local success, err = os.remove(file)
	if not success then
		error("Failed to delete file: " .. err)
		return false
	end
	return true
end

-- Create directory.
--- @param path string
--- @return boolean
function M.create_dir(path)
	local success = pcall(vim.uv.fs_mkdir, path, 493)
	if not success then
		-- TODO: format error correctly
		print("Could not create folder '" .. path .. "'")
		return false
	end
	return true
end

-- Create file and all intermediate directories
--- @param new_file_path string
function M.create_file_and_dirs(new_file_path)
	local p = M.path_remove_trailing(new_file_path)
	local path_to_create = ""
	-- local is_last_path_file = not new_file_path:match(M.path_separator .. "$")
	local split_path = M.path_split(new_file_path)
	for idx, path in ipairs(split_path) do
		path_to_create = M.path_join({ path_to_create, path })
		if idx < #split_path and not M.file_exists(path_to_create) then
			if not M.create_dir(path_to_create) then
				break
			end
		elseif not M.file_exists(path_to_create) then
			if not M.create_file(path_to_create) then
				break
			end
		end
	end
end

return M
