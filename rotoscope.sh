echo "input: $1"
echo "output: $2"

ffmpeg -i $1 -r 6 -q:v 4 -f image2 original-frames/image.%6d.jpeg

mkdir output

for frame in $(ls original-frames); do
    echo "Converting $frame..."
    gimp -i -b "$(cat rotoscope.scm) (rotoscope \"original-frames/$frame\" \"output/$frame\")" -b '(gimp-quit 0)' > /dev/null 2>&1
done

ffmpeg -r 6 -f image2 -i output/image.%6d.jpeg -vcodec libx264 -crf 15  -pix_fmt yuv420p $2