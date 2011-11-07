class Datum < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :event_id, :unit_id, :documentation_id,  :title, :num_data, :text_data, :description, :time_data, :unit_name, :source_id, :missing

  belongs_to :event
  belongs_to :source
  belongs_to :quality_flag
  belongs_to :documentation

  attr_accessor :unit_name

  ##
  # Saving A Datum

=begin
 So, data can have a
  - source
  - documentation
  - quality flag (later)
  - event!!

  ATOMIC! <- focus
    - best way to ensure this is to SAVE together, right?
    - might be some built-in way of grouping DB actions together in atomic way (remember something of that sort - idk if applies to active record)
    - also might be useful to see if, when you save a parent model, all unsaved children are automatically saved (if event has unsaved data, does creating+saving event save data in its arrays)
  VALIDATION! <- after it works w/o it

  we need to basically override the initialize and update functions, right? ya!

  how does creating new differ from updating old??

  we create/select new data object (for a given event...no orphaned data!! what if the event is not saved?? ahh!)
  we create/select:
    - for each doc/source
      - if id is there, select old and update w/ data (need to decide if updating is allowed - might not allow in beginning)
      - otherwise, create new
      - add to datum

  for events, we do the same, except nest the individual data inserts, and again only save AT THE END WHEN EVERYTHING IS VALID YO
    - any database errors need to roll everything back!!
=end

  ##
  # These functions display all unique titles in the data table
  def self.titles
    self.select("unique title").order("title asc").map(&:title)
  end

  # This one displays the titles yet undefined in the data dictionary
  def self.undefined_titles(title_part)
    self.find_by_sql("select title from data where title like '%#{title_part}%' group by title minus select title from data_dictionary group by title").map(&:title)
  end

  ##
  # Returns dictionary record for this datum
  def dictionary_record
    DataDictionary.find_by_title(title)
  end


  # Return value of available field
  # in future, refer to DATA DICTIONARY!!!  if no entry, then this could be fallback...
  def value
    # make sure one and only one field has a value
    if (num_data.nil? && text_data.nil? && time_data.nil?) and not missing
      CUSTOM_LOGGER.error "NO DATA VALUE! #{datum_id} #{time_data.nil?} #{missing}"
      raise StandardError, "No data value in datum object and no missing data flag"
    end

    if missing
      nil
    elsif not num_data.nil?
      num_data
    elsif not text_data.nil?
      text_data
    else
      time_data
    end
  end

  # THIS FUNCTION IS A PRESENTER-TYPE THING
  def value_to_string

    # make sure one and only one field has a value
    if (num_data.nil? && text_data.nil? && time_data.nil?) and not missing
      CUSTOM_LOGGER.error "NO DATA VALUE! #{datum_id} #{time_data.nil?} #{missing}"
      raise StandardError, "No data value in datum object and no missing data flag"
    end

    if missing
      "N/A - Data Missing"
    else
      to_formatted_string
    end
  end

  private

  # UNITS NO LONGER STORED IN DATA TABLE
  #def assign_unit
  #  if self.unit_name
  #    u = DataUnit.find_or_create_by_name(self.unit_name)
  #    self.data_unit = u
  #  end
  #end

  def to_formatted_string
    #### DEPRECIATED!!!! USE DATA DICTIONARY!!!!! ######
    # special format needs first
    case title
      when "date_of_birth", "admit_date"
        time_data.strftime('%x')
      when "gender", "ethnic_category"
        text_data.tr('_', ' ')
      when "weight", "height", "naps_per_week", "owl_lark_score", "blood_pressure_diastolic", "blood_pressure_systolic", "heart_rate", "suite_number"
        number_to_human(num_data)
      when "race"
        r = YAML::load(text_data)
        r.join(", ")
      else
        if !num_data.nil?
          num_data
        elsif !text_data.nil?
          text_data
        elsif !time_data.nil?
          time_data.strftime('%X')
        else
          "N/A - Data Missing"
        end
    end
  end
end
