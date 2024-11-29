module ApplicationHelper
    def loan_status_badge(status)
      badge_class = case status
        when 'requested'
          'bg-info'
        when 'approved'
          'bg-success'
        when 'open'
          'bg-primary'
        when 'close'
          'bg-secondary'
        when 'rejected'
          'bg-danger'
        when 'waiting_for_adjustment_acceptance'
          'bg-warning'
        when 'readjustment_requested'
          'bg-warning'
        else
          'bg-secondary'
      end
  
      content_tag(:span, status.humanize, class: "badge #{badge_class}")
    end
  
    def flash_class(level)
      case level
      when 'notice', 'success'
        'alert alert-success'
      when 'error', 'alert'
        'alert alert-danger'
      when 'warning'
        'alert alert-warning'
      else
        'alert alert-info'
      end
    end
  
    def format_currency(amount)
      number_to_currency(amount, unit: '₹', precision: 2)
    end
  end