require 'test/unit'

# Extend libpath with .
$current_dir = File.dirname(__FILE__)
$: << $current_dir+"/../lib"

# Debug ?
#$DEBUG = true

# Unicode ?
$KCODE='U'

require 'superunpack'

class TestParsable < Test::Unit::TestCase
  include Parsable
  def test_unknowsizeparsableexception
    @length = nil
    assert_raise(UnknownSizeParsableException) {
      read_data
    }
  end
end

class TestChar < Complex
  Char :char
end
class TestChars < Complex
  Char :chars, 2
end
class TestULong < Complex
  Blong :ulong
end
class TestUInt < Complex
  Uint :uint
end
class TestBShort < Complex
  Bshort :ushort
end

class TestAllTypes < Complex
  Char :char
  Blong :ulong
  Uint :uint
  Bshort :ushort
end

class BasicTypes < Test::Unit::TestCase
  def test_char
    ab = TestChar.new
    ab.parse_string("1")
    assert_equal("1", ab.char)
  end
  def test_chars
    ab = TestChars.new
    ab.parse_string("ab")
    assert_equal("ab", ab.chars)
  end
  
  def test_ulong 
    ab = TestULong.new
    ab.parse_string("\000\000\010\001")
    assert_equal(2049, ab.ulong)
  end
  def test_uint
    ab = TestUInt.new
    ab.parse_string("\f")
    assert_equal(12, ab.uint)
  end
  def test_ushort
    ab = TestBShort.new
    ab.parse_string("\004\322")
    assert_equal(1234, ab.ushort)
  end
  
  def test_char_ulong_uint_ushort
    ab = TestAllTypes.new
    ab.parse_string("1\000\000\010\001\f\004\322")
    assert_equal("1", ab.char)
    assert_equal(2049, ab.ulong)
    assert_equal(12, ab.uint)
    assert_equal(1234, ab.ushort)
    
  end
end

class CStringTest < Complex
  CString :cstring
end

class TestComplex < Test::Unit::TestCase
  def test_string_complex
    ab = CStringTest.new
    ab.parse_string("simple string\0")
    assert_equal("simple string", ab.cstring)
  end
end

class ExtendedChar < Complex
  Char :version, 4
  Blong :ulong
end

class MultipleCharComplex < Test::Unit::TestCase
  def test_char_multiple_complex
    ab = ExtendedChar.new
    ab.parse_string("\001\010\100\101\000\000\010\001")
    assert_equal("\001\010\100\101", ab.version)
    assert_equal(2049, ab.ulong)
    
  end
end

class PString < Complex
  PascalString :var
end
class MultipleChar < Test::Unit::TestCase
  def test_pascal_string
    ab = PascalString.new
    # Regular 2 bytes Pascal String
    ab.parse_string("\0\4COIN")
    assert_equal('COIN', ab.value)

    # Empty String
    ab.parse_string("\xff\xff")
    assert_equal("", ab.value)

    # Another Empty String
    ab.parse_string("\x0\x0")
    assert_equal("", ab.value)

  end
end

class SimpleMix < Complex
  CString :string
  element TestAllTypes, :mix
end

class CStringAndElement < Test::Unit::TestCase
  def test_cstring_and_element
    ab = SimpleMix.new
    ab.parse_string("simple string\0001\000\000\010\001\f\004\322")
    
    assert_equal("simple string", ab.string)
    assert_equal("1", ab.mix.char)
    assert_equal(2049, ab.mix.ulong)
    assert_equal(12, ab.mix.uint)
    assert_equal(1234, ab.mix.ushort)
    
  end 
end


class LengthTest < Test::Unit::TestCase
  def test_simple_length
    ab = TestULong.new
    ab.parse_string("\000\000\010\001")
    assert_equal(4, ab.length)      
    ab = CStringTest.new
    ab.parse_string("simple string\0")
    assert_equal(14, ab.length)
  end
end

# class Anyterator < Complex
#   Any CString, :strings
# end

# class AniteratorTest < Test::Unit::TestCase
#   def test_iterator
#     i = Anyterator.new
#     i.parse_string("string 1\0string 2\0string 4\t\0")
#     assert_equal(['string 1','string 2', "string 4\t"], i.strings.value)
#   end
# end
