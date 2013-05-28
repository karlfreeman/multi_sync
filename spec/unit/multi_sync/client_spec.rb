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

    context :local do

      it "should work" do

        client = MultiSync::Client.new

        missing_files_target = MultiSync::LocalTarget.new(
          :target_dir => "/tmp",
          :destination_dir => "simple-with-missing-file",
          :credentials => {
            :local_root => "/tmp"
          }
        )

        outdated_files_target = MultiSync::LocalTarget.new(
          :target_dir => "/tmp",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :local_root => "/tmp"
          }
        )

        expect(missing_files_target).to have(2).files
        expect(outdated_files_target).to have(4).files

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple",
          :targets => [missing_files_target, outdated_files_target]
        )

        missing_missing = (source.files - missing_files_target.files)
        expect(missing_missing.length).to be(1)

        missing_outdated = (missing_files_target.files - source.files)
        expect(missing_outdated.length).to be(0)

        outdated_missing = (source.files - outdated_files_target.files)
        expect(outdated_missing.length).to be(0)

        outdated_outdated = (outdated_files_target.files - source.files)
        expect(outdated_outdated.length).to be(1)

        expect(source).to have(3).files
        expect(source).to have(2).targets

        client.targets << missing_files_target
        client.targets << outdated_files_target
        expect(client).to have(2).targets

        client.sources << source
        expect(client).to have(1).sources

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

        client = MultiSync::Client.new

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple"
        )

        outdated_files_target = MultiSync::AWSTarget.new(
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "xxx",
            :aws_secret_access_key => "xxx"
          }
        )

        missing_files_target = MultiSync::AWSTarget.new(
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-missing-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "xxx",
            :aws_secret_access_key => "xxx"
          }
        )

        expect(missing_files_target).to have(2).files
        expect(outdated_files_target).to have(4).files

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple",
          :targets => [missing_files_target, outdated_files_target]
        )

        missing_missing = (source.files - missing_files_target.files)
        expect(missing_missing.length).to be(1)

        missing_outdated = (missing_files_target.files - source.files)
        expect(missing_outdated.length).to be(0)

        outdated_missing = (source.files - outdated_files_target.files)
        expect(outdated_missing.length).to be(0)

        outdated_outdated = (outdated_files_target.files - source.files)
        expect(outdated_outdated.length).to be(1)

        expect(source).to have(3).files
        expect(source).to have(2).targets

        client.targets << missing_files_target
        client.targets << outdated_files_target
        expect(client).to have(2).targets

        client.sources << source
        expect(client).to have(1).sources

      end

    end

  end

end