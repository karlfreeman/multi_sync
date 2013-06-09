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

    describe :configure do
      subject { MultiSync.respond_to?(:configure) }
      it { should be_true }
    end

  end

  context :configure do

    it "should allow you to set configuration" do

      MultiSync.configure do |config|
        config.verbose = true
        config.concurrency = 2
      end

      expect(MultiSync.verbose).to be_true
      expect(MultiSync.concurrency).to be 2

    end

  end

  context :run, fakefs: true do

    before do

      FileUtils.mkdir_p("/tmp/simple")
      File.open("/tmp/simple/foo.txt", "w") do |f| f.write("foo") end
      File.open("/tmp/simple/bar.txt", "w") do |f| f.write("bar") end
      FileUtils.mkdir_p("/tmp/simple/in-a-dir")
      File.open("/tmp/simple/in-a-dir/baz.html", "w") do |f| f.write("baz") end

      FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-outdated-file")
      FileUtils.rm_r("/tmp/simple-with-outdated-file/foo.txt")

      FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-abandoned-file")
      File.open("/tmp/simple-with-abandoned-file/baz.txt", "w") do |f| f.write("baz") end

      FileUtils.mkdir_p("/tmp/complex")
      50.times do
        File.open("/tmp/complex/#{SecureRandom.urlsafe_base64}.txt", "w") do |f| f.write(SecureRandom.random_bytes) end
      end

      FileUtils.mkdir_p("/tmp/complex-empty")

    end

    before do
      Fog.mock!

      connection = Fog::Storage.new(
        :provider => :aws,
        :region => "us-east-1",
        :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
        :aws_secret_access_key => "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",
      )

      directory = connection.directories.create(
        :key => "multi_sync",
        :public => true
      )

      ["simple", "simple-with-outdated-file", "simple-with-abandoned-file"].each do |fixture_name|
        Dir.glob("/tmp/#{fixture_name}/**/*").reject {|path| File.directory?(path) }.each do |path|
          directory.files.create(
            :key => path.gsub("/tmp/", ""),
            :body => File.open(path, "r"),
            :public => true
          )
        end
      end

    end

    after do
      Fog.unmock!
    end

    it "should work" do

      MultiSync.run do

        target :aws, :simple_with_outdated_file, {
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
            :aws_secret_access_key => "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"
          }
        }

        target :aws, :simple_with_abandoned_file, {
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-abandoned-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
            :aws_secret_access_key => "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"
          }
        }

        source :local, :simple, {
          :source_dir => "/tmp/simple",
          :targets => [ :simple_with_outdated_file, :simple_with_abandoned_file ]
        }

      end

    end

  end


end