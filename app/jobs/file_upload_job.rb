class FileUploadJob < ApplicationJob
  queue_as :default

  def perform(file_upload_id)
    file_upload = FileUpload.find(file_upload_id)
    file = file_upload.file

    begin
      temp_file = Tempfile.new([file.blob.filename.base, ".#{file.blob.filename.extension}"])
      temp_file.binmode
      temp_file.write(file.download)
      temp_file.rewind

      if file.content_type.start_with?('image')
        image = MiniMagick::Image.read(temp_file.read)
        image.format "jpeg"
        image.quality 75

        compressed_temp_file = Tempfile.new(['compressed_file', '.jpg'])
        compressed_temp_file.binmode
        image.write(compressed_temp_file.path)
        compressed_temp_file.rewind

        temp_file.close
        temp_file = compressed_temp_file
      end

      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
      bucket = s3.bucket(ENV['AWS_BUCKET_NAME'])
      s3_object = bucket.object("uploads/#{file_upload.user.id}/#{file.blob.filename.to_s}")

      s3_object.put(body: temp_file)

      file_upload.update(file_url: s3_object.public_url)

    ensure
      temp_file.close
      temp_file.unlink 

  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Upload Error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "File Processing Error: #{e.message}"
  end
end
