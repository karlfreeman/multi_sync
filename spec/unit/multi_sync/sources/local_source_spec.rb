require 'spec_helper'

describe MultiSync::LocalSource do
  before do
    FileUtils.mkdir_p('tmp/local-source')
    File.open('tmp/local-source/foo.txt', File::CREAT | File::RDWR) do |f| f.write('foo') end
    File.open('tmp/local-source/bar.txt', File::CREAT | File::RDWR) do |f| f.write('bar') end
    FileUtils.mkdir_p('tmp/local-source/in-a-dir')
    File.open('tmp/local-source/in-a-dir/baz.html', File::CREAT | File::RDWR) do |f| f.write('baz') end
    File.open('tmp/local-source/in-a-dir/baz.txt', File::CREAT | File::RDWR) do |f| f.write('baz') end
  end

  describe :files do
    it 'should find files' do
      source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source')
      expect(source.files.size).to eq(4)
    end

    it 'should ignore found files' do
      source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source', include: '**/*', exclude: '*/*.html')
      expect(source.files.size).to eq(3)
    end

    it 'should find files (recursively)' do
      source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source', include: '**/*')
      expect(source.files.size).to eq(4)
    end

    it 'should find files (by type)' do
      source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source', include: '**/*.txt')
      expect(source.files.size).to eq(3)
    end

    context :with_root do
      it 'should return files with the root' do
        source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source')
        expect(source.files[0].path_with_root.to_s).to eq 'tmp/local-source/bar.txt'
      end
    end

    context :without_root do
      it 'should return files without the root' do
        source = MultiSync::LocalSource.new(source_dir: 'tmp/local-source')
        expect(source.files[0].path_without_root.to_s).to eq 'bar.txt'
      end
    end
  end
end
