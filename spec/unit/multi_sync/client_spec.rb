require "spec_helper"

describe MultiSync::Client, fakefs: true do

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

        outdated_files_target = MultiSync::LocalTarget.new(
          :target_dir => "/tmp",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :local_root => "/tmp"
          }
        )

        abandoned_files_target = MultiSync::LocalTarget.new(
          :target_dir => "/tmp",
          :destination_dir => "simple-with-abandoned-file",
          :credentials => {
            :local_root => "/tmp"
          }
        )

        expect(outdated_files_target).to have(2).files
        expect(abandoned_files_target).to have(4).files

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple",
          :targets => [outdated_files_target, abandoned_files_target]
        )

        expect(source).to have(3).files
        expect(source).to have(2).targets

        client.targets << outdated_files_target
        client.targets << abandoned_files_target
        expect(client).to have(2).targets

        client.sources << source
        expect(client).to have(1).sources

        client.sync

        expect(outdated_files_target).to have(3).files
        expect(abandoned_files_target).to have(3).files

      end

    end

    context :aws do

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

        client = MultiSync::Client.new

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple"
        )

        outdated_files_target = MultiSync::AWSTarget.new(
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
            :aws_secret_access_key => "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",
          }
        )

        abandoned_files_target = MultiSync::AWSTarget.new(
          :target_dir => "multi_sync",
          :destination_dir => "simple-with-abandoned-file",
          :credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
            :aws_secret_access_key => "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",
          }
        )

        expect(outdated_files_target).to have(2).files
        expect(abandoned_files_target).to have(4).files

        source = MultiSync::Source.new(
          :source_dir => "/tmp/simple",
          :targets => [outdated_files_target, abandoned_files_target]
        )

        expect(source).to have(3).files
        expect(source).to have(2).targets

        client.targets << outdated_files_target
        client.targets << abandoned_files_target
        expect(client).to have(2).targets

        client.sources << source
        expect(client).to have(1).sources

        client.sync

        expect(outdated_files_target).to have(3).files
        expect(abandoned_files_target).to have(3).files

      end

    end

  end

end