class DataUnit < ActiveRecord::Base
  set_primary_key 'unit_id'
  set_sequence_name 'id_seq'
  set_table_name "units"
  attr_accessible :name
  
  has_many :data
end
