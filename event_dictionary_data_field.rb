class EventDictionaryDataField < ActiveRecord::Base
  set_sequence_name 'id_seq'

  belongs_to :data_dictionary, :foreign_key => "data_record_id"
  belongs_to :event_dictionary, :foreign_key => "event_record_id"

  attr_accessible :event_record_id, :data_record_id, :required, :max_occurrences

end
