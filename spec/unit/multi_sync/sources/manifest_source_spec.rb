require 'spec_helper'
require 'sprockets'

describe MultiSync::ManifestSource do
  before do
    FileUtils.mkdir_p('tmp/local-manifest')
    File.open('tmp/local-manifest/foo.txt', File::CREAT | File::RDWR) do |f| f.write('foo') end
    File.open('tmp/local-manifest/bar.txt', File::CREAT | File::RDWR) do |f| f.write('bar') end
    FileUtils.mkdir_p('tmp/local-manifest/in-a-dir')
    File.open('tmp/local-manifest/in-a-dir/baz.html', File::CREAT | File::RDWR) do |f| f.write('baz') end
    File.open('tmp/local-manifest/in-a-dir/baz.txt', File::CREAT | File::RDWR) do |f| f.write('baz') end

    env = Sprockets::Environment.new('.') do |e|
      e.append_path('tmp/local-manifest')
    end
    manifest = Sprockets::Manifest.new(env, 'tmp/local-manifest')
    manifest.compile('foo.txt', 'bar.txt', 'in-a-dir/baz.html', 'in-a-dir/baz.txt')
  end

  describe :files do
    it 'should find files' do
      source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest')
      expect(source.files).to have(4).files
    end

    it 'should ignore found files' do
      source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest', include: '**/*', exclude: '*/*.html')
      expect(source.files).to have(3).files
    end

    it 'should find files (recursively)' do
      source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest', include: '**/*')
      expect(source.files).to have(4).files
    end

    it 'should find files (by type)' do
      source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest', include: '**/*.txt')
      expect(source.files).to have(3).files
    end

    context :with_root do
      it 'should return files with the root' do
        source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest')
        expect(source.files[0].path_with_root.to_s).to include 'tmp/local-manifest'
      end
    end

    context :without_root do
      it 'should return files without the root' do
        source = MultiSync::ManifestSource.new(source_dir: 'tmp/local-manifest')
        expect(source.files[0].path_without_root.to_s).to_not include 'tmp/local-manifest'
      end
    end
  end
end
