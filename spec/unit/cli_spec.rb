require "spec_helper"

describe MultiSync::Cli do
  describe "#hello" do
    context "when credentials are not provided" do
      subject { MultiSync::Cli.new }
      let(:output) { capture(:stdout) { subject.sync } }
    end
  end
end