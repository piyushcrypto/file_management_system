class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum role: { user: 'user', admin: 'admin' }

  after_initialize :set_default_role, if: :new_record?

  has_many :file_uploads, dependent: :destroy
  
  private

  def set_default_role
    self.role ||= :user
  end
end
