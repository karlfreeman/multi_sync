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

    FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-abandoned-file")
    File.open("/tmp/simple-with-abandoned-file/baz.txt", "w") do |f| f.write("baz") end

    FileUtils.cp_r("/tmp/simple", "/tmp/simple-with-outdated-file")
    File.open("/tmp/simple-with-outdated-file/foo.txt", "w") do |f| f.write("outdated") end

    FileUtils.mkdir_p("/tmp/complex")
    50.times do
      File.open("/tmp/complex/#{SecureRandom.urlsafe_base64}.txt", "w") do |f| f.write(SecureRandom.random_bytes) end
    end

    FileUtils.mkdir_p("/tmp/complex-empty")

  end

  # context :sources do

  #   it "should allow for sources to be added ( uniquely )" do
  #     client = MultiSync::Client.new
  #     expect{client.sources << MultiSync::LocalSource.new}.to change{client.sources.length}.from(0).to(1)
  #     uniq_source = MultiSync::LocalSource.new
  #     expect{client.sources << uniq_source}.to change{client.sources.length}.from(1).to(2)
  #     expect{client.sources << uniq_source}.to change{client.sources.length}.by(0)
  #     expect(client.sources).to include(uniq_source)
  #   end

  # end

  context :sync do

    context :local do

      it "should work with simple" do

        missing_files_target_options = {
          :target_dir => "/tmp",
          :destination_dir => "simple-with-missing-file",
          :credentials => {
            :local_root => "/tmp"
          }
        }

        abandoned_files_target_options = {
          :target_dir => "/tmp",
          :destination_dir => "simple-with-abandoned-file",
          :credentials => {
            :local_root => "/tmp"
          }
        }

        outdated_files_target_options = {
          :target_dir => "/tmp",
          :destination_dir => "simple-with-outdated-file",
          :credentials => {
            :local_root => "/tmp"
          }
        }

        local_source_options = {
          :source_dir => "/tmp/simple"
        }

        missing_files_target = MultiSync::LocalTarget.new(missing_files_target_options)
        abandoned_files_target = MultiSync::LocalTarget.new(abandoned_files_target_options)
        outdated_files_target = MultiSync::LocalTarget.new(outdated_files_target_options)

        expect(missing_files_target).to have(2).files
        expect(abandoned_files_target).to have(4).files
        expect(outdated_files_target).to have(3).files

        local_source = MultiSync::LocalSource.new(local_source_options)
        expect(local_source).to have(3).files

        expect(outdated_files_target.files[1].body).to eq "outdated"

        MultiSync.run do
           target :local, :missing_files_target, missing_files_target_options
           target :local, :abandoned_files_target, abandoned_files_target_options
           target :local, :outdated_files_target, outdated_files_target_options
           source :local, :simple, local_source_options.merge(:targets => [ :missing_files_target, :abandoned_files_target, :outdated_files_target ])
         end

        expect(missing_files_target).to have(3).files
        expect(abandoned_files_target).to have(3).files
        expect(outdated_files_target).to have(3).files        
        expect(outdated_files_target.files[1].body).to eq "foo"

      end

      it "should work with complex" do

        complex_empty_target_options = {
          :target_dir => "/tmp",
          :destination_dir => "complex-empty",
          :credentials => {
            :local_root => "/tmp"
          }
        }

        local_source_options = {
          :source_dir => "/tmp/complex",
        }

        complex_empty_target = MultiSync::LocalTarget.new(complex_empty_target_options)
        expect(complex_empty_target).to have(0).files

        local_source = MultiSync::LocalSource.new(local_source_options)
        expect(local_source).to have(50).files

        MultiSync.run do
           target :local, :complex_empty_target, complex_empty_target_options
           source :local, :complex, local_source_options.merge(:targets => [ :complex_empty_target ])
         end

        expect(complex_empty_target).to have(50).files

      end

    end

    context :aws do

      context "simple" do

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

          ["simple", "simple-with-missing-file", "simple-with-abandoned-file", "simple-with-outdated-file"].each do |fixture_name|
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

          missing_files_target_options = {
            :target_dir => "multi_sync",
            :destination_dir => "simple-with-missing-file",
            :credentials => {
              :region => "us-east-1",
              :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
              :aws_secret_access_key => "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",
            }
          }

          abandoned_files_target_options = {
            :target_dir => "multi_sync",
            :destination_dir => "simple-with-abandoned-file",
            :credentials => {
              :region => "us-east-1",
              :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
              :aws_secret_access_key => "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",
            }
          }

          outdated_files_target_options = {
            :target_dir => "multi_sync",
            :destination_dir => "simple-with-outdated-file",
            :credentials => {
              :region => "us-east-1",
              :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
              :aws_secret_access_key => "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",
            }
          }

          local_source_options = {
            :source_dir => "/tmp/simple"
          }

          missing_files_target = MultiSync::AwsTarget.new(missing_files_target_options)
          abandoned_files_target = MultiSync::AwsTarget.new(abandoned_files_target_options)
          outdated_files_target = MultiSync::AwsTarget.new(outdated_files_target_options)

          expect(missing_files_target).to have(2).files
          expect(abandoned_files_target).to have(4).files
          expect(outdated_files_target).to have(3).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(3).files

          expect(outdated_files_target.files[1].body).to eq "outdated"

          MultiSync.run do
             target :aws, :missing_files_target, missing_files_target_options
             target :aws, :abandoned_files_target, abandoned_files_target_options
             target :aws, :outdated_files_target, outdated_files_target_options
             source :local, :simple, local_source_options.merge(:targets => [ :missing_files_target, :abandoned_files_target, :outdated_files_target ])
           end

          expect(missing_files_target).to have(3).files
          expect(abandoned_files_target).to have(3).files
          expect(outdated_files_target).to have(3).files
          expect(outdated_files_target.files[1].body).to eq "foo"

        end


      end

      context "without a destination_dir" do


        before do
          Fog.mock!

          connection = Fog::Storage.new(
            :provider => :aws,
            :region => "us-east-1",
            :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
            :aws_secret_access_key => "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",
          )

          directory = connection.directories.create(
            :key => "without_destination_dir",
            :public => true
          )

        end

        after do
          Fog.unmock!
        end

        it "should work" do

          without_destination_dir_target_options = {
            :target_dir => "without_destination_dir",
            :credentials => {
              :region => "us-east-1",
              :aws_access_key_id => "AKIAI263OMKGV6YDWWAQ",
              :aws_secret_access_key => "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",
            }
          }

          local_source_options = {
            :source_dir => "/tmp/simple"
          }

          without_destination_dir_target = MultiSync::AwsTarget.new(without_destination_dir_target_options)
          expect(without_destination_dir_target).to have(0).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(3).files

          MultiSync.run do
             target :aws, :without_destination_dir_target, without_destination_dir_target_options
             source :local, :simple, local_source_options.merge(:targets => :without_destination_dir_target )
           end

          expect(without_destination_dir_target).to have(3).files

        end

      end

    end

  end

end