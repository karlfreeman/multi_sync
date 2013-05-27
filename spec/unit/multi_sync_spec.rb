require "spec_helper"

describe MultiSync do

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

  describe :configure do
    subject { MultiSync.respond_to?(:configure) }
    it { should be_true }
  end

end