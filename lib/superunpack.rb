require 'stringio'

class UnknownSizeParsableException < Exception; end

# The Parsable module is responsible of implementing the basics of binary parsing in all
# class that the SuperUnpack library uses.
module Parsable
  # Assign the current IO for parsing
  def input=(value)
    @input = value
  end
  # Returns the length in bytes of this object
  def length
    @length
  end
  # Move ahead in the stream and restugn the next character
  def next_char
    val = @input.getc
    if $DEBUG
      puts sprintf("%X", val)
    end
    return val
  end
  def parse_string(string)
    @input = StringIO.new(string)
    parse
  end
  # read length char using next_char and call decode_data
  def parse
    read_data
    decode_data
  end
  def read_data
    if $DEBUG
      puts "Reading data for #{self.class}"
    end
    @values = []
    if length != nil
      1.upto(@repeat) do
        value = ''
        1.upto(length) do
          value += next_char.chr
        end
        @values << value
      end
    else
      # unknown size
      raise UnknownSizeParsableException, "Size not set for \"#{self.class}\"", caller
    end
  end
  # standard decoder does nothing
  def decode_data
    @decoded_value = @values
  end
  def value
    if @decoded_value.length==1
      @decoded_value[0]
    else
      @decoded_value
    end
  end
end


class Complex
  class << self
    BASICFORMATS = [
    ['uint','C',1],
    ['blong','N',4], #big endian, network
    ['bshort','n',2],
    ['llong','V',4], # little endian, intel
    ['lshort','v',4]
    ]
    BASICFORMATS.each do |format|
      klass_name = format[0].capitalize
      unpack_format = format[1]
      size = format[2]
      eval %Q!
        class #{klass_name}
          include Parsable
          def initialize repeat=1
            @length=#{size}
            @repeat=repeat
            @decoded_value = []
          end
          def decode_data
            @values.each do |value|
              @decoded_value << value.unpack('#{unpack_format}')[0]
            end
          end
        end 
        def #{klass_name} name, repeat=1
          add_object name, #{klass_name}, repeat
        end
      !
    end 
    def element klass, name
      add_object name, klass
    end
    def CString name
      add_object name, CString
    end
    def PascalString name
      add_object name, PascalString
    end
    def Char name, length=1
      add_object name, Char, length
    end
    def add_object name, klass, extra = nil
      @content ||=Array.new
      line = [name, klass]
      line << extra if extra != nil
      @content << line
      begin
        attr_reader name
      rescue Exception=>e
        puts "Exception for #{name} object #{klass}"
        raise e
      end
    end
    def content
      @content
    end
  end
  def length
    lgt=0
    @inner_data.each do |data|
      lgt+=data[1].length
    end
    lgt
  end
  
  def content
    self.class.content
  end
  def value
    self
  end
  def input
    @input
  end
  def parse_string stringio
    @input = StringIO.new(stringio)
    parse
  end
  def parse stringio = nil
    puts "Will attempt to match this structure: " + content.inspect if $DEBUG
    if stringio!=nil
      @input = stringio
    end
    content.each do |element|
      extra = nil
      if element.length == 3
        name, type, extra = element
      else
        name, type = element
      end
      @inner_data = Array.new
      if extra != nil 
        data = type.new(extra)
      else
        data = type.new
      end
      if type.ancestors.include? Complex 
        data.parse @input
      else
        data.input = @input
        data.parse
      end
      @inner_data << [name, data]
      instance_variable_set("@#{name}", data.value)
    end
  end
  
end
class CString 
  include Parsable
  def initialize
    @length = nil
  end
  def read_data
    if $DEBUG
      puts "Reading data for #{self.class}"
    end
    @value = ''
    value = next_char
    while value!=0
      @value += value.chr
      value = next_char
    end
    @values = [@value]
  end
  def length 
    @value.length+1
  end
end
class Char
  include Parsable
  def initialize length=1
    @length = length
  end
  def read_data
    if $DEBUG
      puts "Reading data for #{self.class}"
    end
    
    @value = ''
    while @value.length < @length 
      value = next_char
      @value += value.chr
      next if @length == 1
    end
    @values = [@value]
    if $DEBUG
      puts "done #{@values.inspect} #{self.class}"
    end
    
  end
end
class PascalString
  include Parsable
  def initialize
    @length = nil
  end
  def read_data
    @value = ''
    length = next_char
    if length == 255
      length = next_char
      length = 255 * 255 + length
    else
      length = length *255  + next_char
    end
    if length == 0 or length == 255 * (255 +1)
      @values = [ "" ]
      return
    end


    puts "length:#{length}" if $DEBUG
    0.upto(length-1) do
      @value += next_char.chr
    end
    @values = [ @value ]
  end
end

