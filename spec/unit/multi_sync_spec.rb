require "spec_helper"

describe MultiSync do

  describe :version do
    subject { MultiSync::VERSION }
    it { should be_kind_of(String) }
  end

end