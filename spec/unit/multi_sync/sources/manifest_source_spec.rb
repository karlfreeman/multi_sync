require 'spec_helper'
require 'sprockets'

describe MultiSync::ManifestSource do

  before do

    FileUtils.rm_rf('/tmp/local-manifest')

    FileUtils.mkdir_p('/tmp/local-manifest')
    File.open('/tmp/local-manifest/foo.txt', 'w') do |f| f.write('foo') end
    File.open('/tmp/local-manifest/bar.txt', 'w') do |f| f.write('bar') end

    env = Sprockets::Environment.new('.') do |e|
      e.append_path('/tmp/local-manifest')
    end
    manifest = Sprockets::Manifest.new(env, '/tmp/local-manifest')
    manifest.compile('foo.txt', 'bar.txt')

  end

  # context :validations do

  #   describe "without a source_dir" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::LocalSource.new }.to raise_error(ArgumentError, /source_dir must be a directory/)
  #     end
  #   end

  #   describe "with a file as source_dir" do
  #     it "raises an ArgumentError" do
  #       expect{ MultiSync::LocalSource.new(:source_dir => "/tmp/local-source" + "foo.txt") }.to raise_error(ArgumentError, /source_dir must be a directory/)
  #     end
  #   end

  # end

  describe :files do

    it 'should find files' do
      source = MultiSync::ManifestSource.new(source_dir: '/tmp/local-manifest')
      expect(source.files).to have(2).files
    end

    context :with_root do

      it 'should return files with the root' do
        source = MultiSync::ManifestSource.new(source_dir: '/tmp/local-manifest')
        expect(source.files[0].path_with_root.to_s).to include '/tmp/local-manifest'
      end

    end

    context :without_root do

      it 'should return files without the root' do
        source = MultiSync::ManifestSource.new(source_dir: '/tmp/local-manifest')
        expect(source.files[0].path_without_root.to_s).to_not include '/tmp/local-manifest'
      end

    end

  end

end
