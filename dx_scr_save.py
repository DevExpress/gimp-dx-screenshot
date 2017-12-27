#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from gimpfu import *
from gimpenums import *
import webbrowser


# This is the main plugin function
def script_main(image, drawable, working_dir, open_explorer):
    dir_list = os.listdir(working_dir)

    int_list = []
    for dir in dir_list:
        try: 
            int_list.append(int(dir[0:2])) # You can have 99 commented folders
        except ValueError: 
            pass

    path = os.path.join(working_dir, str(max(int_list) + 1).zfill(2) if len(int_list) > 0 else "01")
    os.mkdir(path)

    filename = os.path.join(path, "Scr.xcf")
    pdb.gimp_file_save(image, drawable, filename, filename)

    saved_image = pdb.gimp_file_load(filename, filename)
    pdb.script_fu_dx_export_png8v2(saved_image, saved_image.layers[0], 1, 0, gimpcolor.RGB(1.0, 1.0, 1.0, 1.0), "_256color", path, 0)

    pdb.gimp_displays_reconnect(image, saved_image)
    pdb.gimp_image_clean_all(saved_image)

    if open_explorer:
        webbrowser.open(path)


# This is the plugin registration function
register(
    "python_fu_dx_scr_saver",	# Function name
    "Screenshot saver",
    "This script creates sequential folders with 2 files in them: Scr.xcf and Scr_256color.png",
    "Vladislav Glagolev",
    "Developer Express inc.",
    "4/16/2014 (rev. 12/27/2017)",
    "<Image>/DX/Screenshot saver",
    "*",	# Image types
    [ # Input
    (PF_DIRNAME, 'working_dir', 'Working directory', 'D:\Screenshots'),
    (PF_TOGGLE, 'open_explorer', 'Open dir after save', 0)
    ],
    [],	# Return
    script_main, # The main plugin function symbol
)

main()