require "spec_helper"

describe MultiSync::LocalResource, fakefs: true do

  before do
    FileUtils.mkdir_p("/tmp/local-resource")
    File.open("/tmp/local-resource/foo.txt", "w") do |f| f.write("foo") end
  end

  describe :local do

    describe :state do

      it "should be work" do
        resource = MultiSync::LocalResource.new(
          :with_root => Pathname.new("/tmp/local-resource/foo.txt"),
          :without_root => Pathname.new("foo.txt")
        )
        expect(resource.body).to eq "foo"
        expect(resource.content_length).to eq 3
        expect(resource.content_type).to eq "text/plain"
        expect(resource.etag).to eq "acbd18db4cc2f85cedef654fccc4a4d8"
      end

      it "should be work" do
        resource = MultiSync::LocalResource.new(
          :with_root => Pathname.new("/tmp/local-resource/missing.txt"),
          :without_root => Pathname.new("missing.txt")
        )
        expect(resource.body).to eq ""
        expect(resource.content_length).to eq 0
        expect(resource.content_type).to eq "text/plain"
        expect(resource.etag).to eq ""
      end

    end

  end

end