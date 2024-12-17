class FileUploadsController < ApplicationController
  before_action :authenticate_user!

  def index
    @file_uploads = current_user.file_uploads
  end

  def new
    @file_upload = FileUpload.new
  end

  def file_upload_to_s3(file_upload)
    file = params[:file_upload][:file]
    if file.content_type.start_with?('image')
      image = MiniMagick::Image.open(file.path)
      image.format "jpeg"
      image.quality 75
      compressed_file_path = Rails.root.join('tmp', 'compressed_file.jpg')
      image.write(compressed_file_path)
      file = File.open(compressed_file_path)
    end
  
    s3 = Aws::S3::Resource.new(region: 'ap-southeast-1')
    bucket = s3.bucket('file-management-bucket-ftr')
    s3_object = bucket.object("uploads/#{file_upload.user.id}/#{file.original_filename}")
    s3_object.upload_file(file.path)
  
    file_upload.update(file_url: s3_object.public_url)
  end
  

  def destroy
    @file_upload = current_user.file_uploads.find(params[:id])
    s3 = Aws::S3::Resource.new(region: 'ap-southeast-1')
    s3_object = s3.bucket('file-management-bucket-ftr').object(@file_upload.file_url.split('/').last)
    s3_object.delete
    @file_upload.destroy
  
    redirect_to file_uploads_path, notice: 'File deleted successfully.'
  end
  

  private

  def file_upload_params
    params.require(:file_upload).permit(:title, :description, :file_url)
  end

  def file_upload_to_s3(file_upload)
    s3 = Aws::S3::Resource.new(region: 'ap-southeast-1')
    bucket = s3.bucket('file-management-bucket-ftr')

    file = params[:file_upload][:file]
    s3_object = bucket.object("uploads/#{file_upload.user.id}/#{file.original_filename}")

    s3_object.upload_file(file.path)

    file_upload.update(file_url: s3_object.public_url)
  end
end
