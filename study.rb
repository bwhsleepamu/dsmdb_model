class Study < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  
  # Attributes
  attr_accessible :nickname, :pi_id, :notes
  
  # Associations
  has_many :subjects
  belongs_to :personnel, :foreign_key => "pi_id"
  has_many :events
  
  # Getters
  def start_date
    event_name = "demographics"
    data_title = "admit date"
    
    first_admit_date = Datum.find_by_sql ["
                      select data.* from studies
                        inner join subjects on subjects.study_id = studies.study_id
                        inner join events on events.subject_id = subjects.subject_id
                        inner join data on data.event_id = events.event_id
                      where events.name = ? and data.title = ? and studies.study_id = ?
                      order by time_data asc
                     ", event_name, data_title, study_id]
    first_admit_date.first.value
                     
  end
  
  def project_leaders
    Personnel.find_by_sql ["select unique personnel.* from personnel
                            inner join subjects on personnel.personnel_id = subjects.pl_id 
                            inner join studies on subjects.study_id = studies.study_id
                          where studies.study_id = ?", study_id] 
  end
  
  def irbs
    Irb.find_by_sql("select unique irbs.* from irbs
                        inner join irbs_subjects on irbs.irb_id = irbs_subjects.irb_id
                        inner join subjects on subjects.subject_id = irbs_subjects.subject_id
                        inner join studies on studies.study_id = subjects.study_id
                      where studies.study_id = #{study_id}") 
  end
  
end
