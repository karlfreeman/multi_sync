require 'tmpdir'
require 'pathname'
require 'fileutils'
RSpec.configure do |config|
  config.around do |ex|
    tmpdir = Dir.mktmpdir('multi_sync')
    tmp = Pathname.new File.join(tmpdir, ex.__id__.to_s)
    pwd = Dir.pwd
    FileUtils.mkdir(tmp)
    begin  
      Dir.chdir(tmp)
      ex.run
      Dir.chdir(pwd)
    ensure
      FileUtils.remove_entry_secure tmp
    end
  end
end