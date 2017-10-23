require 'aws-sdk'
require 'aws-sdk-sqs'
require 'mongoid'
require 'carrierwave'
require 'fog-aws'
require 'carrierwave/storage/fog'
require 'carrierwave/mongoid'
require 'streamio-ffmpeg'
require 'open-uri'
require 'mail'
require './original_video_uploader'
require './video_uploader'
require './video'

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['CST_AWS_KEY'],
    aws_secret_access_key: ENV['CST_AWS_SECRET'],
    region: ENV['CST_AWS_REGION']
  }
  config.fog_directory = ENV['CST_S3_BUCKET']
  config.fog_public = false
end

Mongoid.load!('./mongoid.yml', :development)
credentials = Aws::Credentials.new(ENV['CST_AWS_KEY'],
                                   ENV['CST_AWS_SECRET'])

options = {
  address: 'email-smtp.us-east-1.amazonaws.com',
  port: 587,
  user_name: ENV['CLOUDSMARTTOOLS_SMTP_USER'],
  password: ENV['CLOUDSMARTTOOLS_SMTP_PASSWORD'],
  authentication: :login,
  enable_starttls_auto: true
}

Mail.defaults do
  delivery_method :smtp, options
end

region = ENV['CST_AWS_REGION']
Aws.config.update(credentials: credentials, region: region)

sqs = Aws::SQS::Client.new

loop do
  begin
    response = sqs.receive_message(queue_url: ENV['CST_SQS_URL'],
                                   max_number_of_messages: 1)

    response.messages.each do |message|
      video_id = message.body
      puts "Video id #{video_id}"
      video = Video.find(video_id)
      original_filename_split = video.original_video.file.filename.split('.')
      original_video_tmp_file = Tempfile.new([original_filename_split[0], ".#{original_filename_split[1]}"])
      puts "Original video #{original_video_tmp_file.path}"
      open(video.original_video.url) do |uri|
        puts uri
        File.open(original_video_tmp_file, 'wb') do |output|
          IO.copy_stream(uri, output)
        end
      end
      movie = FFMPEG::Movie.new(original_video_tmp_file.path)
      transcoded_video_file = Tempfile.new([video_id, '.mp4'])
      movie.transcode(transcoded_video_file.path)
      puts "Transcoded video #{transcoded_video_file.path}"
      video.video = transcoded_video_file.open
      video.status = Video::CONVERTED
      video.save
      Mail.deliver do
        from 'cloudsmarttools@gmail.com'
        to video.email
        subject 'Tu video ha sido subido'
        body "Hola #{video.name}, tu video ha sido subido a nuestra webpage. Cuando accedas a su respectivo concurso podras verlo"
      end
      puts 'Mail'
      sqs.delete_message(queue_url: ENV['CST_SQS_URL'], receipt_handle: message.receipt_handle)
      original_video_tmp_file.close
      transcoded_video_file.close
      original_video_tmp_file.unlink
      transcoded_video_file.unlink
      sleep(5)
    end
  rescue StandardError
    next
  end
end
