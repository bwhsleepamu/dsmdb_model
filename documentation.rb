class Documentation < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'

  attr_accessible :title, :author, :procedure, :notes

  has_many :data
  has_many :events

end
