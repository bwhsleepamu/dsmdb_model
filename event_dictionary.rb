class EventDictionary < ActiveRecord::Base
  set_table_name "event_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'

  has_many :event_dictionary_data_fields, :foreign_key => "event_record_id"
  has_many :data_dictionary, :through => :event_dictionary_data_fields
end