(define (script-fu-dx-screenshotv3  image
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
                                    wavy-crop
                                    amplitude
                                    reverse-phase
                                    history-type)
(let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))

        (is-GIF (car (gimp-drawable-is-indexed drawable)))
        (user-selection-exists (car (gimp-selection-bounds image)))

        (border-layer 0)
        (background-layer (vector-ref (car (cdr (gimp-image-get-layers image)))
                                      (- (car (gimp-image-get-layers image)) 1)
                          )) ; The last layer
        (background-name (car (gimp-item-get-name background-layer)))
        (shadow-layer 0)
        (white-layer 0)

        (bordered-selection 0)
        (initial-selection 0)

        (sel-docked-left FALSE) (sel-docked-right FALSE)
        (sel-docked-top FALSE) (sel-docked-bottom FALSE)
        (num-of-docked 0)

        (x1 0) (y1 0) (x2 0) (y2 0) (x 0) (y 0) (phase 0) (points 0) (point 0)

    )
(gimp-context-push)

(define (layer-resize layer bounds) ; It was hard to find out how it actually works
    (gimp-layer-resize layer (- (list-ref bounds 2) (list-ref bounds 0))
                             (- (list-ref bounds 3) (list-ref bounds 1))
                             (- 0 (list-ref bounds 0))
                             (- 0 (list-ref bounds 1)) )
)

(if (= history-type 0) (gimp-image-undo-group-start image))
;BEGIN -----------------------------------------------------------
    (if (= history-type 1) (gimp-image-undo-group-start image))
        (if (= is-GIF TRUE) (gimp-image-convert-rgb image)) ; No opacity in INDEXED
        (gimp-image-set-active-layer image background-layer) ; The main layer
        (if (= user-selection-exists FALSE) (gimp-selection-all image))
        (set! initial-selection (car (gimp-selection-save image)))
    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= draw-border TRUE) (begin           ; --------- Border Start ---------
    (if (= history-type 1) (gimp-image-undo-group-start image))
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

            (set! image-width (car (gimp-image-width image)))   ; Updare image
            (set! image-height (car (gimp-image-height image))) ; dimensions
        ) (begin ; Else
            ; Simply expand the image and selection by 1px
            (gimp-image-resize image (+ image-width 2) (+ image-height 2) 1 1)
            (gimp-selection-all image)

            (set! image-width (+ image-width 2))   ; Update image
            (set! image-height (+ image-height 2)) ; demendions

            (set! wavy-crop FALSE) ; Disable wavy-cropper

            (set! sel-docked-left TRUE) (set! sel-docked-right  TRUE)
            (set! sel-docked-top  TRUE) (set! sel-docked-bottom TRUE)
        ))

        (set! bordered-selection (car (gimp-selection-save image)))

        (set! x1 (list-ref (gimp-selection-bounds image) 1))
        (set! y1 (list-ref (gimp-selection-bounds image) 2))
        (set! x2 (list-ref (gimp-selection-bounds image) 3))
        (set! y2 (list-ref (gimp-selection-bounds image) 4))

        (if (= wavy-crop TRUE) (begin
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
            (gimp-image-insert-layer image border-layer 0 ; no parent
                (- (car (gimp-image-get-layers image)) 1)) ; The pre-last layer

            (gimp-context-set-foreground border-color)
            (gimp-edit-bucket-fill-full border-layer FG-BUCKET-FILL NORMAL-MODE
                                        100   ; opacity
                                        0     ; threshold
                                        FALSE ; sample-merged
                                        TRUE  ; fill-transparent
                                        SELECT-CRITERION-COMPOSITE 0 0)
        ))
        (gimp-selection-load bordered-selection) ; Load border selection
        (layer-resize border-layer ; crop layer to bordered-selection
            (cdr (gimp-selection-bounds image)) )
        (gimp-image-remove-channel image bordered-selection) ; No need anymore
    (if (= history-type 1) (gimp-image-undo-group-end image))
    ))                                         ; --------- Border End ---------

    (if (= history-type 1) (gimp-image-undo-group-start image))
    (if (= wavy-crop TRUE) (begin          ; --------- Wavy crop Start ---------
        (if (< 2 num-of-docked) (gimp-message "Wawy crop from 3 or more sides is not recommended!"))
        (set! x1 (list-ref (gimp-selection-bounds image) 1))
        (set! y1 (list-ref (gimp-selection-bounds image) 2))
        (set! x2 (list-ref (gimp-selection-bounds image) 3))
        (set! y2 (list-ref (gimp-selection-bounds image) 4))
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
        ; Actual cropping
        (gimp-selection-load initial-selection)
        (gimp-image-select-polygon image CHANNEL-OP-ADD point points)
        (gimp-selection-invert image)
        (gimp-edit-clear background-layer)
        (gimp-selection-invert image)
        (plug-in-autocrop-layer RUN-NONINTERACTIVE image background-layer) ; May cause problems !
    ) (begin ; (= wavy-crop FALSE)               ; -------- Simple crop --------
        (gimp-image-crop image
                         (- (list-ref (cdr (gimp-selection-bounds image)) 2)
                            (list-ref (cdr (gimp-selection-bounds image)) 0))
                         (- (list-ref (cdr (gimp-selection-bounds image)) 3)
                            (list-ref (cdr (gimp-selection-bounds image)) 1))
                         (list-ref (cdr (gimp-selection-bounds image)) 0)
                         (list-ref (cdr (gimp-selection-bounds image)) 1))
        (gimp-selection-load initial-selection)
    ))
    (gimp-image-remove-channel image initial-selection)
    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= drop-shadow TRUE) (begin                 ; --------- Shadow ---------
    (if (= history-type 1) (gimp-image-undo-group-start image))

        (script-fu-drop-shadow  image background-layer
                                shadow-offset-x
                                shadow-offset-y
                                shadow-blur
                                shadow-color
                                shadow-opacity
                                1)    ; Allow resizing
        (set! shadow-layer (car (gimp-image-get-layer-by-name image
                                                              "Drop Shadow")))
        (gimp-item-set-name shadow-layer "Shadow")
        (gimp-image-lower-item-to-bottom image shadow-layer)
        (gimp-image-raise-item image shadow-layer) ; Border, Shadow, Background

    (if (= history-type 1) (gimp-image-undo-group-end image))
    ))                                          ; --------- Shadow End ---------

    (gimp-image-resize-to-layers image)

    (if (= history-type 1) (gimp-image-undo-group-start image))
        (gimp-selection-none image)
        (set! white-layer  (car (gimp-layer-new image
                                           (car (gimp-image-width image))
                                           (car (gimp-image-height image))
                                           RGBA-IMAGE "White" 100 NORMAL-MODE)))
        (gimp-drawable-fill white-layer WHITE-FILL)
        (gimp-image-insert-layer image white-layer 0
                                 (car (gimp-image-get-layers image))) ; To end
    (if (= history-type 1) (gimp-image-undo-group-end image))

    (if (= is-GIF TRUE) (begin ; --------- Merge layers ----------
        (if (= history-type 1) (gimp-image-undo-group-start image))
            (set! border-layer (car (gimp-image-merge-down image border-layer
                                                           EXPAND-AS-NECESSARY))
            ) ; 1. Border & Background -> Border
            (set! border-layer (car (gimp-image-merge-down image border-layer
                                                           EXPAND-AS-NECESSARY))
            ) ; 2. Border & Shadow -> Border
            (set! background-layer (car (gimp-image-merge-down image
                                                           border-layer
                                                           EXPAND-AS-NECESSARY))
            ) ; 3. Border & White -> Background
            (gimp-item-set-name background-layer
                                background-name) ; Important! Recovers duration
        (if (= history-type 1) (gimp-image-undo-group-end image))

        (gimp-image-convert-indexed image NO-DITHER MAKE-PALETTE
                                    255 TRUE TRUE "")
    ))
;END -----------------------------------------------------------
(if (= history-type 0) (gimp-image-undo-group-end image))
(gimp-displays-flush)
(gimp-context-pop)
)) ;let, define

(script-fu-register "script-fu-dx-screenshotv3"
    _"_Screenshot processing 2016..."
    _"Draws border, adds modern shadow and makes wavy crop."
    "Vladislav Glagolev <vladislav.glagolev@devexpress.com>, Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>"
    "DevExpress Inc."
    "7/15/2016"
    "RGB* INDEXED* GRAY*"
    SF-IMAGE      "Image"                               0
    SF-DRAWABLE   "Drawable"                            0
    SF-TOGGLE     _"Drop shadow"                        TRUE
    SF-COLOR      _"Shadow color"                       "black"
    SF-ADJUSTMENT _"Shadow offsrt X (-10..10 pixels)"   '(0 -10 10 1 10 0 )
    SF-ADJUSTMENT _"Shadow offsrt Y (-10..10 pixels)"   '(2 -10 10 1 10 0 )
    SF-ADJUSTMENT _"Shadow blur radius (0-40 pixels)"   '(6 0 40 1 10 0 0)
    SF-ADJUSTMENT _"Shadow opacity (0-100%)"            '(20 0 100 1 10 0 0)
    SF-TOGGLE     _"Draw border"                        TRUE
    SF-COLOR      _"Border color"                       "black"
    SF-ADJUSTMENT _"Border opacity (0-100%)"            '(20 0 100 1 10 0 0)
    SF-TOGGLE     _"Make wavy crop"                     TRUE
    SF-ADJUSTMENT _"Waves strength (0 - calm, 10 - tsunami)" '(3 0 10 1 0 0)
	SF-TOGGLE     _"Reverse wave phase"                 FALSE
    SF-OPTION     _"History type"                       '("One step" "Several steps" "Verbose")
)
(script-fu-menu-register "script-fu-dx-screenshotv3" "<Image>/DX")
