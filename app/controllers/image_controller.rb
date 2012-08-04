class ImageController < ApplicationController
	def show
		width = params[:width]
		height = params[:height]
		image_original = Magick::Image.read(Rails.root.join('images','123.jpeg')).first
		image = image_original.resize_to_fill(width.to_i,height.to_i)
		response.headers["Content-Type"] = image.mime_type
		render :text => image.to_blob
	end
end