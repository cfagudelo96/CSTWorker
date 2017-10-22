require 'aws-sdk'
require 'aws-sdk-sqs'
require 'mongoid'
require 'carrierwave'
require 'fog-aws'
require 'carrierwave/storage/fog'
require 'carrierwave/mongoid'

class VideoUploader < CarrierWave::Uploader::Base
  storage :fog

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
