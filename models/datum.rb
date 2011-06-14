class Datum < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :event_id, :unit_id, :title, :numeric, :char, :description, :timepoint, :unit_name
  
  belongs_to :data_unit, :foreign_key => "unit_id"
  belongs_to :event
  
  attr_accessor :unit_name
  
  before_save :assign_unit
  
  def value
    # make sure one and only one field has a value
    if numeric.nil? && char.nil? && timepoint.nil?
      CUSTOM_LOGGER.error "NO DATA VALUE! #{datum_id} #{timepoint.nil?}"     
      raise StandardError, "No data value in datum object"
    end
    
    if !numeric.nil?
      numeric
    elsif !char.nil?
      char.tr('_', ' ')
    else
      timepoint
    end
  end
  
  private 
  
  def assign_unit
    if self.unit_name
      u = DataUnit.find_or_create_by_name(self.unit_name)
      self.data_unit = u
    end
  end
end
