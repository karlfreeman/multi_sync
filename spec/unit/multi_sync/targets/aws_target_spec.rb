require 'spec_helper'

describe MultiSync::AwsTarget, fog: true do
  before do
    FileUtils.mkdir_p('tmp/aws-target')
    File.open('tmp/aws-target/foo.txt', File::CREAT | File::RDWR) do |f| f.write('foo') end
    File.open('tmp/aws-target/bar.txt', File::CREAT | File::RDWR) do |f| f.write('bar') end
    FileUtils.mkdir_p('tmp/aws-target/in-a-dir')
    File.open('tmp/aws-target/in-a-dir/baz.html', File::CREAT | File::RDWR) do |f| f.write('baz') end

    connection = Fog::Storage.new(
      provider: :aws,
      region: 'us-east-1',
      aws_access_key_id: 'xxx',
      aws_secret_access_key: 'xxx'
    )

    directory = connection.directories.create(key: 'multi_sync', public: true)

    Dir.glob('tmp/aws-target/**/*').reject { |path| File.directory?(path) }.each do |path|
      directory.files.create(
        key: path.gsub('tmp/', ''),
        body: File.open(path, 'r'),
        public: true
      )
    end
  end

  describe :files do
    context :aws do
      let(:target) {
        MultiSync::AwsTarget.new(
          target_dir: 'multi_sync',
          destination_dir: 'aws-target',
          credentials: {
            region: 'us-east-1',
            aws_access_key_id: 'xxx',
            aws_secret_access_key: 'xxx'
          }
        )
      }

      it 'should find files' do
        expect(target.files).to have(3).files
      end

      context :with_root do
        it 'should return files with the root' do
          expect(target.files[0].path_with_root.to_s).to eq 'multi_sync/aws-target/bar.txt'
        end
      end

      context :without_root do
        it 'should return files without the root' do
          expect(target.files[0].path_without_root.to_s).to eq 'bar.txt'
        end
      end
    end
  end
end
