class FileUploadJob < ApplicationJob
  queue_as :default

  def perform(file_upload_id)
    file_upload = FileUpload.find(file_upload_id)
    file = file_upload.file

    begin
      # Local file setup
      temp_file_path = Rails.root.join('tmp', file.blob.filename.to_s)
      File.open(temp_file_path, 'wb') { |f| f.write(file.download) }

      # Image compression (if applicable)
      if file.content_type.start_with?('image')
        image = MiniMagick::Image.open(temp_file_path)
        image.format "jpeg"
        image.quality 75
        compressed_file_path = Rails.root.join('tmp', 'compressed_file.jpg')
        image.write(compressed_file_path)
        temp_file_path = compressed_file_path
      end

      # Upload to S3
      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
      bucket = s3.bucket(ENV['AWS_BUCKET_NAME'])
      s3_object = bucket.object("uploads/#{file_upload.user.id}/#{file.blob.filename.to_s}")
      s3_object.put(body: File.open(temp_file_path))

      # Update file URL
      file_upload.update(file_url: s3_object.public_url)
    ensure
      # Cleanup temporary files
      File.delete(temp_file_path) if File.exist?(temp_file_path)
    end
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Upload Error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "File Processing Error: #{e.message}"
  end
end
