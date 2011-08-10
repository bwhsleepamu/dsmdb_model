class EventTag < ActiveRecord::Base
  set_primary_key self.name.underscore+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :tag_name, :description
  
  has_and_belongs_to_many :events, :join_table => "events_event_tags"
end
