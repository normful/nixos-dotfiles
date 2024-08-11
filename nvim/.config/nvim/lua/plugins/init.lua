return {
	{
		'normful/monokai.nvim',
    -- 'rebelot/kanagawa.nvim',
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme monokai]])
			-- vim.cmd([[colorscheme kanagawa]])
		end,
	},
	{ 'nvim-lua/plenary.nvim', lazy = false },
}
