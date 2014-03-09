require 'spec_helper'

describe MultiSync do
  context :methods do
    [:configure, :run, :prepare, :client, :configuration, :version, :reset_client!, :reset_configuration!, :reset!].each do |method_name|
      it "should respond_to #{method_name}" do
        expect(MultiSync).to respond_to(method_name)
      end
    end
    MultiSync::Client::SUPPORTED_SOURCE_TYPES.each do |type, clazz|
      it "should respond_to #{type}_source" do
        expect(MultiSync).to respond_to("#{type}_source")
      end
    end
    MultiSync::Client::SUPPORTED_TARGET_TYPES.each do |type, clazz|
      it "should respond_to #{type}_target" do
        expect(MultiSync).to respond_to("#{type}_target")
      end
    end
  end
  context :client_delegated_methods do
    [:sync].each do |method_name|
      it "should respond_to #{method_name}" do
        expect(MultiSync).to respond_to(method_name)
      end
    end
    MultiSync::Client.attribute_set.map(&:name).each do |method_name|
      it "should respond_to #{method_name}" do
        expect(MultiSync).to respond_to(method_name)
      end
    end
  end
  context :configuration_delegated_methods do
    MultiSync::Configuration.attribute_set.map(&:name).each do |method_name|
      it "should respond_to #{method_name}" do
        expect(MultiSync).to respond_to(method_name)
      end
    end
  end
  context :configure do
    describe :block do
      it 'should allow you to set configuration' do
        MultiSync.configure do |config|
          config.verbose = true
          config.target_pool_size = 2
        end
        expect(MultiSync.verbose).to be_true
        expect(MultiSync.target_pool_size).to be 2
      end
    end
    describe :methods do
      it 'should allow you to set configuration' do
        MultiSync.verbose = true
        MultiSync.target_pool_size = 2
        expect(MultiSync.verbose).to be_true
        expect(MultiSync.target_pool_size).to be 2
      end
    end
  end
end
