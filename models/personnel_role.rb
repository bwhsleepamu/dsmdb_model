class PersonnelRole < ActiveRecord::Base
  set_sequence_name 'id_seq'
  
  belongs_to :personnel
  belongs_to :study
  
  scope :pi, lambda {where("role_name = '")}
end
