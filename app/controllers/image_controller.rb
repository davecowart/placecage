require 'RMagick'

class ImageController < ApplicationController
	before_filter :check_sizes, :only => [:show, :show_gray, :show_crazy, :show_gif]

	def show
		gabba = Gabba::Gabba.new("UA-33854875-1", "placecage.com")
		gabba.event("Images", "Show", "Size", "#{@width*@height}", true)
		gabba.page_view("Show", "#{@width}/#{@height}")
    expires_in 1.year, :public => true
		return_image(@width,@height)
	end

	def show_gray
		gabba = Gabba::Gabba.new("UA-33854875-1", "placecage.com")
		gabba.event("Images", "ShowGray", "Size", "#{@width*@height}", true)
		gabba.page_view("ShowGray", "g/#{@width}/#{@height}")
    expires_in 1.year, :public => true
		return_image(@width,@height,:grayscale)
	end

	def show_crazy
		gabba = Gabba::Gabba.new("UA-33854875-1", "placecage.com")
		gabba.event("Images", "ShowCrazy", "Size", "#{@width*@height}", true)
		gabba.page_view("ShowCrazy", "c/#{@width}/#{@height}")
    expires_in 1.year, :public => true
		return_image(@width,@height,:crazy)
	end

  def show_gif
		gabba = Gabba::Gabba.new("UA-33854875-1", "placecage.com")
		gabba.event("Images", "ShowGif", "Size", "#{@width*@height}", true)
		gabba.page_view("ShowGif", "c/#{@width}/#{@height}")
    expires_in 1.year, :public => true
    return_gif(@width,@height)
  end

private
	def check_sizes
		@width = params[:width].to_i
		@height = params[:height].to_i
		return render :nothing => true, :status => 400 if @height == nil || @width == nil || @height < 1 || @width < 1
		return render :nothing => true, :status => 403 if @height > 2000 || @width > 2000
	end

	def return_image(width, height, *args)
		grayscale = args.include?(:grayscale)
		crazy = args.include?(:crazy)
		filename = get_image_filename(width, height, grayscale, crazy)
		image = Magick::Image.read(filename).first
		response.headers["Content-Type"] = image.mime_type
		render :text => image.to_blob
	end

  def return_gif(width, height)
    filename = get_gif_filename(width, height)
    # image = Magick::Image.read(filename).first
    # response.headers["Content-Type"] = 'image/gif'
    # render :text => image.to_blob
    send_file filename, type: 'image/gif', disposition: 'inline'
  end

  def get_gif_filename(desired_width, desired_height)
    original_path = ['images', 'source', 'gifs', '*.gif']
		filename = Dir.glob(Rails.root.join(*original_path)).sample

    dimensions = "#{desired_width.to_i}x#{desired_height.to_i}"
    path = ['images','generated','gifs',"#{dimensions}.gif"]
		generated_filename = Rails.root.join(*path)
		return generated_filename if FileTest.exists?(generated_filename)

    sizeinfo = `gifsicle --sinfo #{filename} | grep 'logical screen'`
    matches = /\s(\d+)x(\d+)/.match(sizeinfo) 
    width = matches.captures[0].to_i #500
    height = matches.captures[1].to_i #375
    
    width_ratio = width.to_f / desired_width.to_f
    height_ratio = height.to_f / desired_height.to_f
    
    new_height = desired_height
    new_width = desired_width
    if (height_ratio <= width_ratio)
        new_width = width / height_ratio
    else
        new_height = height / width_ratio
    end
    
    crop_x = (new_width - desired_width) / 2
    crop_y = (new_height - desired_height) / 2

    `gifsicle #{filename} --resize #{new_width.to_i}x#{new_height.to_i} | gifsicle --crop #{crop_x.to_i},#{crop_y.to_i}+#{dimensions} --output #{generated_filename}`
    generated_filename
  end

	def get_image_filename(width, height, grayscale=false, crazy=false)
		path = ['images','generated']
		path << 'grayscale' if grayscale
		path << 'crazy' if crazy
		path << "#{width}x#{height}.jpg"
		filename = Rails.root.join(*path)
		return filename if FileTest.exists?(filename)

		original_path = ['images','source']
		original_path << 'crazy' if crazy
		original_path << '*.*'
		original_filename = Dir.glob(Rails.root.join(*original_path)).sample
		image_original = Magick::Image.read(original_filename).first
		image = image_original.resize_to_fill(width,height)
		image = image.quantize(256,Magick::GRAYColorspace) if grayscale
		image.write(filename)
		filename
	end
end
