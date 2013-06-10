require "spec_helper"

describe MultiSync::Configuration, fakefs: true do

  before do
    FileUtils.mkdir_p("/tmp/fog")
    File.open("/tmp/fog/.fog", "w") do |f|
      f << "default:\n"
      f << "  aws_access_key_id: AWS_ACCESS_KEY_ID_DEFAULT\n"
      f << "  aws_secret_access_key: AWS_SECRET_ACCESS_KEY_DEFAULT\n"
      f << "alt:\n"
      f << "  aws_access_key_id: AWS_ACCESS_KEY_ID_ALT\n"
      f << "  aws_secret_access_key: AWS_SECRET_ACCESS_KEY_ALT"
    end
  end

  let(:configuration) { MultiSync::Configuration.new }

  context :target_pool_size do

    context :defaults do

      describe :size do
        subject { configuration.target_pool_size }
        it { should > 1 }
      end

    end

    context :custom do

      before do
        configuration.target_pool_size = 3
      end

      describe :size do
        subject { configuration.target_pool_size }
        it { should eq 3 }
      end

    end

  end

  context :credentials do

    before do
      Fog.instance_variable_set('@credential_path', nil) # kill fog memoization
      Fog.instance_variable_set('@credentials', nil) # kill fog memoization
      Fog.instance_variable_set('@credential', nil) # kill fog memoization
    end

    after(:each) do
      ENV["FOG_RC"] = nil
      ENV["FOG_CREDENTIAL"] = "default"
    end

    context "with default fog credentials" do

      before do
        ENV["FOG_RC"] = nil
        ENV["FOG_CREDENTIAL"] = "default"
      end

      describe :credentials do
        subject { configuration.credentials }
        it { should be_empty }
      end

    end

    context "with custom .fog path set" do

      before do
        ENV["FOG_RC"] = "/tmp/fog/.fog"
        ENV["FOG_CREDENTIAL"] = "default"
      end

      describe :credentials do
        subject { configuration.credentials }
        its([:aws_access_key_id]) { should eq "AWS_ACCESS_KEY_ID_DEFAULT" }
        its([:aws_secret_access_key]) { should eq "AWS_SECRET_ACCESS_KEY_DEFAULT" }
      end

    end

    context "with 'alt' credential set" do

      before do
        ENV["FOG_RC"] = "/tmp/fog/.fog"
        ENV["FOG_CREDENTIAL"] = "alt"
      end

      describe :credentials do
        subject { configuration.credentials }
        its([:aws_access_key_id]) { should eq "AWS_ACCESS_KEY_ID_ALT" }
        its([:aws_secret_access_key]) { should eq "AWS_SECRET_ACCESS_KEY_ALT" }
      end

    end

  end

end