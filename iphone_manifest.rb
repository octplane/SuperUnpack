$current_dir = File.dirname(__FILE__)
$: << $current_dir
$KCODE='U'

require "superunpack"

class MFile < Complex
	PascalString :domain
	PascalString :filename
	PascalString :linktarget
	PascalString :datahash
	PascalString :dummy
	Bshort :mode
	Blong :dum2
	Blong :dum3
	Blong :userid
	Blong :groupid
	Blong :mtime
	Blong :atime
	Blong :ctime
	Char  :filelen, 8
	Uint  :flat 
	Uint  :numprops
end

class Mbdb < Complex
  Char :type, 4
  Char :dummy, 2 #  = 1
end

def pstring(input)
  p = PascalString.new
  p.input = input
  p.parse
  p.value
end

m = Mbdb.new

m.parse_string(File.open("#{$current_dir}/data/Manifest.mbdb").binmode.read)

while not m.input.eof?
  file = MFile.new
  file.parse m.input
  puts file.filename
  1.upto(file.numprops) do
    k = pstring(m.input)
    v = pstring(m.input)
    #puts k
    #puts v
  end
end

