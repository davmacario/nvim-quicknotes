local utils = require("utils")
local ui = require("ui")
local DEFAULTS = {
	quicknotes_dir = utils.path_join({ os.getenv("HOME"), ".local/state/nvim/quicknotes/" }),
	window = {
		width = 0.5,
		height = 0.6,
		relative = "editor",
		style = "minimal",
		border = "rounded",
    title = "📝 Quicknotes",
		title_color = "#FABD2F",
	},
}

local config = DEFAULTS

local M = {}

M.setup_called = false

-- Check whether the quicknotes directory exists. If not, create it.
function M.check_quicknotes_dir()
	if vim.fn.isdirectory(config.quicknotes_dir) == 0 then
		utils.create_dir(config.quicknotes_dir)
	end
end

-- Open editable floating buffer containing the quicknote
function M.open_quicknotes()
	-- Build file name
	local qn_path = utils.path_join({ config.quicknotes_dir, utils.get_qn_fname() })
	-- qn_path = vim.fn.fnameescape(qn_path)
	-- Check if file exists, if not, create it
	if not utils.file_exists(qn_path) then
		utils.create_file_and_dirs(qn_path)
	end
	-- Open the floating window with the file
	-- TODO: check if modifying opts in setup changes them here also
	ui.open_float_win(qn_path, config.window)
end

-- Cleanup the directory - remove quicknotes whose associated project does not
-- exist anymore
function M.cleanup_quicknotes()
	local p, err = io.popen("ls -1 " .. config.quicknotes_dir)
	if p == nil then
		error("Unable to get directory contents: " .. err)
		return
	end
	for filename in p:lines() do
		local project_path = utils.get_qn_project(filename)
		if not utils.is_name_quicknotes(filename) or (vim.fn.isdirectory(project_path) == 0) then
			print("Removing " .. filename)
			local ok, err1 = os.remove(utils.path_join({ config.quicknotes_dir, filename }))
			if not ok then
				error("Unable to delete " .. filename .. ": " .. err1)
				break
			end
		end
	end
	p:close()
end

function M.clear_quicknotes()
	local qn_path = utils.path_join({ config.quicknotes_dir, utils.get_qn_fname() })
	if utils.file_exists(qn_path) then
		utils.delete_file(qn_path)
	end
end

function M.create_user_commands()
	local usercmd = vim.api.nvim_create_user_command
	usercmd("Quicknotes", function(opts)
		if opts.bang then
			M.clear_quicknotes()
		end
		M.open_quicknotes()
	end, { desc = "Open quicknotes. If `!`, wipes the note before (will open a blank note)", bar = true })
	usercmd("QuicknotesClear", M.clear_quicknotes, { desc = "Wipe quicknotes for current dir" })
	usercmd(
		"QuicknotesCleanup",
		M.cleanup_quicknotes,
		{ desc = "Cleanup quicknotes folder (delete notes which don't have an associated directory anymore)" }
	)
end

function M.setup(opts)
	if M.setup_called then
		return
	end

	M.setup_called = true
	-- Set opts
	config = vim.tbl_extend("force", config, opts or {})
	-- Check quicknotes_dir exists (else, create it) -- maybe not needed because of utils.create_file_and_dirs
	M.check_quicknotes_dir()
	-- Cleanup
	M.cleanup_quicknotes()
	-- Define user commands
	M.create_user_commands()
end

return M -- require("...")
