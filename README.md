# GIMP Scripts for Screenshot Processing
## Script-Fu scripts used in DevExpress to design screenshots

### [dx-pointer](dx-pointer.scm)
Adds mouse pointer to screenshot image and applies shadow and/or motion effect.

### [dx-highlight](dx-highlight.scm)
Highlights the selected area.

### [dx-export-png8](dx-export-png8.scm)
Мakes a web-optimized copy of an image (256 colors, png).

###  [dx_scr_save](dx_scr_save.py)
You can use this script to organize the XCFs with 265-colored PNGs automatically. It is written on Python-Fu, which makes it very easy to edit and personalize.

### [dx-screenshot](dx-screenshot.scm)
Erases XP/Vista style window corners, makes wavy crop, adds shadow.

### [Screenshot Processing 2016](dx-screenshot-2016.scm)

In 2016, the screenshot processing script was entirely redesigned. 

The following changes were made.

#### Removed features
* **Erase corners**. Useless in Windows 8+.
* **Auto-flatten**. Useless. And dangerous for GIFs. It will flatten on export anyway, but you **should** save the original XCF with layers to be able to fix and update your screenshots. 

#### Added features
* Works with **GIFs** and images in the **Indexed** mode!
* The default **shadow settings** were corrected according to the designer's prototype.
* **Borders**. Outer or inner. Please add them to all pictures without borders. Every image should be explicitly separated from the text background. GIFs too.
* Different **crop types**. Wavy-crop is not always the best solution, you might want a simple **rectangular crop** with the border.
* Ability to decorate a **layer inside a bigger canvas**. Even the non-rectangular one.
(**Crop type**: _No crop_).
* If you try to wavy-crop an image from three or four sides, you will get a **warning** (if your GIMP window is not maximized [it's open-source, what did you expect?]). The designer recommends using a wavy-crop from **one** side maximum. Consider the rectangular crop in difficult cases.
* Different modes of **history** logging (used mostly for debugging).
* Can place the layer decorations in a separate layer group.
* Can add a white background layer in the end.

The examples of images processed by this script can be found in the [CodeRush](https://documentation.devexpress.com/#CodeRushForRoslyn/CustomDocument115802) docs (not all images are updated yet).

## How to Use

1. Run [Install to 2.10.bat](Install%20to%202.10.bat) or [Install to 2.8.bat](Install%20to%202.8.bat) as Administrator.
2. Restart GIMP.
3. Notice the new **DX** menu.
