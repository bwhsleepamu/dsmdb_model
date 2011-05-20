class Study < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :nickname
  
  has_and_belongs_to_many :irbs
  has_many :subjects
  has_many :personnel_roles
  has_many :personnel, :through => :personnel_roles
  has_many :events
end
