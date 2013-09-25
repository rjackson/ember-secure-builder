module EmberSecureBuilder
  module TestSupport
    class MockS3Object
      attr_reader :path, :source_path, :options

      def initialize(path)
        @path = path
      end

      def write(source_path, options)
        @source_path = source_path
        @options = options
      end
    end

    class MockS3Bucket
      def objects
        @objects ||= Hash.new {|h,k| h[k] = MockS3Object.new(k) }
      end
    end
  end
end
