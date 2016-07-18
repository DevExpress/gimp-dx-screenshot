(define (script-fu-dx-highlightv2 image
                               drawable
				preserve-selection
                               draw-border
				border-shadow
				fill-area
				pred-color
				color
				opacity
	)

(let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))
	(new-layer 0)
	(current-layer drawable)
	(selection-channel)
        (x1 0)
	(y1 0)
	(x2 0)
	(y2 0)

        )
         (if (= (car (gimp-selection-bounds image)) FALSE) (gimp-message "Nothing to highlight - select an area and repeat."))
	 (if (= (or draw-border fill-area) FALSE) (gimp-message "Nothing to do - check 'Draw border' and/or 'Fill area'."))

	 (if (= (car (gimp-selection-bounds image)) TRUE)
		(begin

	(gimp-context-push)

	(gimp-image-undo-group-start image)
	(gimp-image-set-active-layer image drawable)


	(if (= pred-color 0) (set! color '(157 3 3)))
	(if (= pred-color 1) (set! color '(65 131 4)))
	(if (= pred-color 2) (set! color '(7 89 180)))

        (gimp-context-set-foreground color)

	(if (= preserve-selection TRUE)(set! selection-channel (car (gimp-selection-save image))))

        
 	(set! new-layer (car (gimp-layer-new image image-width image-height 0 "Highlight" 100 0)))
        (gimp-layer-add-alpha new-layer)
        (gimp-drawable-fill new-layer TRANSPARENT-FILL) 
	(gimp-image-insert-layer image new-layer 0 -1)
	(gimp-image-set-active-layer image new-layer)
	(set! current-layer new-layer)
        
	(if (= fill-area TRUE)
        	(gimp-edit-bucket-fill-full current-layer 0 0 opacity 0 FALSE TRUE 0 0 0)
	)

	(if (= draw-border  TRUE) (begin 
		(gimp-selection-border image 1)
        	(gimp-edit-bucket-fill-full current-layer 0 0 100 0 FALSE TRUE 0 0 0)
		(if (= border-shadow  TRUE) (begin
			(gimp-selection-none image)
			(script-fu-drop-shadow image current-layer 3 4 5 '(0 0 0) 40 0)
			(set! current-layer new-layer (car (gimp-image-merge-down image current-layer 0)))
		))
	))

	(gimp-selection-none image)

	(if (= preserve-selection TRUE) (begin
		(gimp-selection-load selection-channel)
		(gimp-image-remove-channel image selection-channel)
	))

        
	(plug-in-autocrop-layer 0 image current-layer)
	(gimp-image-set-active-layer image drawable)
	

	(gimp-image-undo-group-end image)
	(gimp-displays-flush)
	(gimp-context-pop)
		)
	)
  )
)

(script-fu-register "script-fu-dx-highlightv2"
	_"_Highlight selected area..."
	_"Highlightes the selected area."
	"Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>"
	"Developer Express Inc."
	"2010/06/25"
	"RGB* GRAY*"
	SF-IMAGE      "Image"                                0
	SF-DRAWABLE   "Drawable"                             0
	SF-TOGGLE	_"Preserve selection"			FALSE
	SF-TOGGLE	_"Draw border"				TRUE
	SF-TOGGLE	_"Border has shadow"			TRUE
	SF-TOGGLE	_"Fill area"				TRUE
	SF-OPTION      "Predefined Color"      '("DX Help Red (#9d0303)" "DX Help Green (#418C04)" "DX Help Blue (#0759B4)" "Custom Color")
	SF-COLOR      _"Custom Color"                        "#9d0303"
	SF-ADJUSTMENT _"Opacity (0-100%)"             '(10 0 100 1 10 0 0)


)

(script-fu-menu-register "script-fu-dx-highlightv2"
                         "<Image>/DX")
