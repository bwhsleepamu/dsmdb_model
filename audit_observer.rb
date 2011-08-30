  class AuditObserver < ActiveRecord::Observer
  observe :datum, :event, :event_tag, :study, :subject, :personnel, :irb

  def after_destroy(record)
    log_change(record, "destroy")
  end
  def after_update(record)
    log_change(record, "update")
  end
  def after_create(record)
    log_change(record, "create")
  end
  
  private
  
  def log_change(record, type)
    #CUSTOM_LOGGER.info "Logging #{type} on #{record.class.to_s} "
    user_id = Authorization.current_user.respond_to?("id") ? Authorization.current_user.id : nil
    c = ChangeLog.new(:reference_id => record.to_key[0], :user => user_id, :change_type => type, :time_stamp => Time.now)
    c.save    
  end
end