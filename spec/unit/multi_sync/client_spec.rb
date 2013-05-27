require "spec_helper"

describe MultiSync::Client, fakefs: true do

  before do
    FileUtils.mkdir_p("/tmp/simple")
    File.open("/tmp/simple/foo.txt", "w") do |f| f.write("foo") end
    File.open("/tmp/simple/bar.txt", "w") do |f| f.write("bar") end
    FileUtils.mkdir_p("/tmp/simple/in-a-dir")
    File.open("/tmp/simple/in-a-dir/baz.html", "w") do |f| f.write("baz") end

    FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-missing-file")
    FileUtils.rm_r("/tmp/simple-with-missing-file/foo.txt")

    FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-outdated-file")
    File.open("/tmp/simple-with-outdated-file/baz.txt", "w") do |f| f.write("baz") end
  end

  # context :targets do

  #   it "should allow for targets to be added ( uniquely )" do
  #     client = MultiSync::Client.new
  #     expect{client.targets << MultiSync::Target.new}.to change{client.targets.length}.from(0).to(1)
  #     uniq_target = MultiSync::Target.new
  #     expect{client.targets << uniq_target}.to change{client.targets.length}.from(1).to(2)
  #     expect{client.targets << uniq_target}.to change{client.targets.length}.by(0)
  #     expect(client.targets).to include(uniq_target)
  #   end

  # end

  # context :sources do

  #   it "should allow for sources to be added ( uniquely )" do
  #     client = MultiSync::Client.new
  #     expect{client.sources << MultiSync::Source.new}.to change{client.sources.length}.from(0).to(1)
  #     uniq_source = MultiSync::Source.new
  #     expect{client.sources << uniq_source}.to change{client.sources.length}.from(1).to(2)
  #     expect{client.sources << uniq_source}.to change{client.sources.length}.by(0)
  #     expect(client.sources).to include(uniq_source)
  #   end

  # end

  context :sync do

    let(:source) { MultiSync::Source.new(:source_dir => "/tmp/simple") }

    context :local do

      it "should work" do

        missing_files_target = MultiSync::Target.new(
          :provider => :local,
          :provider_credentials => {
            :local_root => "/tmp"
          },
          :target_dir => "/tmp",
          :destination_dir => "simple-with-missing-file"
        )

        outdated_files_target = MultiSync::Target.new(
          :provider => :local,
          :provider_credentials => {
            :local_root => "/tmp"
          },
          :target_dir => "/tmp",
          :destination_dir => "simple-with-outdated-file"
        )

        expect(missing_files_target).to have(2).files
        expect(outdated_files_target).to have(4).files

        # ap "missing_files_target: missing remote file"
        missing_missing = (source.files - missing_files_target.files)
        # ap missing_missing

        # ap "missing_files_target: outdated remote file"
        missing_outdated = (missing_files_target.files - source.files)
        # ap missing_outdated

        # ap "outdated_files_target: missing remote files"
        outdated_missing = (source.files - outdated_files_target.files)
        # ap outdated_missing

        # ap "outdated_files_target: outdated remote files"
        outdated_outdated = (outdated_files_target.files - source.files)
        # ap outdated_outdated

      end

    end

    context :aws do

      before do
        Fog.mock!

        connection = Fog::Storage.new(
          :provider => :aws,
          :region => "us-east-1",
          :aws_access_key_id => "xxx",
          :aws_secret_access_key => "xxx"
        )

        directory = connection.directories.create(
          :key => "multi_sync",
          :public => true
        )

        ["simple", "simple-with-outdated-file", "simple-with-missing-file"].each do |fixture_name|
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

        outdated_files_target = MultiSync::Target.new(
          :provider => :aws,
          :provider_credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "xxx",
            :aws_secret_access_key => "xxx"
          },
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-outdated-file"
        )

        missing_files_target = MultiSync::Target.new(
          :provider => :aws,
          :provider_credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "xxx",
            :aws_secret_access_key => "xxx"
          },
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-missing-file"
        )

        expect(missing_files_target).to have(2).files
        expect(outdated_files_target).to have(4).files

        # ap "missing_files_target: missing remote file"
        missing_missing = (source.files - missing_files_target.files)
        # ap missing_missing

        # ap "missing_files_target: outdated remote file"
        missing_outdated = (missing_files_target.files - source.files)
        # ap missing_outdated

        # ap "outdated_files_target: missing remote files"
        outdated_missing = (source.files - outdated_files_target.files)
        # ap outdated_missing

        # ap "outdated_files_target: outdated remote files"
        outdated_outdated = (outdated_files_target.files - source.files)
        # ap outdated_outdated

      end

    end

  end

end