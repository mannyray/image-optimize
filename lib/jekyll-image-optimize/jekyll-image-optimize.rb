require 'image_optim'

# TODO make this so it does not have to run all the time.

Jekyll::Hooks.register :site, :post_write do
    #TODO make this a helper function so its not just for jekyll
    print Dir.pwd
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
    
    options = jpeg_compression_options.merge(png_compression_options)
    #options = options.merge(gif_compression_options)
    
    
    image_optim = ImageOptim.new(options)
  
    extensions_of_interest = ["JPG",".jpg","png","gif"] #TODO
    directory = "_site/assets"
    files = Dir.glob("#{directory}/**/*").select do |file|
        File.file?(file) && ( file.match?(/\.JPG$/) || file.match?(/\.jpg$/)  || file.match?(/\.png$/))
        
    # TODO: generate a before and after comparison look in html
    # exception list
  end
  
  # TODO parallelize?
  image_optim.optimize_images!(files)
end
