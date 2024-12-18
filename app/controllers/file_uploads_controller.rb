require 'aws-sdk-s3'

class FileUploadsController < ApplicationController
  before_action :authenticate_user!

  def index
    @file_uploads = current_user.file_uploads
  end

  def new
    @file_upload = FileUpload.new
  end

  def create
    @file_upload = current_user.file_uploads.new(file_upload_params)
  
    if params[:file_upload][:file].present?
      file = params[:file_upload][:file]
      @file_upload.save

      if @file_upload.file.attached?
        file_url = url_for(@file_upload.file)  
        @file_upload.update(file_url: file_url)
      end
  
      if @file_upload.save
        redirect_to file_uploads_path, notice: "File uploaded successfully."
      else
        render :new
      end
    else
      render :new, alert: "Please select a file to upload."
    end
  end
  

  def destroy
    @file_upload = current_user.file_uploads.find(params[:id])
    delete_from_s3(@file_upload)
    @file_upload.destroy
    redirect_to file_uploads_path, notice: 'File deleted successfully.'
  end

  private

  def file_upload_params
    params.require(:file_upload).permit(:title, :description, :file)
  end

  def upload_to_s3(file)
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['AWS_BUCKET_NAME'])

    file_name = "#{Time.now.to_i}_#{file.original_filename}"
    
    obj = bucket.object("uploads/#{current_user.id}/#{file_name}")
    obj.put(body: file.tempfile, acl: 'public-read') 
    
    obj.public_url
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Upload Error: #{e.message}"
    nil
  end

  def delete_from_s3(file_upload)
    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    s3.delete_object(
      bucket: ENV['AWS_BUCKET_NAME'],
      key: "uploads/#{file_upload.user.id}/#{File.basename(file_upload.file_url)}"
    )
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Delete Error: #{e.message}"
  end
end
