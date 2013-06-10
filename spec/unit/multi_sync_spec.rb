require "spec_helper"

describe MultiSync do

  before do
    MultiSync.instance_variable_set('@client', nil) # kill memoization
    MultiSync.instance_variable_set('@configuration', nil) # kill memoization
  end

  context :methods do

    describe :version do
      subject { MultiSync::VERSION }
      it { should be_kind_of(String) }
    end

    describe :logger do
      subject { MultiSync.respond_to?(:logger) }
      it { should be_true }
    end

    describe :environment do
      subject { MultiSync.respond_to?(:environment) }
      it { should be_true }
    end

    describe :credentials do
      subject { MultiSync.respond_to?(:credentials) }
      it { should be_true }
    end

    describe :run do
      subject { MultiSync.respond_to?(:run) }
      it { should be_true }
    end

    describe :configure do
      subject { MultiSync.respond_to?(:configure) }
      it { should be_true }
    end

  end

  context :configure do

    it "should allow you to set configuration" do

      MultiSync.configure do |config|
        config.verbose = true
        config.target_pool_size = 2
      end

      expect(MultiSync.verbose).to be_true
      expect(MultiSync.target_pool_size).to be 2

    end

  end

end