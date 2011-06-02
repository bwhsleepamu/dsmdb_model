class Event < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_id, :study_id, :source_id, :name, :labtime_hr, :labtime_min, :labtime_sec, :labtime_year, :realtime

  belongs_to :source
  belongs_to :study
  belongs_to :subject
  has_and_belongs_to_many :event_tags, :join_table => "events_event_tags"
  has_many :data

  accepts_nested_attributes_for :data

end
