(define kp_gegl_menu_root "<Image>/Script-Fu/GEGL")

(define (kp_gegl_operation img layer) 
  (let ((copy (car (gimp-layer-copy layer TRUE))))
    (gimp-image-insert-layer img copy 0 -1)
	(list copy)
  )  
)

(define (kjp24_geglfu_gegl img layer gegl-string)
  (let ((copy (car (kp_gegl_operation img layer))))
    (gegl-gegl copy gegl-string)
    (gimp-displays-flush)
  )
)
(script-fu-register
  "kjp24_geglfu_gegl"
  _"GEGL graph on a layer copy"
  "GEGL graph on a layer copy"
  ""
  ""
  ""
  "*"
  SF-IMAGE        "The Image"     0
  SF-DRAWABLE     "The Layer"     0
  SF-TEXT       "String" "lens-distortion main=50.0\nemboss\nhue-chroma chroma=87"
)
(script-fu-menu-register "kjp24_geglfu_gegl" kp_gegl_menu_root)
