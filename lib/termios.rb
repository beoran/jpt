# Termios for Linux using ruby/dl
module Termios
  
    VINTR     = 0
    VQUIT     = 1
    VERASE    = 2
    VKILL     = 3
    VEOF      = 4
    VTIME     = 5
    VMIN      = 6
    VSWTC     = 7
    VSTART    = 8
    VSTOP     = 9
    VSUSP     = 10
    VEOL      = 11
    VREPRINT  = 12
    VDISCARD  = 13
    VWERASE   = 14
    VLNEXT    = 15
    VEOL2     = 16
  
    IGNBRK    = 0000001
    BRKINT    = 0000002
    IGNPAR    = 0000004
    PARMRK    = 0000010
    INPCK     = 0000020
    ISTRIP    = 0000040
    INLCR     = 0000100
    IGNCR     = 0000200
    ICRNL     = 0000400
    IUCLC     = 0001000
    IXON      = 0002000
    IXANY     = 0004000
    IXOFF     = 0010000
    IMAXBEL   = 0020000
    IUTF8     = 0040000
  
    OPOST     = 0000001
    OLCUC     = 0000002
    ONLCR     = 0000004
    OCRNL     = 0000010
    ONOCR     = 0000020
    ONLRET    = 0000040
    OFILL     = 0000100
    OFDEL     = 0000200
    VTDLY     = 0040000
    VT0       = 0000000
    VT1       = 0040000
    XTABS     = 0014000
    CBAUD     = 0010017
    B0        = 0000000   # hang up 
    B50       = 0000001
    B75       = 0000002
    B110      = 0000003
    B134      = 0000004
    B150      = 0000005
    B200      = 0000006
    B300      = 0000007
    B600      = 0000010
    B1200     = 0000011
    B1800     = 0000012
    B2400     = 0000013
    B4800     = 0000014
    B9600     = 0000015
    B19200    = 0000016
    B38400    = 0000017
    EXTA      = B19200
    EXTB      = B38400
    CSIZE     = 0000060
    CS5       = 0000000
    CS6       = 0000020
    CS7       = 0000040
    CS8       = 0000060
    CSTOPB    = 0000100
    CREAD     = 0000200
    PARENB    = 0000400
    PARODD    = 0001000
    HUPCL     = 0002000
    CLOCAL    = 0004000
    CBAUDEX   = 0010000
    B57600    = 0010001
    B115200   = 0010002
    B230400   = 0010003
    B460800   = 0010004
    B500000   = 0010005
    B576000   = 0010006
    B921600   = 0010007
    B1000000  = 0010010
    B1152000  = 0010011
    B1500000  = 0010012
    B2000000  = 0010013
    B2500000  = 0010014
    B3000000  = 0010015
    B3500000  = 0010016
    B4000000  = 0010017
    MAX_BAUD  = B4000000
    CIBAUD    = 002003600000    # input baud rate (not used) */
    CMSPAR    = 010000000000    # mark or space (stick) parity */
    CRTSCTS   = 020000000000    # flow control */
    ISIG      = 0000001
    ICANON    = 0000002
    XCASE     = 0000004
    ECHO      = 0000010
    ECHOE     = 0000020
    ECHOK     = 0000040
    ECHONL    = 0000100
    NOFLSH    = 0000200
    TOSTOP    = 0000400
    ECHOCTL   = 0001000
    ECHOPRT   = 0002000
    ECHOKE    = 0004000
    FLUSHO    = 0010000
    PENDIN    = 0040000
    IEXTEN    = 0100000
    TCOOFF    = 0
    TCOON     = 1
    TCIOFF    = 2
    TCION     = 3
    TCIFLUSH  = 0
    TCOFLUSH  = 1
    TCIOFLUSH = 2
    TCSANOW   = 0
    TCSADRAIN = 1
    TCSAFLUSH = 2
    
    SPEED_BAUD= { 0       => B0      , 50     => B50      , 75      => B75     , 
                  110     => B110    , 134    => B134     , 150     => B150    , 
                  200     => B200    , 300    => B300     , 600     => B600    ,
                  1200    => B1200   , 1200   => B1800    , 2400    => B2400   ,
                  4800    => B4800   , 9600   => B9600    , 19200   => B19200  ,
                  38400   => B38400  , 57600  => B57600   , 115200  => B115200 ,
                  230400  => B230400 , 460800 => B460800  , 500000  => B500000 ,
                  576000  => B576000 , 921600 => B921600  , 1000000 => B1000000,
                  1152000 => B1152000, 1500000=> B1500000 , 2000000 => B2000000,
                  2500000 => B2500000, 3000000=> B3000000 , 3500000 => B3500000,
                  4000000 => B4000000    
                }
                 
    BAUD_SPEED= {}
    SPEED_BAUD.each_pair { |k,v| BAUD_SPEED[v] = k }

    
    
    require "dl"
    require "dl/import"
    require "dl/struct"
      
    # Determine where the c library to load is  
      
    case RUBY_PLATFORM
      when /cygwin/
        LIBC_SO = "cygwin1.dll"
        LIBM_SO = "cygwin1.dll"
      when /linux/
        # Multi-architecture aware distribitions.
        if (['a'].pack('P').length  > 4) # 64 bits mode
          LIBC_SO = '/lib/x86_64-linux-gnu/libc.so.6'
          LIBM_SO = '/lib/x86_64-linux-gnu/libm.so.6'
        elsif File.exist?('/lib/i386-linux-gnu/libc.so.6')
          LIBC_SO = '/lib/i386-linux-gnu/libc.so.6'
          LIBM_SO = '/lib/i386-linux-gnu/libm.so.6'
        else  
          LIBC_SO = "/lib/libc.so.6"
          LIBM_SO = "/lib/libm.so.6"
        end  
      when /mingw/, /mswin32/
        LIBC_SO = "msvcrt.dll"
        LIBM_SO = "msvcrt.dll"
      else
        LIBC_SO = ARGV[0]
        LIBM_SO = ARGV[1]
        if( !(LIBC_SO && LIBM_SO) )
          $stderr.puts("Could not load libc: #{$0} <libc> <libm>")
          exit
        end
    end
  
      
      
      
    if defined? DL::Importable # Ruby 1.8
      extend DL::Importable
    else
      extend DL::Importer # Ruby 1.9
    end   
      
    dlload LIBC_SO
    
    typealias("uint" , "unsigned int")
    typealias("uchar", "unsigned char")


    
    CTermios   = struct [ "uint iflag",
                          "uint oflag",
                          "uint cflag",
                          "uint lflag",
                          "uchar line",
                          "uchar cc[32]",
                          "uint ispeed",
                          "uint ospeed" ] 
                            
    extern "int tcgetattr(int, Termios *)"  
    extern "int tcsetattr(int, int, Termios *)"
    extern "int tcsendbreak(int, int)"
    extern "int tcdrain(int)"
    extern "int tcflush(int, int)"
    extern "int tcflow(int, int)"
    extern "void cfmakeraw(Termios *)"
    extern "unsigned int cfgetispeed(Termios *)"
    extern "unsigned int cfgetospeed(Termios *)"
    extern "int cfsetispeed(Termios *, uint)"
    extern "int cfsetospeed(Termios *, uint)"
    
    def self.new_ctermios
      tiosptr = DL.malloc(Termios::CTermios.size)
      tios    = Termios::CTermios.new(tiosptr)
      return tios
    end  
  
      
    class RTermios
      
      attr_accessor :file 
      # The file that this termios settings are read from and set to by default.  
    
      def initialize(file = nil)
        @file    = file
        @termios = Termios.new_ctermios
        if file
          self.get(file)
        end 
            
           
      end
      
      def get(file = nil)
        file ||= @file
        Termios.tcgetattr(file.fileno, @termios)
      end
      
      def set(file = nil)
        file ||= @file
        Termios.tcsetattr(file.fileno, Termios::TCSANOW, @termios)
      end
      
      def sendbreak(how)
        self.class.sendbreak(@file, how)
      end
      
      def drain(how)
        self.class.drain(@file, how)
      end
      
      def flush(how)
        self.class.flush(@file, how)
      end
      
      def flow(how)
        self.class.flow(@file, how)
      end
      
      def raw()
        Termios.cfmakeraw(@termios)
      end
      
      
      def self.speed_to_baud(speed)
        return Termios::SPEED_BAUD[speed]
      end
      
            
      def self.baud_to_speed(baud)
        return Termios::BAUD_SPEED[baud]
      end

      
      
      def self.sendbreak(file, how)
        Termios.tcsendbreak(file.fileno, how)
      end
      
      def self.drain(file)
        Termios.tcdrain(file.fileno)
      end
      
      def self.flush(file, how)
        Termios.tcflush(file.fileno, how)
      end
        
      def self.flow(file, how)
        Termios.tcflow(file.fileno, how)
      end
              
      def iflag
        return @termios.iflag
      end
      
      def oflag
        return @termios.oflag
      end
      
      def cflag
        return @termios.cflag
      end
      
      def line
        return @termios.line
      end
      
      def cc
        return @termios.cc
      end
      
      def ispeed
        aid= Termios.cfgetispeed(@termios)
        return self.class.baud_to_speed(aid)         
      end
      
      def ospeed        
        aid = Termios.cfgetospeed(@termios)
        return self.class.baud_to_speed(aid)
      end
      
      def iflag=(value)
        return @termios.iflag = value
      end
      
      def oflag=(value)
        return @termios.oflag = value
      end
      
      def cflag=(value)
        return @termios.cflag = value
      end
      
      def line=(value)
        return @termios.line = value
      end
      
      def ispeed=(value)
        speed = self.class.speed_to_baud(value)
        return nil unless speed
        Termios.cfsetispeed(@termios, speed)
        return self.ispeed
      end
      
      def ospeed=(value)
        speed = self.class.speed_to_baud(value)
        return nil unless speed
        Termios.cfsetospeed(@termios, value)
        return self.ospeed
      end
      
    end
      
    
    def self.new_termios(file = nil)
      return Termios::RTermios.new(file)
    end  
      
      
end # module Termios
