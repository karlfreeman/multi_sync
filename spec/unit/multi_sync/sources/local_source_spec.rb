require "spec_helper"

describe MultiSync::LocalSource, fakefs: true do

  before do
    FileUtils.mkdir_p("/tmp/source")
    File.open("/tmp/source/foo.txt", "w") do |f| f.write("foo") end
    File.open("/tmp/source/bar.txt", "w") do |f| f.write("bar") end
    FileUtils.mkdir_p("/tmp/source/in-a-dir")
    File.open("/tmp/source/in-a-dir/baz.html", "w") do |f| f.write("baz") end
  end

  # context :validations do

  #   describe "without a source_dir" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::LocalSource.new }.to raise_error(ArgumentError, /source_dir must be a directory/)
  #     end
  #   end

  #   describe "with a file as source_dir" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::LocalSource.new(:source_dir => "/tmp/source" + "foo.txt") }.to raise_error(ArgumentError, /source_dir must be a directory/)
  #     end
  #   end

  # end

  describe :files do

    it "should find files" do
      source = MultiSync::LocalSource.new(:source_dir => "/tmp/source")
      expect(source.files).to have(3).files
    end

    it "should ignore found files" do
      source = MultiSync::LocalSource.new(:source_dir => "/tmp/source", :include => "**/*", :exclude => "*/*.html")
      expect(source.files).to have(2).files
    end

    it "should find files (recursively)" do
      source = MultiSync::LocalSource.new(:source_dir => "/tmp/source", :include => "**/*")
      expect(source.files).to have(3).files
    end

    it "should find files (by type)" do
      source = MultiSync::LocalSource.new(:source_dir => "/tmp/source", :include => "*.txt")
      expect(source.files).to have(2).files
    end

    it "should find files (by directory)" do
      source = MultiSync::LocalSource.new(:source_dir => "/tmp/source", :include => "in-a-dir/*")
      expect(source.files).to have(1).files
    end

    context :with_root do

      it "should return files with the root" do
        source = MultiSync::LocalSource.new(:source_dir => "/tmp/source")
        expect(source.files[0].path_with_root.to_s).to eq "/tmp/source/bar.txt"
      end

    end

    context :without_root do

      it "should return files without the root" do
        source = MultiSync::LocalSource.new(:source_dir => "/tmp/source")
        expect(source.files[0].path_without_root.to_s).to eq "bar.txt"
      end

    end

  end

end