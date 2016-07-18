(define (script-fu-dx-screenshotv2 image
                               drawable
                               drop-shadow
                               shadow-distance
                               shadow-angle
                               shadow-blur
                               shadow-color
                               shadow-opacity
			       amplitude
			       reverse-phase
			       scale-percent
			       erase-top-corners
			       erase-bottom-corners
                               radius
			       flatten
			       background-color
	)
  (let* (
        (shadow-blur (max shadow-blur 0))
        (shadow-opacity (min shadow-opacity 100))
        (shadow-opacity (max shadow-opacity 0))
        (type (car (gimp-drawable-type-with-alpha drawable)))
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))
        (from-selection 0)
        (active-selection 0)
        (shadow-layer 0)
	(points 0)
	(point 0)
	(shadow-transl-y (* shadow-distance (sin (/ (- 180 shadow-angle) 57.32))))
	(shadow-transl-x (* shadow-distance (cos (/ (- 180 shadow-angle) 57.32))))
	(diam (* radius 2))
	(sel-exists FALSE)
        (x1 0)
	(y1 0)
	(x2 0)
	(y2 0)
	(x 0)
	(y 0)
	(phase 0)
        )

	(gimp-context-push)
	(gimp-image-set-active-layer image drawable)
	(gimp-image-undo-group-start image)
	(gimp-layer-add-alpha drawable)

;wave cropper prepare code begin
	(set! sel-exists (car (gimp-selection-bounds image)))
	 (if (= sel-exists TRUE)
		(begin
			(set! x1 (car (cdr (gimp-selection-bounds image))))
			(set! y1 (car (cdr (cdr (gimp-selection-bounds image)))))
			(set! x2 (car (cdr (cdr (cdr (gimp-selection-bounds image))))))
			(set! y2 (car (cdr (cdr (cdr (cdr (gimp-selection-bounds image)))))))
			(gimp-selection-none image) ;remove selection if one exists

			(set! points (cons-array (* (+ (* 2 (- x2 x1)) (* 2 (- y2 y1))) 2) 'double)) ; amount of points for points array

			(set! x x1)
			(set! y y1)
			(set! amplitude (/ amplitude 200))
			(if (= reverse-phase TRUE) (set! phase 3.1415))
			; moving from top-left to top-right
			(while (< x x2)
				(aset points point x) ;x
				(set! point (+ point 1))
				(if (> y1 0)
					(aset points point (+ y1 (* (* (- x2 x1) amplitude ) (sin (+ phase (* 6.2832 (/ (- x x1) (- x2 x1)))))))) ;y
				)
				(if (<= y1 0)
					(aset points point 0) ;y
				)
				(set! point (+ point 1))
				(set! x (+ x 1))
			)
			; moving from top-right to bottom-right
			(while (< y y2)
				(if (< x2 image-width)
					(aset points point (+ x2 (* (* (- y2 y1) amplitude) (sin (+ phase (* -6.2832 (/ (- y y1) (- y2 y1)))))))) ;x
				)
				(if (>= x2 image-width)
					(aset points point image-width) ;x
				)
				(set! point (+ point 1))
				(aset points point y) ;y
				(set! point (+ point 1))
				(set! y (+ y 1))
			)
			; moving from bottom-right to bottom-left
			(while (> x x1)
				(aset points point x) ;x
				(set! point (+ point 1))
				(if (< y2 image-height)
					(aset points point (+ y2 (* (* (- x2 x1) amplitude) (sin (+ phase (* 6.2832 (/ (- x x1) (- x2 x1)))))))) ;y
				)
				(if (>= y2 image-height)
					(aset points point image-height)
				)
				(set! point (+ point 1))
				(set! x (- x 1))
			)
			; moving from bottom-left to top-right
			(while (> y y1)
				(if (> x1 0)
					(aset points point (+ x1 (* (* (- y2 y1) amplitude) (sin (+ phase (* -6.2832 (/ (- y y1) (- y2 y1))))))))
				)
				(if (<= x1 0)
					(aset points point 0)
				)
				(set! point (+ point 1))
				(aset points point y)
				(set! point (+ point 1))
				(set! y (- y 1))
			)

			;(gimp-pencil drawable point points)
		)
	)
;wave cropper prepare code end

	(gimp-selection-none image) ;remove selection if one exists

;eraser code begin
	(if (= erase-top-corners TRUE)
		(begin
			(gimp-image-select-rectangle image CHANNEL-OP-ADD 0 0 radius radius)
			(gimp-image-select-ellipse image CHANNEL-OP-SUBTRACT 0 0 diam diam)
			(gimp-image-select-rectangle image CHANNEL-OP-ADD (- image-width radius) 0 radius radius)
			(gimp-image-select-ellipse image CHANNEL-OP-SUBTRACT (- image-width diam) 0 diam diam)
			(gimp-edit-clear drawable)
			(gimp-selection-none image)

		)
	)
	(if (= erase-bottom-corners TRUE)
		(begin
			(gimp-image-select-rectangle image CHANNEL-OP-ADD 0 (- image-height radius) radius radius)
			(gimp-image-select-ellipse image CHANNEL-OP-SUBTRACT 0 (- image-height diam) diam diam)
			(gimp-image-select-rectangle image CHANNEL-OP-ADD (- image-width radius) (- image-height radius) radius radius)
			(gimp-image-select-ellipse image CHANNEL-OP-SUBTRACT (- image-width diam) (- image-height diam) diam diam)
			(gimp-edit-clear drawable)
			(gimp-selection-none image)
		)
	)
;eraser code end

;crooper main code

	(if (= sel-exists TRUE)
		(begin
			;(gimp-pencil drawable point points)
			(gimp-image-select-polygon image CHANNEL-OP-ADD point points)
			(gimp-selection-invert image)
			(gimp-edit-clear drawable)
			(gimp-selection-none image)
			(plug-in-autocrop 1 image drawable)
		)
	)
;end of cropper main code

;resizer code begin

	(if (< scale-percent 100)
		(begin
			(set! image-width (car (gimp-image-width image)))   ; re-get wodth ang height
		        (set! image-height (car (gimp-image-height image))) ; for further resizing
			(plug-in-sharpen 1 image drawable 30) ; sharpen before scale
			(set! image-width (* (/ scale-percent 100) image-width))
			(set! image-height (* (/ scale-percent 100) image-height))
			(gimp-image-scale-full image image-width image-height 3) ;INTERPOLATION-LANCZOS (3)
			(plug-in-gauss 1 image drawable 0.3 0.3 0)
		)
	)
;resizer code end


;SHADOW CODE
	(if (= drop-shadow TRUE)
	(script-fu-drop-shadow image
				drawable
				shadow-transl-x
				shadow-transl-y
				shadow-blur
				shadow-color
				shadow-opacity
				TRUE)
	)
;SHADOW CODE END

;FLATTEN CODE
	(if (= flatten TRUE)
		(begin
			(gimp-context-set-background background-color)
			(gimp-image-flatten image)
			(gimp-image-convert-indexed image 0 0 256 FALSE FALSE "")
		)
	)
;END


	(gimp-image-undo-group-end image)
	(gimp-displays-flush)
	(gimp-context-pop)
  )
)

(script-fu-register "script-fu-dx-screenshotv2"
	_"_Screenshot processing..."
	_"Erases XP/Vista style window corners, makes wavy crop, adds shadow, flattens image and converts it to 256 indexed colors."
	"Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>"
	"Developer Express Inc."
	"2009/10/19"
	"RGB* GRAY*"
	SF-IMAGE      "Image"                                0
	SF-DRAWABLE   "Drawable"                             0
	SF-TOGGLE     _"Drop shadow"  	                     TRUE
	SF-ADJUSTMENT _"Shadow distance (0-20 pixels)"       '(5 0 20 1 10 0 )
	SF-ADJUSTMENT _"Shadow angle (0-360 degrees)"        '(120 0 360 1 10 0 0)
	SF-ADJUSTMENT _"Shadow blur radius (0-40 pixels)"      '(10 0 40 1 10 0 0)
	SF-COLOR      _"Shadow color"                        "black"
	SF-ADJUSTMENT _"Shadow opacity (0-100%)"             '(40 0 100 1 10 0 0)
	SF-ADJUSTMENT _"Waves strength (0 - calm, 10 - tsunami)"       '(3 0 10 1 0 0)
	SF-TOGGLE     _"Reverse wave phase"       				FALSE
	SF-ADJUSTMENT _"Reduce image size (50-100%)"              		'(100 50 100 1 10 0 0)
	SF-TOGGLE     _"Erase upper corners"  	             			FALSE
	SF-TOGGLE     _"Erase bottom corners"  	             			FALSE
	SF-ADJUSTMENT _"Corner radius (0-20 pixels)"             		'(7 0 20 1 10 0 0)
	SF-TOGGLE     _"Flatten image and convert to 256 indexed colors" 	FALSE
        SF-COLOR      _"Background color for flat image" 			"white"
)

(script-fu-menu-register "script-fu-dx-screenshotv2"
                         "<Image>/DX")
