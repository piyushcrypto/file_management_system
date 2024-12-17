class FileUpload < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :title, presence: true
  validates :file, attached: true, content_type: ['image/png', 'image/jpeg', 'application/pdf'], size: { less_than: 10.megabytes }
end
