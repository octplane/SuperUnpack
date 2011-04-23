# Sample mddb and mbdbx reader
# Reads Backup file for the iphone
#
# Data structures are inspired from 
# https://github.com/petewarden/iPhoneTracker
# and
# http://stackoverflow.com/questions/3085153/how-to-parse-the-manifest-mbdb-file-in-an-ios-4-0-itunes-backup


$current_dir = File.dirname(__FILE__)
$: << $current_dir+"/../lib"
$KCODE='U'

require "superunpack"

# Mbdb Header
class MbdbHeader < Complex
  Char :type, 4
  Char :dummy, 2 #  = 1
end

# Mbdb File item
class MFile < Complex
	attr_accessor :properties
	def initialize
	   @properties = {}
	end
  def fileId
    @fileId ||= @properties['fileId'].split(//).map { |c|
      "%02x" % c[0]
    }.join
  end
  Offset :offset
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

# Mbdx Header
class MdbxHeader < Complex
  Char :type, 4
  Char :dummy, 2 #  = 1
  Blong :count
end

# Mbdx Item
class MFilex < Complex
  Char :fileid, 20
  Blong :loffset
  Bshort :bmode

  # real offset is 6 bytes higher (to get past the prolog)
  def offset
    loffset + 6
  end
  def mode
    r = w = x = '-'
    r = 'r' if bmode & 0x4
    w = 'w' if bmode & 0x2
    x = 'x' if bmode & 0x1
    r+w+x
  end

end

# Fixme by implement loopable attributes in SuperUnpack
def pstring(input)
  p = PascalString.new
  p.input = input
  p.parse
  p.value
end

def parse_mbdb filename = "#{$current_dir}/../data/Manifest.mbdb"
  m = MbdbHeader.new
  m.parse_string(File.open(filename).binmode.read)

  files = {}
  while not m.input.eof?
    file = MFile.new
    file.parse m.input
    1.upto(file.numprops) do
      k = pstring(m.input)
      v = pstring(m.input)
      file.properties[k] = v
    end

    files[file.offset] = file
  end
  files
end

def parse_mbdx filename = "#{$current_dir}/../data/Manifest.mbdx"

  m = MdbxHeader.new

  m.parse_string(File.open(filename).binmode.read)

  filex = {}

  1.upto(m.count) do
    file = MFilex.new
    file.parse m.input
    filex[file.offset] = file
  end

  # Sanity Check
  if not m.input.eof?
    raise "Something is wrong with the file size (indicates #{m.count} item, but not at eof yet..." 
  end
  filex
end

# Parse a backup at path
class IPhoneBackup
  def initialize path= "#{$current_dir}/../data/"
    @file_list = {}
    files = parse_mbdb path+"Manifest.mbdb"
    filex = parse_mbdx path+"Manifest.mbdx"

    files.each do |offset, file|
      if filex.has_key?(offset)
        file.properties['fileId'] = filex[offset].fileid
      end
      @file_list[file.filename] = file
    end
  end
  # Returns the file object corresponding to a given filename in the backup
  def file(fname)
    @file_list[fname]
  end
end

if $0 == __FILE__
  backup_path = 'C:/Users/Oct/AppData/Roaming/Apple Computer/MobileSync/Backup/c27f0a46a35e0462d70221cb66c843b929bdcc19-20100623-201105/'
  backup = IPhoneBackup.new(backup_path)
  puts "Database is at "+ backup_path+backup.file("Library/Caches/locationd/consolidated.db").fileId
end