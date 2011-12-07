class Documentation < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'

  attr_accessible :title, :author, :procedure, :notes

  ##
  # Associations
  has_many :data
  has_many :events

  ##
  # Validations
  validates_presence_of :title, :author, :procedure
  validates_length_of :title, :maximum => 254
  validates_length_of :author, :maximum => 254
  validates_uniqueness_of :title, :scope => :author, :message => "Documentation with given author and title combination already exists."

end
