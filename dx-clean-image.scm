(define (script-fu-dx-clean image)
(gimp-image-clean-all image)
)

(script-fu-register "script-fu-dx-clean" 
                    "<Image>/DX/Clean Image"
                    "Clean the current image to close it instantly"
                    "Vladislav Glagolev"
                    "Developer Express Inc."
                    "7/8/14"
                    "*"
                    SF-IMAGE "Image" 0	    
)
