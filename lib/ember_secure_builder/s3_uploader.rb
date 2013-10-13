module EmberSecureBuilder
  module S3Uploader

    def upload(destination, value, options = {})
      bucket = options.fetch(:bucket) { build_s3_bucket }

      obj = bucket.objects[destination]
      obj.write(value, {:content_type => 'application/json'})
    end

    private

    def build_s3_bucket
      s3 = AWS::S3.new(:access_key_id => ENV['S3_ACCESS_KEY_ID'],
                       :secret_access_key => ENV['S3_SECRET_ACCESS_KEY'])

      s3.buckets[ENV['S3_BUCKET_NAME']]
    end
  end
end
