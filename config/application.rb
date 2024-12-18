# config/application.rb
require_relative 'boot'

require 'rails/all'

# Ensure the aws-sdk-s3 gem is required
require 'aws-sdk-s3'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
module FileManagementSystem
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
  end
end