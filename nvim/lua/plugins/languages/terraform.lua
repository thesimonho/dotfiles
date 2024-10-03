return {
  {
    "ANGkeith/telescope-terraform-doc.nvim",
    keys = {
      { "<localleader>h", "<cmd>Telescope terraform_doc<cr>", ft = "terraform", desc = "Terraform Docs" },
      { "<localleader>s", "<cmd>Telescope terraform state_list<cr>", ft = "terraform", desc = "State list" },
    },
  },
}
