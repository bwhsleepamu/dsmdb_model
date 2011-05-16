class Personnel < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :first_name, :last_name
  
  has_many :personnel_roles
  has_many :studies, :through => :personnel_roles
end
