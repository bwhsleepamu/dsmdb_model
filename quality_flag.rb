class QualityFlag < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'

  attr_accessible :condition, :description

  has_many :events
  has_many :data
end