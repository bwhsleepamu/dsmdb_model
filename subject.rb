class Subject < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_code, :study_id, :admit_date
  
  belongs_to :study
  has_many :events
end
