module EmberSecureBuilder
  module TestSupport
    class MockRedis
      attr_accessor :commands

      def initialize
        self.commands = []
      end

      def sadd(*args)
        commands << args
      end
    end
  end
end
