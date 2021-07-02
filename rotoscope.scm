; http://eeb.lu.lv/ftp/pub/Grafika/GIMP/programmeshana/BatchMode.html
; https://www.gimp.org/tutorials/Basic_Batch/
(define (rotoscope 
        filename
        outputfile           
        ;radius
		;amount
		;threshold
        )
    (let* ( 
            ; define the variables
            (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
            (background (car (gimp-image-get-active-layer image)))
            (foreground (car (gimp-layer-copy background TRUE)))
        )

        ; insert the foreground into the image
        (gimp-image-insert-layer image foreground 0 0)

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