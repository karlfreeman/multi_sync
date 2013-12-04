require 'spec_helper'

describe MultiSync::LocalResource, fakefs: true do

  before do
    FileUtils.mkdir_p('/tmp/local-resource')
    File.open('/tmp/local-resource/foo.txt', 'w') do |f| f.write('foo') end
  end

  describe :local do

    context :valid do

      it 'should return correct file details' do
        resource = MultiSync::LocalResource.new(
          with_root: Pathname.new('/tmp/local-resource/foo.txt'),
          without_root: Pathname.new('foo.txt')
        )
        expect(resource.body).to eq 'foo'
        expect(resource.content_length).to eq 3
        expect(resource.content_type).to eq 'text/plain'
        expect(resource.mtime).to eq Time.now
        expect(resource.etag).to eq 'acbd18db4cc2f85cedef654fccc4a4d8'
      end

    end

    context :known do

      it 'should return correct file details ( with overwritten info )' do
        resource = MultiSync::LocalResource.new(
          with_root: Pathname.new('/tmp/local-resource/foo.txt'),
          without_root: Pathname.new('foo.txt'),
          content_length: 42,
          mtime: Time.now - 1,
          etag: 'etag'
        )
        expect(resource.body).to eq 'foo'
        expect(resource.content_length).to eq 42
        expect(resource.content_type).to eq 'text/plain'
        expect(resource.mtime).to eq Time.now - 1
        expect(resource.etag).to eq 'etag'
      end

    end

    context :unknown do

      it 'should return default file details' do
        resource = MultiSync::LocalResource.new(
          with_root: Pathname.new('/tmp/local-resource/missing.txt'),
          without_root: Pathname.new('missing.txt')
        )
        expect(resource.body).to eq nil
        expect(resource.content_length).to eq 0
        expect(resource.content_type).to eq 'text/plain'
        expect(resource.mtime).to eq nil
        expect(resource.etag).to eq nil
      end

    end

  end

end
