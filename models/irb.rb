class Irb < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :protocol_id
  
  has_and_belongs_to_many :subjects
end
