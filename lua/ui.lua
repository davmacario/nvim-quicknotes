local M = {}

--- Check num is in the range [0, 1] (extremities included)
--- @param num number
--- @param a number
--- @param b number
--- @return boolean
local function in_range(num, a, b)
	if num >= a and num <= b then
		return true
	end
	return false
end

--- Check if element is in array. Returns the 1-based index if found, else 0.
--- @param val any
--- @param arr any[]
--- @return number
local function in_array(val, arr)
	for i, ival in ipairs(arr) do
		if val == ival then
			return i
		end
	end
	return 0
end

local valid_win_attr = {}
valid_win_attr.border = {
	"rounded",
}
valid_win_attr.style = {
	"minimal",
}
valid_win_attr.relative = {
	"editor",
}

-- Open file in floating window
--- @param filename string
--- @param opts table
function M.open_float_win(filename, opts)
	-- Default opts
	local window = {
		width = 0.5,
		height = 0.6,
		relative = "editor",
		style = "minimal",
		border = "rounded",
	}
  local title = "📝 Quicknotes"
	local title_color = "#FABD2F"

	if opts ~= nil then -- extract options
		if opts.width and in_range(opts.width, 0, 1) then
			window.width = opts.width
		end
		if opts.height and in_range(opts.height, 0, 1) then
			window.height = opts.height
		end
		if opts.relative and in_array(opts.relative, valid_win_attr.relative) then
			window.relative = opts.relative
		end
		if opts.style and in_array(opts.style, valid_win_attr.style) then
			window.style = opts.style
		end
		if opts.border and in_array(opts.border, valid_win_attr.border) then
			window.border = opts.border
		end
    title = opts.title or title
		title_color = opts.title_color or title_color
	end
	vim.api.nvim_set_hl(0, "TYellow", { fg = title_color })
	local title_format = {
		title = { { title, "TYellow" } },
		title_pos = "center",
	}

	-- Create buffer
	local newbuf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_name(newbuf, filename)

	-- Ensure floating win is at least 10x80 always
	window.width = math.max(math.floor(vim.o.columns * window.width), 80)
	window.height = math.max(math.floor(vim.o.lines * window.height), 10)
	window.col = math.floor((vim.o.columns - window.width) / 2)
	window.row = math.floor((vim.o.lines - window.height) / 2)

	local windowopts = vim.tbl_extend("force", window, title_format)
	local win = vim.api.nvim_open_win(newbuf, true, windowopts)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].cursorline = false
	vim.api.nvim_set_current_win(win)

	vim.cmd("edit " .. vim.fn.fnameescape(filename))
  vim.bo[newbuf].buflisted = false
	vim.bo[newbuf].readonly = false
	vim.bo[newbuf].modifiable = true
	vim.bo[newbuf].filetype = vim.filetype.match({ filename = filename, buf = newbuf }) or "markdown"
	vim.bo[newbuf].bufhidden = "delete"
	vim.bo[newbuf].buftype = ""
	vim.bo[newbuf].swapfile = false
	vim.diagnostic.enable(false, { bufnr = newbuf })

	vim.keymap.set("n", "q", function()
		vim.api.nvim_buf_call(newbuf, function()
			vim.cmd("silent write!")
		end)
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(newbuf, { force = true })
	end, {
		buffer = newbuf,
		noremap = true,
		silent = true,
		desc = "Write and quit floating window.",
	})
end

return M
