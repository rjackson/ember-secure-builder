module EmberSecureBuilder
  module TestSupport
    class MockRedis
      attr_accessor :commands

      def initialize
        self.commands = []
      end

      def sadd(*args)
        commands << [:sadd, *args]
      end

      def srem(*args)
        commands << [:srem, *args]
      end

      def set(*args)
        commands << [:set, *args]
      end
    end
  end
end
