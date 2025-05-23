local headers = {
  {
    [[    ███╗   ███╗ █████╗ ██╗  ██╗███████╗   ]],
    [[    ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝   ]],
    [[    ██╔████╔██║███████║█████╔╝ █████╗     ]],
    [[    ██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝     ]],
    [[    ██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗   ]],
    [[    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ]],
    [[      ██████╗ ██████╗  ██████╗ ██╗        ]],
    [[     ██╔════╝██╔═══██╗██╔═══██╗██║        ]],
    [[     ██║     ██║   ██║██║   ██║██║        ]],
    [[     ██║     ██║   ██║██║   ██║██║        ]],
    [[     ╚██████╗╚██████╔╝╚██████╔╝███████╗   ]],
    [[      ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝   ]],
    [[███████╗████████╗██╗   ██╗███████╗███████╗]],
    [[██╔════╝╚══██╔══╝██║   ██║██╔════╝██╔════╝]],
    [[███████╗   ██║   ██║   ██║█████╗  █████╗  ]],
    [[╚════██║   ██║   ██║   ██║██╔══╝  ██╔══╝  ]],
    [[███████║   ██║   ╚██████╔╝██║     ██║     ]],
    [[╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝     ]],
  },
  {
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   ]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣆⠀⢀⣀⣀⣤⣤⣤⣶⣦⣤⣤⣄⣀⣀⠀⢠⣾⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀   ]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀   ]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀    ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀    ]],
    [[⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⠟⠀⠀⠀⠀⠀⣀⣤⣤⣤⡀⠀⠀⠀⠀⠀⢀⣤⣤⣤⣄⡀⠀⠀⠀⠀⠘⣿⡿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀   ]],
    [[⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀⠀⠀⣠⣾⣿⣿⠛⣿⡇⠀⠀⠀⠀⠀⢸⣿⣿⠛⣿⣿⣦⠀⠀⠀⠀⠸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀    ]],
    [[⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁⠀⠀⠀⠀⣿⣿⣿⣿⣿⡟⢠⣶⣾⣿⣿⣷⣤⢹⣿⣿⣿⣿⣿⡇⠀⠀⣀⣤⣿⣷⣴⣶⣦⣀⡀⠀⠀⠀⠀   ]],
    [[⠀⠀⠀⠀ ⠀⠀⠀⢀⣠⣤⣤⣤⣇⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⠀⠘⠻⣿⣿⣿⡿⠋⠀⢹⣿⣿⣿⣿⡇⠀⣿⣿⣿⡏⢹⣿⠉⣿⣿⣿⣷⠀⠀⠀   ]],
    [[⠀⠀⠀ ⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣶⣄⠀⠀⠹⣿⣿⠿⠋⠀⢤⣀⢀⣼⡄⠀⣠⠀⠈⠻⣿⣿⠟⠀⢸⣿⣇⣽⣿⠿⠿⠿⣿⣅⣽⣿⡇⠀⠀   ]],
    [[⠀⠀⠀⠀ ⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣟⠁⠀⠀⠀⠈⣿⣿⣿⡇⠀⠀⠀  ]],
    [[⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛]],
    [[⠀⠀⠀⠀⠀⠀⠘⠛⠻⢿⣿⣿⣿⣿⣿⠟⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    ]],
  },
  {
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡉⠀⠌⠳⢳⡔⠒⠒⠒⠂⢤⡠⠐⠨⠐⣈⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠡⠈⠄⡁⠀⢀⠂⠡⠈⠄⡐⠠⢁⠢⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠜⠀⡡⠜⠒⣄⠃⠤⠈⢄⠓⠠⣄⠁⢂⣼⣳⣅⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠠⠐⡍⢀⠊⠀⠀⠀⠈⠲⡆⠗⠁⠀⠀⠀⠙⠾⣞⣷⣻⣟⡶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠔⠈⠀⠀⠌⢧⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⢾⣽⡿⣽⡻⠄⠐⠄⡀⠀⠀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⡠⠊⡀⠀⠀⡀⢌⠠⠈⢷⡀⠀⠈⠒⠒⠀⠀⠀⠀⠒⠒⠁⠀⠀⣸⣿⣻⣽⣳⠏⡈⠐⠠⠈⠢⡀⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⢀⡬⢆⣰⢠⡑⢢⡐⡤⢦⡱⣦⠟⠒⠀⡈⠒⠤⠤⠤⠤⠔⠀⢀⠠⠚⠻⣷⡹⣎⣅⠢⢑⡈⠔⢈⠐⡈⠢⡀⠀⠀⠀ ]],
    [[ ⠀⠀⠀⢀⢾⡸⡝⣦⢯⣙⢧⣫⡷⠿⠋⠀⠀⠀⠀⠀⠉⠀⠒⠒⠒⠂⠈⠀⠀⠀⠀⠀⠑⢯⣜⡳⣇⢦⡍⣤⢂⡔⢠⠑⣄⠀⠀ ]],
    [[ ⠀⠀⠀⠫⣳⢧⡝⡶⢷⡫⢏⡷⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⡿⢯⣞⣼⠲⣏⡼⢣⡟⡼⣦⠀ ]],
    [[ ⠀⠀⠀⠀⠈⠉⠀⢠⢷⣙⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⡗⢮⡹⣛⡷⠚⢓⡟⣺⡽⠁ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠀⣼⡳⡾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⢣⣳⣟⣷⠀⠁⠀⠈⠀⠀ ]],
    [[ ⠀⠀⢀⡀⠀⠀⢠⠻⣷⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⢯⣷⢿⣻⡄⠀⠀⠀⠀⠀ ]],
    [[ ⠀⠀⡨⡄⡙⠀⠣⠀⠿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡦⠈⡟⢻⠁⢸⡀⠀⣀⠀⠀ ]],
    [[ ⠩⡁⠃⠀⠀⠀⠀⠀⠀⠀⢡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠁⠀⠀⠀⠁⠊⠈⠇⡘⠀⠀ ]],
    [[ ⠀⢃⠀⡴⠈⠉⠐⢤⡀⠀⠀⢳⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠁⠀⠀⠀⣀⠠⢀⠀⠀⠀⡇⠀⠀ ]],
    [[ ⠀⠀⠁⢧⡰⢆⡏⢶⣱⠀⠀⠀⣿⡿⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⣇⠀⠀⣼⠳⡤⢤⡄⢵⠀⠠⠁⠀⠀ ]],
    [[ ⠀⠀⠀⠑⠙⡺⠼⠧⠊⠀⡠⠎⠉⠉⠉⠁⠀⠉⠂⠒⠀⠤⠤⠤⠤⠄⠐⠒⠚⠛⠿⠿⠽⠟⢄⠈⢯⡳⣙⢶⡸⠋⡠⠂⠀⠀⠀ ]],
    [[ ⠀⠀⠀⠀⠀⠀⠈⠁⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠈⠉⠁⠐⠁⠀⠀⠀⠀⠀ ]],
  },
  {
    [[            ▄▄▀▀▀▀▀▀▀▀▀▄▄            ]],
    [[           █░░░░░░░░░░░░░█           ]],
    [[          █░░░░░░░░░░▄▄▄░░█          ]],
    [[          █░░▄▄▄░░▄░░███░░█          ]],
    [[          ▄█░▄░░░▀▀▀░░░▄░█▄          ]],
    [[          █░░▀█▀█▀█▀█▀█▀░░█          ]],
    [[          ▄██▄▄▀▀▀▀▀▀▀▄▄██▄          ]],
    [[        ▄█░█▀▀█▀▀▀█▀▀▀█▀▀█░█▄        ]],
    [[       ▄▀░▄▄▀▄▄▀▀▀▄▀▀▀▄▄▀▄▄░▀▄       ]],
    [[       █░░░░▀▄░█▄░░░▄█░▄▀░░░░█       ]],
    [[        ▀▄▄░█░░█▄▄▄▄▄█░░█░▄▄▀        ]],
    [[          ▀██▄▄███████▄▄██▀          ]],
    [[          ████████▀████████          ]],
    [[         ▄▄█▀▀▀▀█   █▀▀▀▀█▄▄         ]],
    [[         ▀▄▄▄▄▄▀▀   ▀▀▄▄▄▄▄▀         ]],
  },
  {
    [[i use                                             ]],
    [[                                                  ]],
    [[███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
    [[████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
    [[██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
    [[██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
    [[██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
    [[╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
    [[                                                  ]],
    [[                                              btw.]],
  },
}

return headers
