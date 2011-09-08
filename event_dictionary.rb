class EventDictionary < ActiveRecord::Base
  set_table_name "event_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'

  before_save :delete_data_fields
  after_save :add_data_fields

  attr_accessor :data_fields

  attr_accessible :name, :description, :data_fields

  has_many :event_dictionary_data_fields, :foreign_key => "event_record_id"
  has_many :data_dictionary, :through => :event_dictionary_data_fields


  def delete_data_fields
     event_dictionary_data_fields.each {|df| df.destroy }
  end

  def add_data_fields
    data_fields.each do |field|
      if field["data_record_id"] != ""
        CUSTOM_LOGGER.info "er: #{record_id} dr: #{field["data_record_id"]} f?: #{field["data_record_id"] == ""}"
        eddf = EventDictionaryDataField.new(:event_record_id => record_id, :data_record_id => field["data_record_id"], :required => field["required"])
        eddf.save
      end
    end


  end

end