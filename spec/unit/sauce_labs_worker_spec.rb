require 'spec_helper'

module EmberSecureBuilder
  describe SauceLabsWorker do
    let(:worker) { SauceLabsWorker }

    before do
      worker.jobs.clear
    end

    describe "#queue_cross_browser_tests" do
      let(:mock_worker) { Minitest::Mock.new }
      let(:mock_platforms) { [{foo: 'bar'}, {bin: 'go'}] }
      let(:options)   { {url: 'foo/bar/baz'} }

      it "raises an error if test_options isn't provided" do
        assert_raises(ArgumentError) { worker.queue_cross_browser_tests }
      end

      it "queues tests for the default platforms" do
        mock_platforms.each do |hash|
          mock_worker.expect :perform_async, nil, [hash.merge(options)]
        end

        worker.queue_cross_browser_tests worker_class: mock_worker,
                                         platforms: mock_platforms,
                                         test_options: options

        mock_worker.verify
      end
    end
  end
end

