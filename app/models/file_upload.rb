class FileUpload < ApplicationRecord
  belongs_to :user
  validates :title, presence: true
  validates :file_url, presence: true
end