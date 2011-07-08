class Study < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  
  # Attributes
  attr_accessible :nickname, :pi_id
  
  # Associations
  has_many :subjects
  belongs_to :personnel, :foreign_key => "pi_id"
  has_many :events
  
end
