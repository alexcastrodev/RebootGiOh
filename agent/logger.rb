module AppLogger
  def self.info(msg)
    log('INFO', msg)
  end

  def self.error(msg)
    log('ERROR', msg)
  end

  private

  def self.log(level, msg)
    $stdout.puts "[#{level}] #{msg}"
    $stdout.flush
  end
end
