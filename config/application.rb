require_relative "boot"

require "rails/all"
require 'mini_magick'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hyakumasu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # @see https://qiita.com/hirokun0204/items/a18427c50c90676aed95
    config.hosts << "rewite"
    #config.hosts << "https://4077-220-209-99-244.ngrok.io"

  end

end
