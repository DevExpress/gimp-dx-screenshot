(define (script-fu-dx-screenshot2016  image
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
                                    border-position
                                    crop-type
                                    amplitude
                                    reverse-phase
                                    target
                                    layers-type
                                    history-type
                                    add-white)
(let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))

        (is-GIF (car (gimp-drawable-is-indexed drawable)))
        (user-selection-exists (car (gimp-selection-bounds image)))

        (border-layer 0)
        (target-layer (vector-ref (car (cdr (gimp-image-get-layers image)))
                                      (- (car (gimp-image-get-layers image)) 1)
                          )) ; The last layer
        (target-layer-name (car (gimp-item-get-name target-layer)))
        (shadow-layer 0)
        (white-layer 0)
        (group 0)

        (bordered-selection 0)
        (initial-selection 0)

        (sel-docked-left FALSE) (sel-docked-right FALSE)
        (sel-docked-top FALSE) (sel-docked-bottom FALSE)
        (num-of-docked 0)

        (x1 0) (y1 0) (x2 0) (y2 0) (x 0) (y 0) (phase 0) (points 0) (point 0)

    )
(gimp-context-push)
(if (= history-type 0) (gimp-image-undo-group-start image))
;BEGIN -----------------------------------------------------------
    (if (= history-type 1) (gimp-image-undo-group-start image)) ; Prepare stuff
        (if (= is-GIF TRUE) (begin
            (gimp-image-convert-rgb image) ; No opacity in INDEXED
            (set! layers-type 2))) ; Merge layers
        (if (= user-selection-exists FALSE) (begin
            (if (= crop-type 0) (set! crop-type 1)) ; Disable wavy crop
            (if (= target 0) ; Full image
                (gimp-selection-all image)
                (begin  ; Current layer
                    (gimp-image-select-rectangle image CHANNEL-OP-REPLACE
                                         (car (gimp-drawable-offsets drawable))
                                         (cadr (gimp-drawable-offsets drawable))
                                         (car (gimp-drawable-width drawable))
                                         (car (gimp-drawable-height drawable)))
                    (set! user-selection-exists TRUE)
                    (set! target-layer drawable)
                    (set! target-layer-name
                                        (car (gimp-item-get-name target-layer)))
                )
            )
        ))
        (if (gimp-drawable-has-alpha target-layer)
                                (gimp-layer-add-alpha target-layer))
        (gimp-image-set-active-layer image target-layer) ; The main layer
        (set! initial-selection (car (gimp-selection-save image)))
    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= history-type 1) (gimp-image-undo-group-start image)) ; Prepare layers
        (if (= layers-type 0) ; doesn't work if target-layer is in the middle
            (gimp-image-lower-item-to-bottom image target-layer))
        (if (= layers-type 1) (begin ; Group
            (set! group (car (gimp-layer-group-new image)))
            (gimp-item-set-name group
                                (string-append target-layer-name " decoration"))
            (gimp-image-insert-layer image group 0 ; no parent
                (+ (car (gimp-image-get-item-position image target-layer))
                (if (= crop-type 2) 1 0)) ) ; If non-rect layer, the shadow is
                                            ; filled and should be behind
        ))
    (if (= history-type 1) (gimp-image-undo-group-end image))

    ; Check margins for border
    (if (= user-selection-exists TRUE) (begin
        (if (= (list-ref (gimp-selection-bounds image) 1) 0) (begin
            (set! sel-docked-left TRUE)
            (set! num-of-docked (+ num-of-docked 1)) ))
        (if (= (list-ref (gimp-selection-bounds image) 2) 0) (begin
            (set! sel-docked-top TRUE)
            (set! num-of-docked (+ num-of-docked 1)) ))
        (if (= (list-ref (gimp-selection-bounds image) 3) image-width) (begin
            (set! sel-docked-right TRUE)
            (set! num-of-docked (+ num-of-docked 1)) ))
        (if (= (list-ref (gimp-selection-bounds image) 4) image-height) (begin
            (set! sel-docked-bottom TRUE)
            (set! num-of-docked (+ num-of-docked 1)) ))

        ; If the entire image is selected, assume no selection
        (if (= num-of-docked 4) (set! user-selection-exists FALSE))
    ))

    (if (and (= draw-border TRUE) (= crop-type 2)) (begin
        (gimp-message "Non-rectangular borders are not supported")
        (set! draw-border FALSE) ))

    (if (= draw-border TRUE) (begin           ; --------- Border Start ---------
    (if (= history-type 1) (gimp-image-undo-group-start image))

        (if (= border-position 1) ; Outer border
            ; Fix margins for border
            (if (= user-selection-exists TRUE) (begin
                ; Add required margins for border
                (if (= sel-docked-left TRUE)
                    (gimp-image-resize  image
                                        (+ (car (gimp-image-width  image)) 1)
                                           (car (gimp-image-height image))
                                        1 0) )
                (if (= sel-docked-right TRUE)
                    (gimp-image-resize  image
                                        (+ (car (gimp-image-width  image)) 1)
                                           (car (gimp-image-height image))
                                        0 0) )
                (if (= sel-docked-top TRUE)
                    (gimp-image-resize  image
                                           (car (gimp-image-width  image))
                                        (+ (car (gimp-image-height image)) 1)
                                        0 1) )
                (if (= sel-docked-bottom TRUE)
                    (gimp-image-resize  image
                                           (car (gimp-image-width  image))
                                        (+ (car (gimp-image-height image)) 1)
                                        0 0) )
                (gimp-image-select-rectangle image CHANNEL-OP-REPLACE
                        (- (list-ref (gimp-selection-bounds image) 1) 1)   ;x0
                        (- (list-ref (gimp-selection-bounds image) 2) 1)   ;y0
                        (+ (- (list-ref (gimp-selection-bounds image) 3)
                              (list-ref (gimp-selection-bounds image) 1)) 2) ;w
                        (+ (- (list-ref (gimp-selection-bounds image) 4)
                              (list-ref (gimp-selection-bounds image) 2)) 2) ;h
                ) ; Expand selection by 1px on each side

                (set! image-width (car (gimp-image-width image)))   ; Updare img
                (set! image-height (car (gimp-image-height image))) ; dimensions
            ) (begin ; Else
                ; Simply expand the image and selection by 1px
                (gimp-image-resize image (+ image-width 2)
                                         (+ image-height 2) 1 1)
                (gimp-selection-all image)

                (set! image-width (+ image-width 2))   ; Update image
                (set! image-height (+ image-height 2)) ; demendions

                (set! sel-docked-left TRUE) (set! sel-docked-right  TRUE)
                (set! sel-docked-top  TRUE) (set! sel-docked-bottom TRUE)
            )))

        (set! bordered-selection (car (gimp-selection-save image)))

        (set! x1 (list-ref (gimp-selection-bounds image) 1))
        (set! y1 (list-ref (gimp-selection-bounds image) 2))
        (set! x2 (list-ref (gimp-selection-bounds image) 3))
        (set! y2 (list-ref (gimp-selection-bounds image) 4))

        (if (= crop-type 0) (begin ; wavy-crop
            ; Add margins to only docked sides
            (if (= sel-docked-left   TRUE) (set! x1 (+ x1 1)))
            (if (= sel-docked-right  TRUE) (set! x2 (- x2 1)))
            (if (= sel-docked-top    TRUE) (set! y1 (+ y1 1)))
            (if (= sel-docked-bottom TRUE) (set! y2 (- y2 1)))
        ) (begin ; Else
            (set! x1 (+ x1 1)) (set! x2 (- x2 1)) ; Add all
            (set! y1 (+ y1 1)) (set! y2 (- y2 1)) ; margins
        ))

        (gimp-image-select-rectangle image ; Our cool gimp-selection-border
                                CHANNEL-OP-SUBTRACT x1 y1 (- x2 x1) (- y2 y1))

        ; Selection may disappear (if (= num-of-docked 0))
        (if (= (car (gimp-selection-bounds image)) TRUE) (begin
            (set! border-layer (car (gimp-layer-new image image-width
                                                image-height
                                                RGBA-IMAGE "Border"
                                                border-opacity NORMAL-MODE)))
            (gimp-drawable-fill border-layer TRANSPARENT-FILL)

            (if (= layers-type 1) ; Group
                (gimp-image-insert-layer image border-layer group 0)
            ; else
                (gimp-image-insert-layer image border-layer 0 ; no parent
                (car (gimp-image-get-item-position image target-layer)) ))
            (gimp-context-set-foreground border-color)
            (gimp-edit-bucket-fill-full border-layer FG-BUCKET-FILL NORMAL-MODE
                                        100   ; opacity
                                        0     ; threshold
                                        FALSE ; sample-merged
                                        TRUE  ; fill-transparent
                                        SELECT-CRITERION-COMPOSITE 0 0)

            (gimp-layer-resize border-layer ;crop border-layer to bordered-selection
                (-  (list-ref (cdr (gimp-selection-bounds image)) 2)
                    (list-ref (cdr (gimp-selection-bounds image)) 0) )
                (-  (list-ref (cdr (gimp-selection-bounds image)) 3)
                    (list-ref (cdr (gimp-selection-bounds image)) 1) )
                (- 0 (list-ref (cdr (gimp-selection-bounds image)) 0))
                (- 0 (list-ref (cdr (gimp-selection-bounds image)) 1)) )
        ))
    (if (= history-type 1) (gimp-image-undo-group-end image)))
        (set! bordered-selection (car (gimp-selection-save image))) ; else
    )                                           ; --------- Border End ---------

    (if (= history-type 1) (gimp-image-undo-group-start image))
    (if (= crop-type 0) (begin             ; --------- Wavy crop Start ---------
        (gimp-selection-load initial-selection)
        (if (< num-of-docked 2)
            (gimp-message (string-append
                "Wawy crop from 3 or more sides is not recommended!\n"
                "Wavy-cropped " (number->string (- 4 num-of-docked)) " sides")))
        (set! x1 (list-ref (gimp-selection-bounds image) 1))
        (set! y1 (list-ref (gimp-selection-bounds image) 2))
        (set! x2 (list-ref (gimp-selection-bounds image) 3))
        (set! y2 (list-ref (gimp-selection-bounds image) 4))

        (set! points (cons-array (* (+ (* 2 (- x2 x1)) (* 2 (- y2 y1))) 2) 'double)) ; amount of points for points array

        (set! x x1)
        (set! y y1)
        (set! amplitude (/ amplitude 200))
        (if (= reverse-phase TRUE) (set! phase 3.1415))

        ; Top border
        (while (< x x2)
            (aset points point x) ;x
            (set! point (+ point 1))
            (if (= sel-docked-top TRUE)
                (aset points point y1) ;y
            ; else
                (aset points point (+ (- 0 1) y1 (* (* (- x2 x1) amplitude ) (sin (+ phase (* 6.2832 (/ (- x x1) (- x2 x1)))))))) ;y
            )
            (set! point (+ point 1))
            (set! x (+ x 1))
        )
        ; Right border
        (while (< y y2)
            (if (= sel-docked-right TRUE)
                (aset points point x2) ;x
            ; else
                (aset points point (+ 1 x2 (* (* (- y2 y1) amplitude) (sin (+ phase (* -6.2832 (/ (- y y1) (- y2 y1)))))))) ;x
            )
            (set! point (+ point 1))
            (aset points point y) ;y
            (set! point (+ point 1))
            (set! y (+ y 1))
        )
        ; Bottom border
        (while (> x x1)
            (aset points point x) ;x
            (set! point (+ point 1))
            (if (= sel-docked-bottom TRUE)
                (aset points point y2)
            ; else
                (aset points point (+ 1 y2 (* (* (- x2 x1) amplitude) (sin (+ phase (* 6.2832 (/ (- x x1) (- x2 x1)))))))) ;y
            )
            (set! point (+ point 1))
            (set! x (- x 1))
        )
        ; Left border
        (while (> y y1)
            (if (= sel-docked-left TRUE)
                (aset points point x1)
            ; else
                (aset points point (+ (- 0 1) x1 (* (* (- y2 y1) amplitude) (sin (+ phase (* -6.2832 (/ (- y y1) (- y2 y1))))))))
            )
            (set! point (+ point 1))
            (aset points point y)
            (set! point (+ point 1))
            (set! y (- y 1))
        )
        ; Actual cropping
        (gimp-image-select-polygon image CHANNEL-OP-REPLACE point points)
        (gimp-selection-invert image)
        (gimp-edit-clear target-layer) ; clears the area
        (gimp-selection-invert image)
        (gimp-image-set-active-layer image target-layer) ; Obligatory !!!!
        (plug-in-autocrop-layer RUN-NONINTERACTIVE image target-layer)
    ))

    (if (= crop-type 1)(begin                    ; -------- Simple crop --------
        (gimp-selection-load bordered-selection)
        (gimp-image-crop image
                         (- (list-ref (cdr (gimp-selection-bounds image)) 2)
                            (list-ref (cdr (gimp-selection-bounds image)) 0))
                         (- (list-ref (cdr (gimp-selection-bounds image)) 3)
                            (list-ref (cdr (gimp-selection-bounds image)) 1))
                         (list-ref (cdr (gimp-selection-bounds image)) 0)
                         (list-ref (cdr (gimp-selection-bounds image)) 1))
        (gimp-selection-load initial-selection) ; moved
    ))
    (gimp-image-remove-channel image bordered-selection)
    (gimp-image-remove-channel image initial-selection)
    (if (= crop-type 2) (gimp-selection-none image)) ; For complex selections

    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= drop-shadow TRUE) (begin                 ; --------- Shadow ---------
    (if (= history-type 1) (gimp-image-undo-group-start image))
        (gimp-image-set-active-layer image target-layer) ; Obligatory !!!!
        (script-fu-drop-shadow  image target-layer
                                shadow-offset-x
                                shadow-offset-y
                                shadow-blur
                                shadow-color
                                shadow-opacity
                                1)    ; Allow resizing
        (set! shadow-layer (car (gimp-image-get-layer-by-name image
                                                              "Drop Shadow")))
        (gimp-item-set-name shadow-layer "Shadow")
        (if (= layers-type 1) ; Group
            (gimp-image-reorder-item image shadow-layer group 0)
            ; else
            (gimp-image-reorder-item image shadow-layer 0
                (+ (car (gimp-image-get-item-position image target-layer)) 1) ))

    (if (= history-type 1) (gimp-image-undo-group-end image))
    ))                                          ; --------- Shadow End ---------

    (if (< crop-type 2) (gimp-image-resize-to-layers image))

    (if (= history-type 1) (gimp-image-undo-group-start image))
        (gimp-selection-none image)
        (if (= add-white TRUE)(begin
            (set! white-layer ; Renew
                (car (gimp-image-get-layer-by-name image "White")))
            (if (>= white-layer 0) (gimp-image-remove-layer image white-layer))
            (set! white-layer  (car (gimp-layer-new image
                                           (car (gimp-image-width image))
                                           (car (gimp-image-height image))
                                           RGBA-IMAGE "White" 100 NORMAL-MODE)))
            (gimp-drawable-fill white-layer WHITE-FILL)
            (gimp-image-insert-layer image white-layer 0
                                (car (gimp-image-get-layers image))) ; To end
        ))
    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= layers-type 2) (begin ; --------- Merge layers ----------
        (if (= history-type 1) (gimp-image-undo-group-start image))
            (if (= draw-border TRUE)
                (set! target-layer (car (gimp-image-merge-down image
                                                        border-layer
                                                        EXPAND-AS-NECESSARY)))
            ) ; 1. If border exists, Border & Target -> Target

            (set! target-layer (car (gimp-image-merge-down image target-layer
                                                           EXPAND-AS-NECESSARY))
            ) ; 2. Target & Shadow -> Target
            (if (= add-white TRUE)
                (set! target-layer (car (gimp-image-merge-down image
                                                       target-layer
                                                       EXPAND-AS-NECESSARY)))
            ) ; 3. Target & White -> Target
            (gimp-item-set-name target-layer
                                target-layer-name) ;Important! Recovers duration
        (if (= history-type 1) (gimp-image-undo-group-end image))
    ))

    (if (= is-GIF TRUE)(gimp-image-convert-indexed image NO-DITHER
                            MAKE-PALETTE 255 TRUE TRUE ""))
;END -----------------------------------------------------------
(if (= history-type 0) (gimp-image-undo-group-end image))
(gimp-displays-flush)
(gimp-context-pop)
)) ;let, define

(script-fu-register "script-fu-dx-screenshot2016"
    _"_Screenshot processing 2016..."
    _"Draws border, adds modern shadow and makes wavy crop. Even in GIFs."
    "Vladislav Glagolev <vladislav.glagolev@devexpress.com>, Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>"
    "DevExpress Inc."
    "9/21/2016"
    "RGB* INDEXED* GRAY*"
    SF-IMAGE      "Image"                                   0
    SF-DRAWABLE   "Drawable"                                0
    SF-TOGGLE     _"Drop shadow"                            TRUE
    SF-COLOR      _"Shadow color"                           "black"
    SF-ADJUSTMENT _"Shadow offsrt X (-10..10 pixels)"       '(0 -10 10 1 10 0)
    SF-ADJUSTMENT _"Shadow offsrt Y (-10..10 pixels)"       '(2 -10 10 1 10 0)
    SF-ADJUSTMENT _"Shadow blur radius (0..40 pixels)"      '(6 0 40 1 10 0 0)
    SF-ADJUSTMENT _"Shadow opacity (0-100%)"                '(22 0 100 1 10 0 0)
    SF-TOGGLE     _"Draw border (set if not already exists)" FALSE
    SF-COLOR      _"Border color"                           "black"
    SF-ADJUSTMENT _"Border opacity (0-100%)"                '(12 0 100 1 10 0 0)
    SF-OPTION     _"Border position"                        '("Inner" "Outer")
    SF-OPTION     _"Crop type"       '("Wavy crop" "Rectangular crop" "No crop (non-rect. layer)")
    SF-ADJUSTMENT _"Waves strength (0-calm, 10-tsunami)"    '(3 0 10 1 0 0)
	SF-TOGGLE     _"Reverse wave phase"                     FALSE
    SF-OPTION     _"Target (if no selection)"    '("Full image" "Current layer")
    SF-OPTION     _"Layer arrangement type" '("Separate layers" "Group" "Merge")
    SF-OPTION     _"History type"           '("One step" "Several steps" "Verbose")
    SF-TOGGLE     _"Add white layer"                        TRUE
)
(script-fu-menu-register "script-fu-dx-screenshot2016" "<Image>/DX")
