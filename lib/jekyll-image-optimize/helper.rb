jpeg_compression_options = {
    # disabling all but one jpg library that has max_quality option
    :jpegrecompress => false,
    :jhead=> false,
    :jpegtran=> false,
    :jpegoptim=>
    {
        :allow_lossy=> true,
        :max_quality => 20
    }
}

png_compression_options = {
    # disabling all but one png library that has quality option
    :optipng=> false,
    :oxipng => false,
    :pngcrush=> false,
    :pngout=> false,
    :pngquant=>
    {
        :allow_lossy=> true,
        :quality => 20..30
    }
}

gif_compression_options = {
    :gifsicle => {
        :level => 3,
    }
}

COMPRESION_OPTIONS = jpeg_compression_options.merge(png_compression_options)
