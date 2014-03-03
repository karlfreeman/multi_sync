require 'spec_helper'

describe MultiSync::Client, fakefs: true do

  before do
    FileUtils.mkdir_p('/tmp/simple')
    File.open('/tmp/simple/foo.txt', 'w') do |f| f.write('foo') end
    File.open('/tmp/simple/bar.txt', 'w') do |f| f.write('bar') end
    FileUtils.mkdir_p('/tmp/simple/in-a-dir')
    File.open('/tmp/simple/in-a-dir/baz.html', 'w') do |f| f.write('baz') end

    FileUtils.cp_r('/tmp/simple', '/tmp/simple-with-missing-file')
    FileUtils.rm_r('/tmp/simple-with-missing-file/foo.txt')

    FileUtils.cp_r('/tmp/simple', '/tmp/simple-with-abandoned-file')
    File.open('/tmp/simple-with-abandoned-file/baz.txt', 'w') do |f| f.write('baz') end

    FileUtils.cp_r('/tmp/simple', '/tmp/simple-with-outdated-file')
    File.open('/tmp/simple-with-outdated-file/foo.txt', 'w') do |f| f.write('not-foo') end

    FileUtils.mkdir_p('/tmp/complex')
    50.times do
      File.open("/tmp/complex/#{SecureRandom.urlsafe_base64}.txt", 'w') do |f| f.write(SecureRandom.random_bytes) end
    end

    FileUtils.mkdir_p('/tmp/complex-empty')
  end

  context :sync do
    context :local do
      context 'simple' do
        it 'should work' do
          missing_files_target_options = {
            type: :local,
            target_dir: '/tmp',
            destination_dir: 'simple-with-missing-file',
            credentials: {
              local_root: '/tmp'
            }
          }

          abandoned_files_target_options = {
            type: :local,
            target_dir: '/tmp',
            destination_dir: 'simple-with-abandoned-file',
            credentials: {
              local_root: '/tmp'
            }
          }

          outdated_files_target_options = {
            type: :local,
            target_dir: '/tmp',
            destination_dir: 'simple-with-outdated-file',
            credentials: {
              local_root: '/tmp'
            }
          }

          local_source_options = {
            type: :local,
            source_dir: '/tmp/simple'
          }

          missing_files_target = MultiSync::LocalTarget.new(missing_files_target_options)
          abandoned_files_target = MultiSync::LocalTarget.new(abandoned_files_target_options)
          outdated_files_target = MultiSync::LocalTarget.new(outdated_files_target_options)

          expect(missing_files_target).to have(2).files
          expect(abandoned_files_target).to have(4).files
          expect(outdated_files_target).to have(3).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(3).files

          expect(outdated_files_target.files[1].body).to eq 'not-foo'

          MultiSync.run do
            target :missing_files_target, missing_files_target_options
            target :abandoned_files_target, abandoned_files_target_options
            target :outdated_files_target, outdated_files_target_options
            source :simple, local_source_options.merge(targets: [:missing_files_target, :abandoned_files_target, :outdated_files_target])
          end

          expect(missing_files_target).to have(3).files
          expect(abandoned_files_target).to have(3).files
          expect(outdated_files_target).to have(3).files
          expect(outdated_files_target.files[1].body).to eq 'foo'
        end
      end

      context 'complex' do
        it 'should work' do
          complex_empty_target_options = {
            type: :local,
            target_dir: '/tmp',
            destination_dir: 'complex-empty',
            credentials: {
              local_root: '/tmp'
            }
          }

          local_source_options = {
            type: :local,
            source_dir: '/tmp/complex'
          }

          complex_empty_target = MultiSync::LocalTarget.new(complex_empty_target_options)
          expect(complex_empty_target).to have(0).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(50).files

          MultiSync.run do
            target :complex_empty_target, complex_empty_target_options
            source :complex, local_source_options.merge(targets: [:complex_empty_target])
          end

          expect(complex_empty_target).to have(50).files
        end
      end
    end

    context :aws, fog: true do
      context 'simple' do
        before do
          connection = Fog::Storage.new(
            provider: :aws,
            region: 'us-east-1',
            aws_access_key_id: 'xxx',
            aws_secret_access_key: 'xxx'
          )

          directory = connection.directories.create(key: 'multi_sync', public: true)

          %w(simple simple-with-missing-file simple-with-abandoned-file simple-with-outdated-file).each do |fixture_name|
            Dir.glob("/tmp/#{fixture_name}/**/*").reject { |path| File.directory?(path) }.each do |path|
              directory.files.create(
                key: path.gsub('/tmp/', ''),
                body: File.open(path, 'r'),
                public: true
              )
            end
          end
        end

        it 'should work' do
          missing_files_target_options = {
            type: :aws,
            target_dir: 'multi_sync',
            destination_dir: 'simple-with-missing-file',
            credentials: {
              region: 'us-east-1',
              aws_access_key_id: 'xxx',
              aws_secret_access_key: 'xxx'
            }
          }

          abandoned_files_target_options = {
            type: :aws,
            target_dir: 'multi_sync',
            destination_dir: 'simple-with-abandoned-file',
            credentials: {
              region: 'us-east-1',
              aws_access_key_id: 'xxx',
              aws_secret_access_key: 'xxx'
            }
          }

          outdated_files_target_options = {
            type: :aws,
            target_dir: 'multi_sync',
            destination_dir: 'simple-with-outdated-file',
            credentials: {
              region: 'us-east-1',
              aws_access_key_id: 'xxx',
              aws_secret_access_key: 'xxx'
            }
          }

          local_source_options = {
            type: :local,
            source_dir: '/tmp/simple'
          }

          missing_files_target = MultiSync::AwsTarget.new(missing_files_target_options)
          abandoned_files_target = MultiSync::AwsTarget.new(abandoned_files_target_options)
          outdated_files_target = MultiSync::AwsTarget.new(outdated_files_target_options)

          expect(missing_files_target).to have(2).files
          expect(abandoned_files_target).to have(4).files
          expect(outdated_files_target).to have(3).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(3).files

          expect(outdated_files_target.files[1].body).to eq 'not-foo'

          MultiSync.run do
            target :missing_files_target, missing_files_target_options
            target :abandoned_files_target, abandoned_files_target_options
            target :outdated_files_target, outdated_files_target_options
            source :simple, local_source_options.merge(targets: [:missing_files_target, :abandoned_files_target, :outdated_files_target])
          end

          expect(missing_files_target).to have(3).files
          expect(abandoned_files_target).to have(3).files
          expect(outdated_files_target).to have(3).files
          expect(outdated_files_target.files[1].body).to eq 'foo'
        end
      end

      context 'complex' do
        before do
          connection = Fog::Storage.new(
            provider: :aws,
            region: 'us-east-1',
            aws_access_key_id: 'xxx',
            aws_secret_access_key: 'xxx'
          )

          connection.directories.create(key: 'multi_sync', public: true)
        end

        it 'should work' do
          complex_empty_target_options = {
            type: :aws,
            target_dir: 'multi_sync',
            destination_dir: 'complex-empty',
            credentials: {
              region: 'us-east-1',
              aws_access_key_id: 'xxx',
              aws_secret_access_key: 'xxx'
            }
          }

          local_source_options = {
            type: :local,
            source_dir: '/tmp/complex'
          }

          complex_empty_target = MultiSync::AwsTarget.new(complex_empty_target_options)
          expect(complex_empty_target).to have(0).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(50).files

          MultiSync.run do
            target :complex_empty_target, complex_empty_target_options
            source :complex, local_source_options.merge(targets: [:complex_empty_target])
          end

          expect(complex_empty_target).to have(50).files
        end
      end

      context 'without a destination_dir' do
        before do
          connection = Fog::Storage.new(
            provider: :aws,
            region: 'us-east-1',
            aws_access_key_id: 'xxx',
            aws_secret_access_key: 'xxx'
          )

          connection.directories.create(key: 'without_destination_dir', public: true)
        end

        it 'should work' do
          without_destination_dir_target_options = {
            type: :aws,
            target_dir: 'without_destination_dir',
            credentials: {
              region: 'us-east-1',
              aws_access_key_id: 'xxx',
              aws_secret_access_key: 'xxx'
            }
          }

          local_source_options = {
            type: :local,
            source_dir: '/tmp/simple'
          }

          without_destination_dir_target = MultiSync::AwsTarget.new(without_destination_dir_target_options)
          expect(without_destination_dir_target).to have(0).files

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source).to have(3).files

          MultiSync.run do
            target :without_destination_dir_target, without_destination_dir_target_options
            source :local, local_source_options.merge(targets: :without_destination_dir_target)
          end

          expect(without_destination_dir_target).to have(3).files
        end
      end
    end
  end
end
