require 'image_optim'
require_relative 'helper'
# TODO make this so it does not have to run all the time.

Jekyll::Hooks.register :site, :post_write do
    #TODO make this a helper function so its not just for jekyll
    
    extensions_of_interest = [".jpg",".png"]
    directory = "_site/assets"
    
    # assets
    # original
    
    image_optim = ImageOptim.new(COMPRESION_OPTIONS)
    files = Dir.glob("#{directory}/**/*").select do |file|
        File.file?(file) && extensions_of_interest.any? { |ext| file.downcase.end_with?(ext) }
    end
    
    print files
    # TODO: generate a before and after comparison look in html
    # exception list
  
  # TODO parallelize?
  image_optim.optimize_images!(files)
end
