require "spec_helper"

describe MultiSync::Target, fakefs: true do

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

  # context :validations do

  #   describe "without a destination_dir" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::Target.new }.to raise_error(ArgumentError, /destination_dir must be present/)
  #     end
  #   end

  #   describe "without a provider" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::Target.new(:destination_dir => root_dir) }.to raise_error(ArgumentError, /provider must be present and a symbol/)
  #     end
  #   end

  #   describe "without a symbol provider" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::Target.new(:provider => "aws", :destination_dir => root_dir) }.to raise_error(ArgumentError, /provider must be present and a symbol/)
  #     end
  #   end

  # end

  describe :files do

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

        Dir.glob("/tmp/simple/**/*").reject {|path| File.directory?(path) }.each do |path|
          directory.files.create(
            :key => path.gsub("/tmp/", ""),
            :body => File.open(path, "r"),
            :public => true
          )
        end

      end

      after do
        Fog.unmock!
      end

      let(:target) {
        MultiSync::Target.new(
          :provider => :aws,
          :provider_credentials => {
            :region => "us-east-1",
            :aws_access_key_id => "xxx",
            :aws_secret_access_key => "xxx"
          },
          :target_dir => "multi_sync",
          :destination_dir => "simple"
        )
      }

      it "should find files" do
        expect(target.files).to have(3).files
      end

      context :with_root do

        it "should return files with the root" do
          expect(target.files[0].path_with_root.to_s).to eq "multi_sync/simple/bar.txt"
        end

      end

      context :without_root do

        it "should return files without the root" do
          expect(target.files[0].path_without_root.to_s).to eq "bar.txt"
        end

      end

    end

    context :local do

      let(:target) {
        MultiSync::Target.new(
          :provider => :local,
          :provider_credentials => {
            :local_root => "/tmp"
          },
          :target_dir => "/tmp",
          :destination_dir => "simple"
        )
      }

      it "should find files" do
        expect(target.files).to have(3).files
      end

      context :with_root do

        it "should return files with the root" do
          expect(target.files[0].path_with_root.to_s).to eq "/tmp/simple/bar.txt"
        end

      end

      context :without_root do

        it "should return files without the root" do
          expect(target.files[0].path_without_root.to_s).to eq "bar.txt"
        end

      end

    end

  end

end