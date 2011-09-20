class Event < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_id, :study_id, :source_id, :name, :labtime_hr, :labtime_min, :labtime_sec, :labtime_year, :realtime, :notes, :labtime_decimal, :documentation_id

  belongs_to :documentation
  belongs_to :source
  belongs_to :study
  belongs_to :subject
  has_and_belongs_to_many :event_tags, :join_table => "events_event_tags"
  has_many :data

  accepts_nested_attributes_for :data

  after_save :save_data

  # Sometimes labtime is stored or needed in hour.fractionofhour format
  # These functions allow conversion to and from this format
  def labtime_decimal=(val)
    # hour is always to left of decimal point
    hour = val.truncate

    # multiply decimal by number of seconds in hour, and round to nearest second
    # (usually value will already be very close)
    sec = ((val - hour) * 3600).round
    min = (sec / 60).truncate
    sec %= 60

    self[:labtime_hr] = hour
    self[:labtime_min] = min
    self[:labtime_sec] = sec
  end

  def labtime_decimal
    (self[:labtime_hr] + (self[:labtime_min] / 60) + (self[:labtime_sec] / 3600)).to_f
  end

  # add demographic tags
  def add_demographic_tags
    add_tags(["demographic", "manual", "merged"])
  end

  # add form tags
  def add_form_tags
    add_tags(["demographic", "manual", "form"])
  end

  def add_tags(tag_list)
    tag_list.each do |tag|
      event_tags << EventTag.find_or_create_by_tag_name(tag)
    end
  end





  ## Creators for different types of events ##
  # return an event object for holding subject demographic data
  def self.new_subject_demographics(subject)
    event = Event.new({:name => "demographics"})
    event.subject = subject
    event.add_demographic_tags
    event.add_data_by_event_type(true)
    event.realtime = Time.now()
    event.source = Source.new({:user => Authorization.current_user.id, :source_type => "merged",
                        :reference => "Merged Forms page for subject #{subject.subject_id}"
                       })
    event
  end

  def self.new_form(form_name, subject_id, missing_tag)
    # maybe make this the accessor and creator?

    CUSTOM_LOGGER.info "Creating form #{form_name} for #{subject_id}"
    e = Event.where("name = ? AND subject_id = ?", form_name, subject_id).first
    CUSTOM_LOGGER.info e ? e.event_id : "no other such event found"

    if e.nil?
      event = Event.new(:name => form_name)
      event.subject_id = subject_id
      event.add_data_by_event_type(missing_tag)
      event.add_form_tags
      event.source = Source.new({:user => Authorization.current_user.id, :source_type => "physical",
                                  :reference => "File Room - folder for subject #{event.subject.subject_code} - #{event.name}"
                                 })
      return event
    else
      return e
    end

  end
  ############

  def add_data_by_event_type(missing_tag)
    # each event has data titles associated with it
    # missing tag allows associated data to set to missing as default, until set with an actual value and changed otherwise



    case name
      when "demographics"
        titles = ["admit date", "suite number", "date of birth", "gender", "ethnic category", "race" ]
        titles += ["height", "weight", "blood pressure systolic", "blood pressure diastolic", "heart rate"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
        titles += ["owl lark score"]
      when "personal data form"
        titles = ["date of birth", "gender", "ethnic category", "race"]
      when "physical exam form"
        titles = ["blood pressure systolic", "blood pressure diastolic", "heart rate"]
      when "physician form"
        titles = ["height", "weight", "blood pressure systolic", "blood pressure diastolic", "heart rate"]
      when "subject information form"
        titles = ["date of birth", "gender", "height", "weight"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
      when "owl lark form"
        titles = ["owl lark score"]
      when "other sources"
        titles = ["date of birth", "age", "gender", "ethnic category", "race", "height", "weight"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
    end
    titles.each { |title| data.build(:title => title, :missing => missing_tag) }
  end


  def add_update_data(params)
    # add or update applicable data fields to event
    params.each do |title, value|
      convert_units!(value)
      title_ns = title.tr('_', ' ')

      CUSTOM_LOGGER.info "Adding/updating data for #{subject.subject_code} #{name}: #{title} #{title_ns} #{value}"

      data_attributes = value.merge({ :title => title_ns })
      data_attributes[:missing] ||= 'f'
      if (datum = data.find_by_title(title_ns))
        CUSTOM_LOGGER.info "Updating existing #{title}"
        datum.update_attributes(data_attributes)
      else
        CUSTOM_LOGGER.info "Creating new #{title}"
        datum = data.build(data_attributes)
      end

      if empty_form(datum, data_attributes)
        datum.missing = true
      end

      # make sure missing ==> no data stored
      if datum.missing
        datum.num_data = nil
        datum.text_data = nil
        datum.time_data = nil
        datum.data_unit = nil
        datum.save
      end

      # create/update source information - put in data model
      if Source.create_source?(data_attributes[:source_attributes])
        CUSTOM_LOGGER.info "Updating/Creating Source Info"
        if datum.source
          CUSTOM_LOGGER.info "update current source"
          data_attributes[:source_attributes].merge({ :user => Authorization.current_user.id })
          datum.source.update_attributes(data_attributes[:source_attributes])
        else
          CUSTOM_LOGGER.info "create new source"
          s = Source.create(data_attributes[:source_attributes])
          s.user = Authorization.current_user.id
          datum.source = s
        end
        datum.save
      else
        if datum.source
          if datum.source.data.length <= 1
            ds = datum.source
            datum.source = nil
            datum.save
            ds.destroy
          else
            datum.source = nil
          end
        end
      end
    end
  end

  private

  # convert to standard units - modifies value
  def convert_units!(value)
    # for now: lb ==> kg and ft/in ==> cm
    case value[:unit_name]
      when "ft"
        u = Unit(value[:num_data])
        u >>= "cm"
        value[:num_data] = u.abs
        value[:unit_name] = "cm"
      when "lb"
        u = Unit(value[:num_data] + " lb")
        u >>= "kg"
        value[:num_data] = u.abs
        value[:unit_name] = "kg"
    end
  end

  def save_data
    self.data.each {|d| d.save}
  end

  # check if datum has no actual data
  def empty_form(datum, atts)
    empty = true

    # check num_data
    if not datum.num_data.nil?
      empty = false
    end

    # check text_data
    if not datum.text_data.nil?
      if not datum.text_data.empty?
        empty = false
      end
    end

    # check timestamp for time fields (1i to 3i are default values)
    if not atts["time_data(4i)"].nil?
      if not atts["time_data(4i)"].empty?
        empty = false
      end
    end

    # check timestamp for date fields (no 4i and 5i fields)
    if not atts["time_data(1i)"].nil? && atts["time_data(4i)"].nil?
      if not atts["time_data(1i)"].empty?
        empty = false
      end
    end
    empty
  end
end
