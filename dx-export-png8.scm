(define (script-fu-dx-export-png8v2 image-orig
				drawable
				save
				dither
;				export-alpha
				background-color                               
				suffix
                dirname
				to-orig-dir
	)
  
  (let* ((image (car (gimp-image-duplicate image-orig)))
         (name (car (gimp-image-get-name image-orig)))
         (filename (car (gimp-image-get-filename image-orig)))
         (display 0)
         (layers (gimp-image-get-layers image))
         (num-layers (car layers))
         (num-visi-layers 0)
         (layer-array (cadr layers))
         (i 0)
         (layer 0)
         (merged-layer 0)
	 (initial-background-color (car (gimp-context-get-background)))
	)

    (gimp-image-undo-disable image)
    (if (= save FALSE) (set! display (car (gimp-display-new image))))
    ; remove invisible layers, count visible layers
    
    (while (< i num-layers)
	   (set! layer (aref layer-array i))
	   (if (= FALSE (car (gimp-item-get-visible layer)))
	       (gimp-image-remove-layer image layer)
	       (begin
		 (set! num-visi-layers (+ num-visi-layers 1))
		 (set! merged-layer layer)
	       )
	   )
	   (set! i (+ i 1))
    )
    
    ; merge visible layers
    
    (if (> num-visi-layers 1)
	(set! merged-layer (car (gimp-image-merge-visible-layers image CLIP-TO-IMAGE)))
	
    )
    (gimp-context-set-background background-color)
    (if (> num-visi-layers 0) (gimp-image-flatten image) )
    (gimp-context-set-background initial-background-color)
    (if (= (car (gimp-drawable-is-indexed (car (gimp-image-get-active-drawable image)))) FALSE) 
		(gimp-image-convert-indexed image dither 0 256 0 1 "")
	   )
;	  )
 ;   )
    (if (= to-orig-dir TRUE)
	(begin
		(while (not (string=? (substring filename (- (string-length filename) 1)) "."))
		       (set! filename (substring filename 0 (- (string-length filename) 1)))
		)
		(set! filename (substring filename 0 (- (string-length filename) 1)))
		(set! filename (string-append filename suffix ".png"))
	)
	(begin
		(while (not (string=? (substring name (- (string-length name) 1)) "."))
       			(set! name (substring name 0 (- (string-length name) 1)))
    	 	)
		(set! name (substring name 0 (- (string-length name) 1)))
		(set! filename (string-append dirname "/" name suffix ".png"))
	  )
       
    )

    (gimp-image-set-filename image filename)
    (gimp-image-undo-enable image)

	(if (= save TRUE)
		(begin
                   (gimp-file-save 1 image (car (gimp-image-get-active-drawable image)) filename filename)
		   ;(gimp-display-delete display)
		)
	)

    (gimp-displays-flush)
  )
)


(script-fu-register "script-fu-dx-export-png8v2" 
                    "<Image>/DX/Export to PNG-8"
                    "Export image to 256-color PNG..."
                    "Konstantin Beliakov <beliakov@gmail.com>"
                    "Developer Express Inc."
                    "30.10.2009"
                    "*"
                    SF-IMAGE "Image" 0
                    SF-DRAWABLE "Drawable" 0
		    SF-TOGGLE "Don't display exported PNG, save it instantly" TRUE
                    SF-OPTION "Color dithering" '("None" "Floyd-Steinbeg 1" "Floyd-Steinbeg 2" "Positioned")
;                    SF-TOGGLE "Export alpha channel" FALSE
		    SF-COLOR  "Background color" "white"
                    SF-STRING "Add filename suffix" "_256color"
		    SF-DIRNAME "Export to directory" "D:/"
		    SF-TOGGLE  "Use original image directory instead of defined above" TRUE
		    
)
