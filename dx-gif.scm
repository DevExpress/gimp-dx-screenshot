(define 
(script-fu-dx-gif   image
                    drawable
                    drop-shadow
                    shadow-color
                    shadow-offset-x
                    shadow-offset-y
                    shadow-blur
                    shadow-opacity
                    draw-border
                    border-color
                    border-opacity
)

(let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))

    	(border-layer 0)
    	(background-layer (vector-ref (car (cdr (gimp-image-get-layers image))) (- (car (gimp-image-get-layers image)) 1))) ; The last layer
    	(background-name (car (gimp-item-get-name background-layer)))
    	(shadow-layer 0)
    	(white-layer 0)
    )

	(gimp-context-push)
;BEGIN -----------------------------------------------------------
    
    (gimp-image-convert-rgb image) ; Because GIMP can't operate opacity in INDEXED

    (gimp-image-resize image (+ image-width 2) (+ image-height 2) 1 1)
    
    (set! image-width (car (gimp-image-width image)))
    (set! image-height (car (gimp-image-height image)))
    
    (gimp-image-undo-group-start image)
        (gimp-image-set-active-layer image background-layer)
        (gimp-selection-all image)

    	(if (= draw-border TRUE) (begin
           	(set! border-layer (car (gimp-layer-new image
           	                                        image-width
           	                                        image-height
           	                                        RGBA-IMAGE
           	                                        "Border"
           	                                        border-opacity
           	                                        NORMAL-MODE
           	)                  )    )
         	(gimp-drawable-fill border-layer TRANSPARENT-FILL) 
        	(gimp-image-insert-layer image border-layer 0 (- (car (gimp-image-get-layers image)) 1))
    	
    	    (gimp-context-set-foreground border-color)
    
        	(gimp-image-select-rectangle image CHANNEL-OP-SUBTRACT
        	                             (+ (list-ref (gimp-selection-bounds image) 1) 1)   ;x0
        	                             (+ (list-ref (gimp-selection-bounds image) 2) 1)   ;y0
                                         (- (list-ref (gimp-selection-bounds image) 3) (list-ref (gimp-selection-bounds image) 1) 2) ;w
                                         (- (list-ref (gimp-selection-bounds image) 4) (list-ref (gimp-selection-bounds image) 2) 2) ;h
            ) ; gimp-selection-border sucks
     	
     		(gimp-edit-bucket-fill-full border-layer 
     		                            FG-BUCKET-FILL 
     		                            NORMAL-MODE
     		                            100   ; opacity
     		                            0     ; threshold
     		                            FALSE ; sample-merged (Use the composite image, not the drawable)
     		                            TRUE  ; fill-transparent
     		                            SELECT-CRITERION-COMPOSITE
     		                            0 0
            )
    	))
        (gimp-selection-all image)
	(gimp-image-undo-group-end image)
	
	(if (= drop-shadow TRUE) (begin
        (gimp-image-undo-group-start image)

    		(script-fu-drop-shadow  image background-layer 
    		                        shadow-offset-x
    		                        shadow-offset-y
    		                        shadow-blur
    		                        shadow-color
    		                        shadow-opacity
    		                        1)    ; Allow resizing
		
		(set! shadow-layer (car (gimp-image-get-layer-by-name image "Drop Shadow")))
		(gimp-item-set-name shadow-layer "Shadow")
		(gimp-image-lower-item-to-bottom image shadow-layer)
		
		(gimp-image-undo-group-end image)
	))

    (gimp-image-undo-group-start image)
    	(gimp-selection-none image)

       	(set! white-layer (car (gimp-layer-new image (car (gimp-image-width image)) (car (gimp-image-height image)) RGBA-IMAGE "White" 100 NORMAL-MODE)))
     	(gimp-drawable-fill white-layer WHITE-FILL)
    	(gimp-image-insert-layer image white-layer 0 (car (gimp-image-get-layers image)))
    (gimp-image-undo-group-end image)

    (gimp-image-undo-group-start image)
        (set! border-layer (car (gimp-image-merge-down image border-layer EXPAND-AS-NECESSARY))) ; 1. Border & Background -> Border
        (set! border-layer (car (gimp-image-merge-down image border-layer EXPAND-AS-NECESSARY))) ; 2. Border & Shadow -> Border
        (set! background-layer (car (gimp-image-merge-down image border-layer EXPAND-AS-NECESSARY))) ; 3. Border & White -> Background
        (gimp-item-set-name background-layer background-name)

    (gimp-image-undo-group-end image)
    
    (gimp-image-convert-indexed image NO-DITHER MAKE-PALETTE 255 TRUE TRUE "")

;END -----------------------------------------------------------
	(gimp-displays-flush)
	(gimp-context-pop)
) ;let
) ;define



(script-fu-register "script-fu-dx-gif"
    _"_GIF Screenshot processing..."
    _"Draws border and adds modern shadow."
    "Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>, Vladislav Glagolev <vladislav.glagolev@devexpress.com>"
    "Developer Express Inc."
    "7/15/2016"
    "INDEXED* GRAY*"
    SF-IMAGE      "Image"                               0
    SF-DRAWABLE   "Drawable"                            0
    SF-TOGGLE     _"Drop shadow"                        TRUE
    SF-COLOR      _"Shadow color"                       "black"
    SF-ADJUSTMENT _"Shadow offsrt X (-10..10 pixels)"   '(0 -10 10 1 10 0 )
    SF-ADJUSTMENT _"Shadow offsrt Y (-10..10 pixels)"   '(2 -10 10 1 10 0 )
    SF-ADJUSTMENT _"Shadow blur radius (0-40 pixels)"   '(5 0 40 1 10 0 0)
    SF-ADJUSTMENT _"Shadow opacity (0-100%)"            '(20 0 100 1 10 0 0)
    SF-TOGGLE     _"Draw border"                        TRUE
    SF-COLOR      _"Border color"                       "black"
    SF-ADJUSTMENT _"Border opacity (0-100%)"            '(25 0 100 1 10 0 0)
)

(script-fu-menu-register "script-fu-dx-gif" "<Image>/DX")
