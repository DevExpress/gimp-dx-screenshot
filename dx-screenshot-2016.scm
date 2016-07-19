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
)

(let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))

        (is-GIF (car (gimp-drawable-is-indexed drawable)))
        (selection-exists (car (gimp-selection-bounds image)))

        (border-layer 0)
        (background-layer (vector-ref (car (cdr (gimp-image-get-layers image)))
                                      (- (car (gimp-image-get-layers image)) 1)
                          )) ; The last layer
        (background-name (car (gimp-item-get-name background-layer)))
        (shadow-layer 0)
        (white-layer 0)

        (bordered-selection 0)
        (user-selection 0)

        (sel-docked-left FALSE)
        (sel-docked-right FALSE)
        (sel-docked-top FALSE)
        (sel-docked-bottom FALSE)
    )

  (gimp-context-push)
;BEGIN -----------------------------------------------------------
    (if (= is-GIF TRUE) (gimp-image-convert-rgb image)) ; No opacity in INDEXED
    (gimp-image-set-active-layer image background-layer) ; The main layer
    (set! user-selection (car (gimp-selection-save image))) ; Save selection

    (if (= draw-border TRUE) (begin           ; --------- Border Start ---------
    (gimp-image-undo-group-start image)

        ; Selection fix
        (if (= selection-exists FALSE) (begin
            (gimp-image-resize image (+ image-width 2) (+ image-height 2) 1 1)

            (set! image-width (+ image-width 2))   ; Update image
            (set! image-height (+ image-height 2)) ; demendions

            (gimp-selection-all image)
        ) (begin  ; Else (selection exists)
            ; Check margins for border
            (if (= (list-ref (gimp-selection-bounds image) 1) 0)
                (set! sel-docked-left TRUE)
            ) (if (= (list-ref (gimp-selection-bounds image) 2) 0)
                (set! sel-docked-top TRUE)
            ) (if (= (list-ref (gimp-selection-bounds image) 3) image-width)
                (set! sel-docked-right TRUE)
            ) (if (= (list-ref (gimp-selection-bounds image) 4) image-height)
                (set! sel-docked-bottom TRUE)
            )
            ; Add required margins for border
            (if (= sel-docked-left TRUE)
                (gimp-image-resize  image
                                    (+ (car (gimp-image-width  image)) 1)
                                       (car (gimp-image-height image))
                                    1 0)
            ) (if (= sel-docked-right TRUE)
                (gimp-image-resize  image
                                    (+ (car (gimp-image-width  image)) 1)
                                       (car (gimp-image-height image))
                                    0 0)
            ) (if (= sel-docked-top TRUE)
                (gimp-image-resize  image
                                       (car (gimp-image-width  image))
                                    (+ (car (gimp-image-height image)) 1)
                                    0 1)
            ) (if (= sel-docked-bottom TRUE)
                (gimp-image-resize  image
                                       (car (gimp-image-width  image))
                                    (+ (car (gimp-image-height image)) 1)
                                    0 0)
            )
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
        ))

        (set! bordered-selection (car (gimp-selection-save image)))

        (set! border-layer (car (gimp-layer-new image
                                                image-width
                                                image-height
                                                RGBA-IMAGE
                                                "Border"
                                                border-opacity
                                                NORMAL-MODE
        )                  )    )
        (gimp-drawable-fill border-layer TRANSPARENT-FILL)
        (gimp-image-insert-layer image border-layer 0 ; no parent
                (- (car (gimp-image-get-layers image)) 1)) ; The pre-last layer
        (gimp-context-set-foreground border-color)

        (gimp-image-select-rectangle image CHANNEL-OP-SUBTRACT
                        (+ (list-ref (gimp-selection-bounds image) 1) 1)  ;x0
                        (+ (list-ref (gimp-selection-bounds image) 2) 1)  ;y0
                        (-  (list-ref (gimp-selection-bounds image) 3)
                            (list-ref (gimp-selection-bounds image) 1) 2) ;w
                        (-  (list-ref (gimp-selection-bounds image) 4)
                            (list-ref (gimp-selection-bounds image) 2) 2) ;h
        ) ; (gimp-selection-border sucks)

        (gimp-edit-bucket-fill-full border-layer
                                    FG-BUCKET-FILL
                                    NORMAL-MODE
                                    100   ; opacity
                                    0     ; threshold
                                    FALSE ; sample-merged
                                    TRUE  ; fill-transparent
                                    SELECT-CRITERION-COMPOSITE
                                    0 0
        )
        (gimp-selection-load bordered-selection) ; Load border selection
        (gimp-image-set-active-layer image background-layer)
    (gimp-image-undo-group-end image)
    ))                                         ; --------- Border End ---------


    (gimp-image-crop image ; Crop to selection
                     (- (list-ref (cdr (gimp-selection-bounds image)) 2)
                        (list-ref (cdr (gimp-selection-bounds image)) 0))
                     (- (list-ref (cdr (gimp-selection-bounds image)) 3)
                        (list-ref (cdr (gimp-selection-bounds image)) 1))
                     (list-ref (cdr (gimp-selection-bounds image)) 0)
                     (list-ref (cdr (gimp-selection-bounds image)) 1))

    (gimp-selection-load user-selection) ; Recover selection

    (if (= drop-shadow TRUE) (begin                 ; --------- Shadow ---------
        (gimp-image-undo-group-start image)

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

        (gimp-image-undo-group-end image)
    ))                                          ; --------- Shadow End ---------

    (gimp-image-undo-group-start image)
        (gimp-selection-none image)
        (set! white-layer  (car (gimp-layer-new image
                                           (car (gimp-image-width image))
                                           (car (gimp-image-height image))
                                           RGBA-IMAGE "White" 100 NORMAL-MODE)))
        (gimp-drawable-fill white-layer WHITE-FILL)
        (gimp-image-insert-layer image white-layer 0
                                 (car (gimp-image-get-layers image))) ; To end
        (gimp-image-remove-channel image user-selection)     ; Clean up
        (gimp-image-remove-channel image bordered-selection) ; channels
    (gimp-image-undo-group-end image)

    (if (= is-GIF TRUE) (begin
        (gimp-image-undo-group-start image) ; --------- Merge layers ----------
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
        (gimp-image-undo-group-end image)

        (gimp-image-convert-indexed image NO-DITHER MAKE-PALETTE
                                    255 TRUE TRUE ""))
    )
;END -----------------------------------------------------------
  (gimp-displays-flush)
  (gimp-context-pop)
) ;let
) ;define



(script-fu-register "script-fu-dx-screenshotv3"
    _"_Screenshot processing 2016..."
    _"Draws border, adds modern shadow and makes wavy crop."
    "Konstantin Beliakov <Konstantin.Belyakov@devexpress.com>, Vladislav Glagolev <vladislav.glagolev@devexpress.com>"
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
)
(script-fu-menu-register "script-fu-dx-screenshotv3" "<Image>/DX")
