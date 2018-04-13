# A collection of GIMP scripts used in DevExpress for screenshot design


## dx-pointer-*
Adds mouse pointer to screenshot image and applies shadow and/or motion effect.

## dx-highlight-*
Highlights the selected area.

## dx-export-png8-*
Couple of GIMP scripts. One makes a web-optimized copy of image (256 colors, png), another does the same with a set of images in batch mode.

* File -> Export to PNG8
* File -> Export to PNG8 (batch)

## Screenshot Processing 2016

In 2016, the screenshot processing script was entirely redesigned. 

The following changes were made.

### Removed features
* **Erase corners**. Please, do update to Windows 10 now. Screenshots from Windows 7 is a shame for any modern windows software, IMHO.
* **Auto-flatten**. Useless. And dangerous for GIFs. It will flatten on export anyway, but you **should** save the original XCF with layers to be able to fix and update your screenshots. 

> **NOTE**
You can use the **dx_screenshot_saver** script to organize the XCFs with 265-colored PNGs automatically. It is written on Python-Fu, which makes it very easy to edit and personalize.

### Added features
* Works with **GIFs** and images in the **Indexed** mode!
* The default **shadow settings** were corrected according to the designer's prototype.
* **Borders**. Outer or inner. Please add them to all pictures without borders. Every image should be explicitly separated from the text background. GIFs too.
* Different **crop types**. Wavy-crop is not always the best solution, you might want a simple **rectangular crop** with the border.
* Ability to decorate a **layer inside a bigger canvas**. Even the non-rectangular one.
(**Crop type**: _No crop_).
* If you try to wavy-crop an image from three or four sides, you will get a **warning** (if your GIMP window is not maximized [it's open-sourse, what did you expect?]). The designer advices to use wavy-crop from **one** side maximum. Consider the rectangular crop in difficult cases.
* Different modes of **history** logging (used mostly for debugging).
* Can place the layer decorations in a separate layer group.
* Can add a white background layer in the end.

The examples of images processed by this script can be found in the [CodeRush](https://documentation.devexpress.com/#CodeRushForRoslyn/CustomDocument115802) docs (not all images are updated yet).
