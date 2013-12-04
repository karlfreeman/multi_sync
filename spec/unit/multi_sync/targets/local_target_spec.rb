require 'spec_helper'

describe MultiSync::LocalTarget, fakefs: true do

  before do
    FileUtils.mkdir_p('/tmp/local-target')
    File.open('/tmp/local-target/foo.txt', 'w') do |f| f.write('foo') end
    File.open('/tmp/local-target/bar.txt', 'w') do |f| f.write('bar') end
    FileUtils.mkdir_p('/tmp/local-target/in-a-dir')
    File.open('/tmp/local-target/in-a-dir/baz.html', 'w') do |f| f.write('baz') end
  end

  describe :files do

    context :local do

      let(:target) {
        MultiSync::LocalTarget.new(
          target_dir: '/tmp',
          destination_dir: 'local-target',
          credentials: {
            local_root: '/tmp'
          }
        )
      }

      it 'should find files' do
        expect(target.files).to have(3).files
      end

      context :with_root do

        it 'should return files with the root' do
          expect(target.files[0].path_with_root.to_s).to eq '/tmp/local-target/bar.txt'
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
