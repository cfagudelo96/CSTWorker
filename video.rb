require 'aws-sdk'
require 'aws-sdk-sqs'
require 'mongoid'
require 'carrierwave'
require 'fog-aws'
require 'carrierwave/storage/fog'
require 'carrierwave/mongoid'
require './original_video_uploader'
require './video_uploader'

class Video
  include Mongoid::Document

  IN_PROGRESS = 0
  CONVERTED = 1

  field :description, type: String
  field :name, type: String
  field :last_name, type: String
  field :email, type: String
  field :original_video, type: String
  field :video, type: String
  field :status, type: Integer, default: 0
  field :contest_id, type: Integer

  mount_uploader :original_video, OriginalVideoUploader
  mount_uploader :video, VideoUploader
end