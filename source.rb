class Source < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :user, :source_type, :reference, :description
  
  has_many :events
end
