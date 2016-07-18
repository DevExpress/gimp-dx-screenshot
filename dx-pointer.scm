(define (script-fu-dx-pointerv2 image
                               drawable
                               drop-shadow
			       pointer-type
                               shadow-distance
                               shadow-angle
                               shadow-blur
                               shadow-color
                               shadow-opacity
			       motion
			       motion-separate-layers
			       motion-length
			       motion-angle	
			       reflections
				click
	)
  (let* (
        (shadow-blur (max shadow-blur 0))
        (shadow-opacity (min shadow-opacity 100))
        (shadow-opacity (max shadow-opacity 0))
;        (type (car (gimp-drawable-type-with-alpha drawable)))
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))
	(offset-x (/ image-width 2))
	(offset-y (/ image-height 2))
	(opacity 100)
	(opacity-decrement (/ opacity reflections))
	(motion-step (/ motion-length (- reflections 1)))
	(reflections-counter reflections)
	(layer (gimp-image-get-active-layer image))
	(shadow-transl-y (* shadow-distance (sin (/ (- 180 shadow-angle) 57.32))))
	(shadow-transl-x (* shadow-distance (cos (/ (- 180 shadow-angle) 57.32))))
        )

	(gimp-context-push)
	(gimp-image-set-active-layer image drawable)
	(gimp-image-undo-group-start image)

	(if (= motion FALSE) (set! motion-length 0))

	(if (= click TRUE)
		(begin
		(set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-click-effect.png"))))
		(gimp-layer-set-offsets layer (- (+ offset-x (* (/ motion-length 2) (sin (/ (- motion-angle 90) 57.2958)))) 7) (- (+ offset-y (* (/ motion-length 2) (cos (/ (- motion-angle 90) 57.2958)))) 7))
 		(gimp-image-insert-layer image layer 0 -1)
                (gimp-item-set-name (car (gimp-image-get-active-drawable image)) "Pointer")
		)
	)

	(if (= motion TRUE)
		(begin	
			(set! offset-x (- offset-x (* (/ motion-length 2) (sin (/ (- motion-angle 90) 57.2958)))))
			(set! offset-y (- offset-y (* (/ motion-length 2) (cos (/ (- motion-angle 90) 57.2958)))))
		)
	)

	

	(while (> reflections-counter 0)
		(if (= pointer-type 0)
		        (set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-normal-select.png"))))
		)
		(if (= pointer-type 1)
		        (set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-drag-and-drop.png"))))
		)
		(if (= pointer-type 2)
		        (set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-drag-and-drop-move.png"))))
		)
		(if (= pointer-type 3)
		        (set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-link-select.png"))))
		)

		(if (= pointer-type 4)
		        (set! layer (car (gimp-file-load-layer 0 image (string-append gimp-data-directory "/scripts/images/pointer-editor.png"))))
		)

	        (gimp-layer-set-offsets layer offset-x offset-y)
		(gimp-image-insert-layer image layer 0 -1)
		;(gimp-image-resize-to-layers image)
		(if (= drop-shadow TRUE)
		(begin
			(script-fu-drop-shadow image 
					;(car (gimp-image-get-active-layer image))
					layer
					shadow-transl-x
					shadow-transl-y
					shadow-blur
					shadow-color
					shadow-opacity
					TRUE)
				
			(gimp-image-merge-down image 
				;(car (gimp-image-get-active-layer image))
				layer
				 0)
		)
		)
		(gimp-layer-set-opacity (car (gimp-image-get-active-layer image)) opacity)
		(gimp-item-set-name (car (gimp-image-get-active-drawable image)) "Pointer")
 		(set! reflections-counter (- reflections-counter 1))
		(set! offset-x (+ offset-x (* motion-step (sin (/ (- motion-angle 90) 57.2958)))))
		(set! offset-y (+ offset-y (* motion-step (cos (/ (- motion-angle 90) 57.2958)))))
		(set! opacity (- opacity opacity-decrement))
		(if (= motion FALSE) (set! reflections-counter 0))

		
	 )
	(if (and (= motion TRUE) (= motion-separate-layers FALSE))
		(while (< reflections-counter (- reflections 1))
			(begin
				(gimp-image-merge-down image (car (gimp-image-get-active-layer image)) 0)
		 		(set! reflections-counter (+ reflections-counter 1))
			)
		)
	)

	(if (= click TRUE) (gimp-image-merge-down image (car (gimp-image-get-active-layer image)) 0))

	(gimp-image-undo-group-end image)
	(gimp-displays-flush)
	(gimp-context-pop)
)
)
(script-fu-register "script-fu-dx-pointerv2"
	_"_Add pointer"
	_"Adds pointer to image and applies effects to it."
	"Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>"
	"Developer Express Inc."
	"2010/07/22"
	"RGB* GRAY*"
	SF-IMAGE      "Image"                                0
	SF-DRAWABLE   "Drawable"                             0
	SF-TOGGLE     _"Add pointer shadow"  	              FALSE
	SF-OPTION      "Pointer type"      '("Normal pointer" "Drag&Drop" "Drag&Drop/Move" "Link select" "Editor")
	SF-ADJUSTMENT _"Shadow distance (0-20 pixels)"       '(3 0 10 1 10 0 )
	SF-ADJUSTMENT _"Shadow angle (0-360 degrees)"        '(120 0 360 1 10 0 0)
	SF-ADJUSTMENT _"Shadow blur radius (0-40 pixels)"      '(3 0 20 1 10 0 0)
	SF-COLOR      _"Shadow color"                        "black"
	SF-ADJUSTMENT _"Shadow opacity (0-100%)"             '(45 0 100 1 10 0 0)
	SF-TOGGLE     _"Motion effect" 	                     FALSE
	SF-TOGGLE     _"Create separate layers with motion reflections" FALSE
	SF-ADJUSTMENT _"Motion length (0-600 pixels)"       	     '(200 0 600 1 10 0 )
	SF-ADJUSTMENT _"Motion angle (-180-+180 degrees)"        '(15 -180 180 1 10 0 0)
	SF-ADJUSTMENT _"Number of reflections (2-10)"      	     '(4 0 10 1 10 0 )
	SF-TOGGLE     _"Click effect" 	                     FALSE
)

(script-fu-menu-register "script-fu-dx-pointerv2"
                         "<Image>/DX")
