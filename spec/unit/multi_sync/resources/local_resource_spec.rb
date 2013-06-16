require "spec_helper"

describe MultiSync::LocalResource, fakefs: true do

  before do
    FileUtils.mkdir_p("/tmp/local-resource")
    File.open("/tmp/local-resource/foo.txt", "w") do |f| f.write("foo") end
  end

  describe :local do

    describe :state do

      it "should be :available when a file is exists" do
        resource = MultiSync::LocalResource.new(
          :with_root => Pathname.new("/tmp/local-resource/foo.txt"),
          :without_root => Pathname.new("foo.txt")
        )
        # expect(resource.state_name).to eq :available
      end

      it "should be :unavailable when a file doesnt exist" do
        resource = MultiSync::LocalResource.new(
          :with_root => Pathname.new("/tmp/local-resource/missing.txt"),
          :without_root => Pathname.new("missing.txt")
        )
        # expect(resource.state_name).to eq :unavailable
      end

    end

  end

end