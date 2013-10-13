require 'securerandom'

require 'spec_helper'

module EmberSecureBuilder
  describe S3Uploader do
    class FakeS3Uploader
      include EmberSecureBuilder::S3Uploader
    end

    let(:uploader) { FakeS3Uploader.new }
    let(:destination) { 'foo/bar/blammo' }
    let(:value) { SecureRandom.urlsafe_base64 }

    describe "#upload" do
      let(:fake_bucket)  { TestSupport::MockS3Bucket.new }

      before do
        def uploader.build_s3_bucket
          @build_s3_bucket_called = true
          TestSupport::MockS3Bucket.new
        end

        def uploader.build_s3_bucket_called
          @build_s3_bucket_called
        end
      end

      it "calls build_s3_bucket if no bucket is provided" do
        uploader.upload(destination, value)

        assert uploader.build_s3_bucket_called
      end

      it "uses the bucket if provided" do
        uploader.upload(destination, value, :bucket => fake_bucket)

        refute uploader.build_s3_bucket_called
      end

      it "uploads files" do
        uploader.upload(destination, value, :bucket => fake_bucket)

        assert_equal 1, fake_bucket.objects.length
      end

      it "saves data" do
        uploader.upload(destination, value, :bucket => fake_bucket)

        s3_object = fake_bucket.objects[destination]

        assert_equal value, s3_object.source_path
      end
    end
  end
end
