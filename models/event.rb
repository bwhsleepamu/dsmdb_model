class Event < ActiveRecord::Base
  attr_accessible :subject_id, :study_id, :source_id, :name, :labtime_hr, :labtime_min, :labtime_sec, :labtime_year, :realtime
end
