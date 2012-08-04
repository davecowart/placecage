class ImageController < ApplicationController
	def show
		return_image(params,false)
	end

	def show_gray
		return_image(params,true)
	end

private
	def return_image(params, grayscale=false)
		filename = get_image_filename(params[:width], params[:height], grayscale)
		image = Magick::Image.read(filename).first
		response.headers["Content-Type"] = image.mime_type
		render :text => image.to_blob
	end

	def get_image_filename(width, height, grayscale=false)
		filename = Rails.root.join('images','generated',grayscale ? 'grayscale' : 'color', "#{width}x#{height}.jpg")
		return filename if FileTest.exists?(filename)

		original_filename = Dir.glob(Rails.root.join('images','source','*.*')).sample
		image_original = Magick::Image.read(original_filename).first
		image = image_original.resize_to_fill(width.to_i,height.to_i)
		image = image.quantize(256,Magick::GRAYColorspace) if grayscale
		image.write(filename)
		filename
	end
end