
class FileLock
  
  def initialize(lockFileName)
    @lockFileName = lockFileName + ".lock"
    
    unless( File.exist?(@lockFileName) )
      createLockFile
    end
  end
  
  def createLockFile
    File.open(@lockFileName, "w+") do |file|
      file.write("lock")
    end
  end
  
  def lock()
    open(@lockFileName, "r+") do |f|
      f.flock(File::LOCK_EX)
      begin
        yield block_given?
      ensure
        f.flush()
        f.flock(File::LOCK_UN)
      end
    end
  end
  
end
