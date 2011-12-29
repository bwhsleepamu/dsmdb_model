class EventsEventTag < ActiveRecord::Base
  belongs_to :event_tag
  belongs_to :event_dictionary, :foreign_key => "record_id"
end
