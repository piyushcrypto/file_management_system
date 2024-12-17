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

    if @file_upload.save
      FileUploadJob.perform_now(@file_upload.id)
      redirect_to file_uploads_path, notice: "File uploaded successfully."
    else
      render :new
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

  def delete_from_s3(file_upload)
    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    s3.delete_object(
      bucket: ENV['AWS_BUCKET_NAME'],
      key: "uploads/#{file_upload.user.id}/#{file_upload.file.filename}"
    )
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Delete Error: #{e.message}"
  end
end
