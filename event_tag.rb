class EventTag < ActiveRecord::Base
  set_primary_key self.name.underscore+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :tag_name, :description

  ##
  # Associations
  has_and_belongs_to_many :event_dictionary, :join_table => "events_event_tags", :association_foreign_key => "record_id"

  ##
  # Scopes
  scope :find_by_name_part, lambda {|name|
    # allows searching by parts o
    name = '%'+name+'%'
    where("lower(tag_name) like lower(?)", name)
  }

  def save
    # start transaction
    EventTag.transaction do
      CUSTOM_LOGGER.info "Started transaction"
      super
    end

  end

  def frequency_hash


  end
end
