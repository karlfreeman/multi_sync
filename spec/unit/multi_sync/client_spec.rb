require 'cgi'
require 'spec_helper'

describe MultiSync::Client do
  before do
    FileUtils.mkdir_p('tmp/simple')
    File.open('tmp/simple/foo.txt', File::CREAT | File::RDWR) do |f| f.write('foo') end
    File.open('tmp/simple/bar.txt', File::CREAT | File::RDWR) do |f| f.write('bar') end

    FileUtils.mkdir_p('tmp/simple/in-a-dir')
    File.open('tmp/simple/in-a-dir/baz.html', File::CREAT | File::RDWR) do |f| f.write('baz') end

    FileUtils.cp_r('tmp/simple', 'tmp/simple-with-missing-file')
    FileUtils.rm_r('tmp/simple-with-missing-file/foo.txt')

    FileUtils.cp_r('tmp/simple', 'tmp/simple-with-abandoned-file')
    File.open('tmp/simple-with-abandoned-file/baz.txt', File::CREAT | File::RDWR) do |f| f.write('baz') end

    FileUtils.cp_r('tmp/simple', 'tmp/simple-with-outdated-file')
    File.open('tmp/simple-with-outdated-file/foo.txt', File::CREAT | File::RDWR) do |f| f.write('not-foo') end

    FileUtils.mkdir_p('tmp/simple-empty')

    FileUtils.mkdir_p('tmp/complex')
    250.times do |i|
      File.open("tmp/complex/#{i.to_s.rjust(4, '0')}.txt", File::CREAT | File::RDWR) do |f| f.write('foo') end
    end

    FileUtils.mkdir_p('tmp/complex-empty')
  end

  context :sync do
    context :local do
      context 'simple' do
        it 'should work' do
          missing_files_target_options = {
            target_dir: 'tmp',
            destination_dir: 'simple-with-missing-file',
            credentials: {
              local_root: 'tmp'
            }
          }

          abandoned_files_target_options = {
            target_dir: 'tmp',
            destination_dir: 'simple-with-abandoned-file',
            credentials: {
              local_root: 'tmp'
            }
          }

          outdated_files_target_options = {
            target_dir: 'tmp',
            destination_dir: 'simple-with-outdated-file',
            credentials: {
              local_root: 'tmp'
            }
          }

          local_source_options = { source_dir: 'tmp/simple' }

          missing_files_target = MultiSync::LocalTarget.new(missing_files_target_options)
          abandoned_files_target = MultiSync::LocalTarget.new(abandoned_files_target_options)
          outdated_files_target = MultiSync::LocalTarget.new(outdated_files_target_options)

          expect(missing_files_target.files.size).to eq(2)
          expect(abandoned_files_target.files.size).to eq(4)
          expect(outdated_files_target.files.size).to eq(3)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(3)

          expect(outdated_files_target.files[1].body).to eq 'not-foo'

          MultiSync.run do
            local_target(missing_files_target_options)
            local_target(abandoned_files_target_options)
            local_target(outdated_files_target_options)
            local_source(local_source_options)
          end

          expect(missing_files_target.files.size).to eq(3)
          expect(abandoned_files_target.files.size).to eq(3)
          expect(outdated_files_target.files.size).to eq(3)
          expect(outdated_files_target.files[1].body).to eq 'foo'
        end
      end

      context 'complex' do
        it 'should work' do
          complex_empty_target_options = {
            target_dir: 'tmp',
            destination_dir: 'complex-empty',
            credentials: {
              local_root: 'tmp'
            }
          }

          local_source_options = { source_dir: 'tmp/complex' }

          complex_empty_target = MultiSync::LocalTarget.new(complex_empty_target_options)
          expect(complex_empty_target.files.size).to eq(0)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(250)

          MultiSync.run do
            local_source(local_source_options)
            local_target(complex_empty_target_options)
          end

          expect(complex_empty_target.files.size).to eq(250)
        end
      end
    end

    context :aws, fog: true do
      let(:credentials) { { region: 'us-east-1', aws_access_key_id: 'xxx', aws_secret_access_key: 'xxx' } }
      let(:connection) { Fog::Storage.new(credentials.merge(provider: :aws)) }
      context 'simple' do
        before do
          directory = connection.directories.create(key: 'simple', public: true)

          %w(simple simple-with-missing-file simple-with-abandoned-file simple-with-outdated-file).each do |fixture_name|
            Dir.glob("tmp/#{fixture_name}/**/*").reject { |path| File.directory?(path) }.each do |path|
              directory.files.create(
                key: path.gsub('tmp/', ''),
                body: File.open(path, 'r'),
                public: true
              )
            end
          end
        end

        it 'should work' do
          missing_files_target_options = {
            target_dir: 'simple',
            destination_dir: 'simple-with-missing-file',
            credentials: credentials
          }

          abandoned_files_target_options = {
            target_dir: 'simple',
            destination_dir: 'simple-with-abandoned-file',
            credentials: credentials
          }

          outdated_files_target_options = {
            target_dir: 'simple',
            destination_dir: 'simple-with-outdated-file',
            credentials: credentials
          }

          local_source_options = { source_dir: 'tmp/simple' }

          missing_files_target = MultiSync::AwsTarget.new(missing_files_target_options)
          abandoned_files_target = MultiSync::AwsTarget.new(abandoned_files_target_options)
          outdated_files_target = MultiSync::AwsTarget.new(outdated_files_target_options)

          expect(missing_files_target.files.size).to eq(2)
          expect(abandoned_files_target.files.size).to eq(4)
          expect(outdated_files_target.files.size).to eq(3)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(3)

          expect(outdated_files_target.files[1].body).to eq 'not-foo'

          MultiSync.run do
            local_source(local_source_options)
            aws_target(missing_files_target_options)
            aws_target(abandoned_files_target_options)
            aws_target(outdated_files_target_options)
          end

          expect(missing_files_target.files.size).to eq(3)
          expect(abandoned_files_target.files.size).to eq(3)
          expect(outdated_files_target.files.size).to eq(3)
          expect(outdated_files_target.files[1].body).to eq 'foo'
        end
      end

      context 'complex' do
        before do
          connection.directories.create(key: 'complex', public: true)
        end

        it 'should work' do
          complex_empty_target_options = {
            target_dir: 'complex',
            destination_dir: 'complex',
            credentials: credentials
          }

          local_source_options = { source_dir: 'tmp/complex' }

          complex_empty_target = MultiSync::AwsTarget.new(complex_empty_target_options)
          expect(complex_empty_target.files.size).to eq(0)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(250)

          MultiSync.run do
            local_source(local_source_options)
            aws_target(complex_empty_target_options)
          end

          expect(complex_empty_target.files.size).to eq(250)
        end
      end

      context 'without a destination_dir' do
        before do
          connection.directories.create(key: 'without_destination_dir', public: true)
        end

        it 'should work' do
          without_destination_dir_target_options = {
            target_dir: 'without_destination_dir',
            credentials: credentials
          }

          local_source_options = { source_dir: 'tmp/simple' }

          without_destination_dir_target = MultiSync::AwsTarget.new(without_destination_dir_target_options)
          expect(without_destination_dir_target.files.size).to eq(0)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(3)

          MultiSync.run do
            local_source(local_source_options)
            aws_target(without_destination_dir_target_options)
          end

          expect(without_destination_dir_target.files.size).to eq(3)
        end
      end

      context 'with resource_options' do
        before do
          connection.directories.create(key: 'with_resource_options', public: true)
        end

        it 'should work' do
          with_resource_options_target_options = {
            target_dir: 'with_resource_options',
            credentials: credentials
          }

          local_source_options = {
            source_dir: 'tmp/simple',
            resource_options: {
              cache_control: 'public, max-age=31557600',
              expires: CGI.rfc1123_date(Time.now + 31_557_600)
            }
          }

          with_resource_options_target = MultiSync::AwsTarget.new(with_resource_options_target_options)
          expect(with_resource_options_target.files.size).to eq(0)

          local_source = MultiSync::LocalSource.new(local_source_options)
          expect(local_source.files.size).to eq(3)

          MultiSync.run do
            local_source(local_source_options)
            aws_target(with_resource_options_target)
          end

          # dir = connection.directories.get('with_resource_options')
          # pp with_resource_options_target.files[0].file.cache_control

          expect(with_resource_options_target.files.size).to eq(3)
        end
      end
    end
  end
end
