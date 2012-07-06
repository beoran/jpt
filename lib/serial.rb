require 'termios'

# Class to help with serial communication.
# Usees Termios for settings
class Serial
  
  class Error < ::Exception
  end
  
  attr_accessor :rw_sleep
  # time to delay between a read and a write in a "readwrite"
  
  private
  
  # :nodoc: Parses the parity bits into termios settings
  def self.parse_parity(parity, action = :ignore)
    iflag = 0
    case action
      when :ignore
        iflag = Termios::IGNPAR
      when :mark     
        iflag = Termios::PARMRK
      else 
        raise "Unknown action on parity error"      
    end
    cflag = 0
    case parity
      when :none 
        cflag = 0
      when :even   
        cflag = Termios::PARENB
      when :odd 
        cflag = Termios::PARODD
        raise "Unknown parity"  
    end
    return iflag, cflag
  end
  
  # :nodoc: Parses the stop bits into termios settings
  def self.parse_stopbits(stop)
    if stop > 1 
      return Termios::CSTOPB
    else 
      return 0   
    end
  end  
  
  # :nodoc: Parses the bits into termios settings
  def self.parse_bits(bits)
    if bits > 7 
      return Termios::CS8
    elsif bits == 7
      return Termios::CS7
    elsif  bits == 6
      return Termios::CS6
    elsif  bits == 5
      return Termios::CS5
    else 
      raise "Unknown amount of bits"  
    end
  end  
  
  public
  
  DEFAULT_READ_SIZE = 1024
  
  attr_accessor :read_timeout
  attr_accessor :read_size
  
  # Sets up the serial port
  def initialize(filename, baud = 9600, bits = 8, stop = 1, parity = :none, hwflow = true)
    iflag, cflag    = self.class.parse_parity(parity)
    cflag          |= self.class.parse_bits(bits)
    cflag          |= self.class.parse_stopbits(stop)
    cflag          |= Termios::CREAD # Allow reading from the serial port !
    cflag          |= Termios::CLOCAL
    # This is needed to ignore handshake errors (I think).
    # By setting CLOCAL, the device ignores modem control lines. 
    # Communication may get out of whack without this. 
    if hwflow # use hardware flow control if needed
      cflag        |= Termios::CRTSCTS
    end

    @filename       = filename
    @file           = File.open(filename, File::RDWR | File::NOCTTY)
    # Lock device file to prevent duplicate access, which causes tons of problems.
    unless @file.flock(File::LOCK_EX | File::LOCK_NB)
      # Serial::Error.new
      warn("Could not lock #{filename}! Serial device is in use by another program or process!")
    end

    @termios        = Termios.new_termios(@file)
    @termios.iflag  = iflag
    @termios.cflag  = cflag
    @termios.raw()  # Set raw mode
    @termios.cc[Termios::VSTART] = 021
    @termios.cc[Termios::VSTOP]  = 023
    # Control flow characters should remain set, it seems.
    @termios.ispeed = baud
    @termios.ospeed = baud
    @termios.set()  # Apply new terminal io settings to the serial device 
    @read_timeout   = 1.0
    @read_size      = DEFAULT_READ_SIZE
    if(block_given?) 
      begin 
        yield self
      ensure
        self.close
      end
    end 
  end
  
  # Closes the serial device
  def close
    @file.flush # flush output
    res = @file.flock(File::LOCK_UN) # Remove file lock
    @file.close
    @file = nil
  end
  
  # Writes to the serial device
  def write(to_write)
    return @file.syswrite(to_write)    
  end
  
  # Applies expect on the data read from the serial port
  def expect(pattern, timeout= 1.0)
    timeout ||= @read_timeout
    return @file.expect(pattern, timeout)
  end
  
  
  # Reads one time from the device with the given maximum buffer length
  def read(read_size = nil)
    read_size ||= @read_size
    return @file.sysread(read_size)
  end
  
  # Returns true if the serial device is ready to be read, false if not
  def read_ok?(timeout = 1.0)
    timeout ||= @read_timeout
    res = Kernel.select([@file], nil, nil, timeout)
    return res
  end
  
  # Returns true if the serial device is ready to be written to, 
  # false if not
  def write_ok?(timeout = 1.0)
    timeout ||= @read_timeout
    res = Kernel.select(nil, [@file], nil, timeout)
    return res
  end
  
  
  # Reads all data available from the serial device.
  def read_all(timeout = 1.0)
    timeout   ||= @read_timeout
    buf         = nil
    while read_ok?(timeout)
      buf     ||= ''
      buf     << self.read(timeout)
    end
    return buf
  end
  

  # Write a value to the port, check if ready to read for @rw_sleep time
  # and then read back the response.
  def write_read(to_write, timeout = nil, read_size = nil)
    self.write(to_write)
    return nil unless self.read_ok?(timeout)      
    if read_size == :line 
      return @file.readline
    elsif read_size
      return self.read(read_size)
    else
      return read_all()
    end
  end
  
  # Opens a new serial RS232 connection
  def self.serial(params = {})
    filename = params[:filename]
    baud     = params[:baud]    || 9600
    bits     = params[:bits]    || 8
    stop     = params[:stop]    || 1
    hwflow   = params[:hwflow]  || false
    serial = Serial.new(filename, baud, bits, stop, hwflow)
    serial.read_timeout  = params[:read_timeout] rescue nil 
    # initialize and set control, ignoring certain 
    # platform-specific exceptions.
    serial.rw_sleep      = params[:rw_sleep]
    if block_given?
      begin
        yield serial
      ensure
        serial.close
      end
    else
      return serial 
    end
  end

end # class Serial


