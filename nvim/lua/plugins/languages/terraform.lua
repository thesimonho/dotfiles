return {
  {
    "ANGkeith/telescope-terraform-doc.nvim",
    keys = {
      { "<localleader>h", "<cmd>Telescope terraform_doc<cr>", ft = "terraform", desc = "Terraform Docs" },
    },
  },
  {
    "mvaldes14/terraform.nvim",
    ft = "terraform",
    keys = {
      {
        "<localleader>s",
        function()
          local current_file = vim.api.nvim_buf_get_name(0) -- Get the current buffer's file name
          if current_file == "" then
            print("No file associated with the current buffer")
            return
          end

          local start_dir = vim.fn.fnamemodify(current_file, ":h") -- Directory of the current file
          local terraform_cwd = utils.find_parent_with_directory(start_dir, ".terraform")

          if terraform_cwd then
            vim.cmd("tcd " .. terraform_cwd)
            vim.cmd("TerraformExplore")
          else
            print("No .terraform directory found in the parent hierarchy")
          end
        end,
        ft = "terraform",
        desc = "State list",
      },
    },
    opts = {
      cmd = "rg",
      program = "terraform",
    },
  },
}
