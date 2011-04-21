$current_dir = File.dirname(__FILE__)
$: << "../"+$current_dir+"/lib"

require 'superunpack'



class Category  < Complex 
  Blong :index
  Blong :identifier
  Blong :dirty
  CString :long_name
  CString :short_name
end

class CField < Complex
      Blong :field_type
      Blong :padding
      CString :value
end 

class CPhoneField < Complex
    Blong :field_type
    Blong :phone_label
    Blong :field_type
    Blong :padding
    CString :value
end

class Address < Complex
  Blong :field_type
  Blong :record_id
  Blong :field_type2
  Blong :status_field
  Blong :field_type3
  Blong :position
  
  element CField, :lastname
  element CField, :first
  element CField, :title
  element CField, :company
  element CField, :phone1

    
  element CPhoneField, :phone1
  element CPhoneField, :phone2
  element CPhoneField, :phone3
  element CPhoneField, :phone4
  element CPhoneField, :phone5
    
  element CField, :address
  element CField, :city
  element CField, :state
  element CField, :zip
  element CField, :country
  element CField, :note
  
  Blong :field_type
  Blong :private
  Blong :field_type
  Blong :category
  [ :custom1,
    :custom2,
    :custom3,
    :custom4 ].each_with_index do |symbol, index|
    
    Blong :field_type
    Blong :padding
    CString symbol
  end
  Blong :field_type
  Blong :display_phone
  
  
end

class CategoryInfo < Complex
   Char :foo, 11 
   PascalString :long_name
   Blong :bar
   PascalString :short_name
end

class AddressBook < Complex
   Char :version, 4
   PascalString :alias
   Char :ooRV, 4
   Char :version_tag, 4
   Char :ignored, 12
   Llong :record_count
   Char :ignored2, 8
   PascalString :file_path
   element CategoryInfo, :category_info

end
#

ab = AddressBook.new
ab.parse_string(File.open($current_dir+"/../data/address.dat").binmode.read)
puts ab.record_count-0x1000
puts ab.category_info.long_name
