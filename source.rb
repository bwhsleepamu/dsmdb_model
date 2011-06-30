class Source < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :user, :source_type, :reference, :description
  
  has_many :events
  has_many :data
  
  def self.create_source?(attr)
    unless attr.nil?
     unless (attr[:source_type].empty? and attr[:source_type].empty? and attr[:description].empty?)
        return true
      end
    end
    
    return false
  end

end
