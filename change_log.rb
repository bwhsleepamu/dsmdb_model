class ChangeLog < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :reference_id, :user, :time_stamp
end
