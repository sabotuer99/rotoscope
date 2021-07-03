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

(define (generate-hatching
         image
         drawable
         background
         angle
         mask-threshold)

        ; initialize the hatch layers
        ;   fill with plasma noise
        ;   for some reason GEGL won't fill layer, so set active and trim
        ;   ... then resize to match image again
        ;   guassian blur to evan out the lines
        ;   newsprint distort
        (gegl-gegl
            drawable
            "plasma")
        (gimp-image-set-active-layer
            image
            drawable)
        (plug-in-autocrop-layer 
            RUN-NONINTERACTIVE
            image 
            drawable)
        (gimp-layer-scale
            drawable
            (car (gimp-drawable-width background))
            (car (gimp-drawable-height background))
            FALSE)
        (gimp-drawable-desaturate
            drawable
            1)
        (plug-in-gauss
            RUN-NONINTERACTIVE
            image ; unused 
            drawable
            15.5
            15.5
            0)
        (plug-in-newsprint
            RUN-NONINTERACTIVE
            image ; unused 
            drawable
            6 ; cell-width
            0 ; colorspace (0=GRAYSCALE)
            0 ; kpullout CKMY only
            angle ; angle
            1 ; lines
            0
            0
            0
            0
            0
            0
            3 ; oversampling
        )
        (plug-in-ripple
            RUN-NONINTERACTIVE
            image ; unused 
            drawable
            100 ; period
            3 ; amplitude
            0 ; orientation
            1 ; edges WRAP
            1 ; waveform SINE
            TRUE ; antialias
            TRUE)  ; tileable

        ; generate and apply the mask
        (let* (
                (mask (car (gimp-layer-copy background TRUE)))
            )

            (gimp-image-insert-layer image mask 0 -1)
            ; oilify 8
            ; desaturate
            ; posterize 7
            ; threshold
            ; black to alpha
            ; guassian blur 5.5
            (plug-in-oilify
                RUN-NONINTERACTIVE
                image ; unused
                mask
                8
                1)
            (gimp-drawable-desaturate
                mask
                1)
            (gimp-drawable-posterize
                mask
                7)
            (gimp-drawable-threshold
                mask
                0 ; channel VALUE
                mask-threshold
                1.0)
            (plug-in-colortoalpha
                RUN-NONINTERACTIVE
                image ; unused 
                mask
                '(0 0 0))
            (plug-in-gauss
                RUN-NONINTERACTIVE
                image ; unused 
                mask
                5.5
                5.5
                0)

            (gimp-image-raise-item-to-top image drawable)
            (gimp-image-raise-item-to-top image mask)
            (gimp-image-set-active-layer image (car (gimp-image-merge-down image mask 1)))

            ; we want drawable to reference the top layer now
            (set! drawable (car (gimp-image-get-active-layer image)))
        )

        ; finally remove the rest of the white
        (plug-in-colortoalpha
            RUN-NONINTERACTIVE
            image ; unused 
            drawable
            '(255 255 255))

        '(drawable)
)

(define (rotoscope 
        filename
        outputfile
        )
    (let* ( 
            ; define the variables
            (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
            (background (car (gimp-image-get-active-layer image)))
            (highlights (car (gimp-layer-copy background TRUE)))
            (foreground (car (gimp-layer-copy background TRUE)))
            (hatch1 (car (new-layer-same-size image background)))
            (hatch2 (car (new-layer-same-size image background)))
        )

        ; insert the layers into the image
        (gimp-image-insert-layer image foreground 0 -1)
        (gimp-image-insert-layer image hatch1 0 -1)
        (gimp-image-insert-layer image hatch2 0 -1)
        (gimp-image-insert-layer image highlights 0 -1)


        ; initialize the hatch layers
        ;   fill with plasma noise
        ;   for some reason GEGL won't fill layer, so set active and trim
        ;   ... then resize to match image again
        ;   newsprint distort @ 45 degrees
        ;   mirror to second hatch layer
        (generate-hatching
            image
            hatch1
            background
            125
            0.25)
        (set! hatch1 (car (gimp-image-get-active-layer image)))

        (generate-hatching
            image
            hatch2
            background
            55
            0.4)
        (set! hatch2 (car (gimp-image-get-active-layer image)))

        ; create the background color with a wide oilify plus waterpixel
        ; then oilify again to smooth out the edges 
        (plug-in-oilify
            RUN-NONINTERACTIVE
            image ; unused
            background
            12
            1)
        (gegl-gegl
            background
            "waterpixels size=128")
        (plug-in-oilify
            RUN-NONINTERACTIVE
            image ; unused
            background
            24
            1)

        ; create the highlight layer
        ; desaturate
        ; guassian blur 3
        ; posterize 7
        ; colortoalpha black .75 alpha threshold
        (gimp-drawable-desaturate
            highlights
            1)
        (plug-in-gauss
            RUN-NONINTERACTIVE
            image ; unused 
            highlights
            3.0
            3.0
            0)
        (gimp-drawable-posterize
            highlights
            7)
        (gegl-gegl
            highlights
            "color-to-alpha color=rgb(0,0,0) transparency-threshold=0.75")   
        (plug-in-oilify
            RUN-NONINTERACTIVE
            image ; unused
            highlights
            8
            1)
        
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

        (gimp-image-raise-item-to-top image foreground)


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