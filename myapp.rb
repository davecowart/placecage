set :public_folder, File.dirname(__FILE__) + '/public'
set :generated_images_folder, File.dirname(__FILE__) + '/images/generated'
set :images_folder, File.dirname(__FILE__) + '/images/source'
set :static_cache_control, [:public, :max_age => 300]
gabba = nil
domain = nil

before do
  domain = request.host.split('.').reverse[1]

  #set gabba
  ga_index = 1
  case domain
  when 'fillmurray'
    ga_index = 1
  when 'placecage'
    ga_index = 2
  when 'stevensegallery'
    ga_index = 3
  end
  gabba = Gabba::Gabba.new("UA-37788508-#{ga_index}", "auto")

  pass if request.path. == '/'
  cache_control :public, :max_age => 31536000
  check_sizes
end

get '/' do
  send_file File.join(settings.public_folder, domain, 'index.html')
end

get '/:width/:height', '/:width/:height/' do
  width = params[:width].to_i
  height = params[:height].to_i
  gabba.page_view("Show", "#{width}/#{height}")
  return_image(domain,width,height)
end

get '/c/:width/:height', '/c/:width/:height/' do
  width = params[:width].to_i
  height = params[:height].to_i
  gabba.page_view("ShowCrazy", "c/#{width}/#{height}")
  return_image(domain,width,height,:crazy)
end

get '/g/:width/:height', '/g/:width/:height/' do
  width = params[:width].to_i
  height = params[:height].to_i
  gabba.page_view("ShowGray", "g/#{width}/#{height}")
  return_image(domain,width,height,:grayscale)
end

get '/gif/:width/:height', '/gif/:width/:height/' do
  width = params[:width].to_i
  height = params[:height].to_i
  gabba.page_view("ShowGif", "gif/#{width}/#{height}")
  return_gif(domain,width,height)
end

private
	def check_sizes
    matches = /\/(\d+)\/(\d+)/.match(request.path)
		width = matches[1].to_i
		height = matches[2].to_i
    raise error 'Bad Request' if height == nil || width == nil || height < 1 || width < 1
    raise error 'Too Large' if height > 3500 || width > 3500
	end

	def return_image(domain, width, height, *args)
		grayscale = args.include?(:grayscale)
		crazy = args.include?(:crazy)
		filename = get_image_filename(domain, width, height, grayscale, crazy)
    send_file filename, type: 'image/jpeg', disposition: 'inline'
	end

  def return_gif(domain, width, height)
    send_file get_gif_filename(domain, width, height), type: 'image/gif', disposition: 'inline'
  end

  def get_gif_filename(domain, desired_width, desired_height)
    original_path = [domain, 'gifs', '*.gif']
    filename = Dir.glob(File.join(settings.images_folder, *original_path)).sample

    dimensions = "#{desired_width.to_i}x#{desired_height.to_i}"
    path = [domain, 'gifs',"#{dimensions}.gif"]
    generated_filename = File.join(settings.generated_images_folder, *path)
		return generated_filename if FileTest.exists?(generated_filename)

    puts "Getting info for #{filename}"

    sizeinfo = `gifsicle --sinfo #{filename} | grep 'logical screen'`
    puts sizeinfo
    matches = /\s(\d+)x(\d+)/.match(sizeinfo)
    width = matches.captures[0].to_i
    height = matches.captures[1].to_i

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

	def get_image_filename(domain, width, height, grayscale=false, crazy=false)
    path = [domain]
		path << 'grayscale' if grayscale
		path << 'crazy' if crazy
		path << "#{width}x#{height}.jpg"

    # send_file File.join(settings.public_folder, 'index.html')
    filename = File.join(settings.generated_images_folder, *path)
		return filename if FileTest.exists?(filename)

    original_path = [domain]
		original_path << 'crazy' if crazy
		original_path << '*.*'
    original_filename = Dir.glob(File.join(settings.images_folder, *original_path)).sample

		image_original = Magick::Image.read(original_filename).first
		image = image_original.resize_to_fill(width,height)
		image = image.quantize(256,Magick::GRAYColorspace) if grayscale
		image.write(filename)
		filename
	end
