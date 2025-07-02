require 'yaml'

RSpec.configure do |config|
  config.before(:all) do
    @validate = ENV['VALIDATE'] || ''
  end
end