module EmberSecureBuilder
  module TestSupport
    module RedisAssertion
      def assert_redis_command(command)
        called_commands = mock_redis.commands.map{|s| "\t#{s}"}.join("\n")
        msg = "\nExpected uncalled redis command:\n\n\t#{command}\n\nThe following commands were called:\n\n#{called_commands}"

        assert mock_redis.commands.include?(command), msg
      end
    end

    class MockRedis
      attr_accessor :commands

      def initialize
        self.commands = []
      end

      def method_missing(method_called, *args)
        commands << [method_called, *args]
      end
    end
  end
end
