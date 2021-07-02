; http://eeb.lu.lv/ftp/pub/Grafika/GIMP/programmeshana/BatchMode.html
; https://www.gimp.org/tutorials/Basic_Batch/
(define (new-layer-same-size
        image 
        drawable)
    (gimp-layer-new 
        image
        (car (gimp-drawable-width drawable))
        (car (gimp-drawable-height drawable))
        0 ; type
        "" ; name
        100 ; opacity
        0 ; mode
    )
)

(define (rotoscope 
        filename
        outputfile
        )
    (let* ( 
            ; define the variables
            (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
            (background (car (gimp-image-get-active-layer image)))
            (foreground (car (gimp-layer-copy background TRUE)))
            (hatch1 (car (new-layer-same-size image background)))
            (hatch1_mask (car (gimp-layer-copy background TRUE)))
            (hatch2 (car (new-layer-same-size image background)))
            (hatch2_mask (car (gimp-layer-copy background TRUE)))
        )

        ; insert the layers into the image
        (gimp-image-insert-layer image foreground 0 -1)
        (gimp-image-insert-layer image hatch1 0 -1)
        (gimp-image-insert-layer image hatch1_mask 0 -1)
        (gimp-image-insert-layer image hatch2 0 -1)
        (gimp-image-insert-layer image hatch2_mask 0 -1)

        ; create the background color with a wide oilify plus waterpixel
        (plug-in-oilify
            RUN-NONINTERACTIVE
            image ; unused
            background
            12
            1)
        (gegl-gegl
            background
            "waterpixels size=64")

        ; create the foreground:
        ;   oilify size 6 to simplify the image
        ;   edge detect to get the lines
        ;   desaturate
        ;   posturize 2 to threshold the colors
        ;   invert to turn the lines black
        ;   turn white to alpha
        ;   
        (plug-in-oilify
            RUN-NONINTERACTIVE
            image ; unused
            foreground
            8
            1)
        (plug-in-edge
            RUN-NONINTERACTIVE
            image ; unused 
            foreground
            5
            0
            0)
        (gimp-drawable-desaturate
            foreground
            1)
        (gimp-drawable-posterize
            foreground
            2)
        (gimp-invert 
            foreground)
        (plug-in-colortoalpha
            RUN-NONINTERACTIVE
            image ; unused 
            foreground
            '(255 255 255))

        ; initialize the hatch layers
        ;   fill with plasma noise
        ;   for some reason GEGL won't fill layer, so set active and trim
        ;   ... then resize to match image again
        ;   newsprint distort @ 45 degrees
        ;   mirror to second hatch layer
        (gegl-gegl
            hatch1
            "plasma")
        (gimp-image-set-active-layer
            image
            hatch1)
        (plug-in-autocrop-layer 
            RUN-NONINTERACTIVE
            image 
            hatch1)
        (gimp-layer-scale
            hatch1
            (car (gimp-drawable-width background))
            (car (gimp-drawable-height background))
            FALSE)
        ;(gimp-drawable-curves-spline
        ;    hatch1
        ;    0
        ;    4
        ;    #(0 50 255 225))
        (gimp-drawable-desaturate
            hatch1
            1)
        (plug-in-newsprint
            RUN-NONINTERACTIVE
            image ; unused 
            hatch1
            6 ; cell-width
            0 ; colorspace (0=GRAYSCALE)
            0 ; kpullout CKMY only
            55 ; angle
            1 ; lines
            0
            0
            0
            0
            0
            0
            1 ; oversampling
        )

        (gimp-file-save 
            RUN-NONINTERACTIVE 
            image 
            background 
            "background.png" 
            "background.png")

        (gimp-file-save 
            RUN-NONINTERACTIVE 
            image 
            foreground 
            "foreground.png" 
            "foreground.png")

        (gimp-file-save 
            RUN-NONINTERACTIVE 
            image 
            hatch1 
            "hatch1.png" 
            "hatch1.png")

        (gimp-file-save 
            RUN-NONINTERACTIVE 
            image 
            hatch2 
            "hatch2.png" 
            "hatch2.png")


        (let* (
                (new_image (car (gimp-image-duplicate image)))
                (drawable (car (gimp-image-merge-visible-layers new_image 1)))
            )
            (gimp-file-save 
                RUN-NONINTERACTIVE 
                new_image 
                drawable 
                outputfile 
                outputfile)
            (gimp-image-delete image)
            (gimp-image-delete new_image)
        )
    )
)