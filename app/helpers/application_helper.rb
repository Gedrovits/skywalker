module ApplicationHelper
  def t(key, options = {})
    p 'OVERRIDEN'
    options = options.dup
    has_default = options.has_key?(:default)
    remaining_defaults = Array(options.delete(:default)).compact
    
    if has_default && !remaining_defaults.first.kind_of?(Symbol)
      options[:default] = remaining_defaults
    end
    
    # If the user has explicitly decided to NOT raise errors, pass that option to I18n.
    # Otherwise, tell I18n to raise an exception, which we rescue further in this method.
    # Note: `raise_error` refers to us re-raising the error in this method. I18n is forced to raise by default.
    if options[:raise] == false
      raise_error = false
      i18n_raise = false
    else
      raise_error = options[:raise] || ActionView::Base.raise_on_missing_translations
      i18n_raise = true
    end
    
    if html_safe_translation_key?(key)
      html_safe_options = options.dup
      options.except(*I18n::RESERVED_KEYS).each do |name, value|
        unless name == :count && value.is_a?(Numeric)
          html_safe_options[name] = ERB::Util.html_escape(value.to_s)
        end
      end
      translation = I18n.translate(scope_key_by_partial(key), html_safe_options.merge(raise: i18n_raise))
      
      translation.respond_to?(:html_safe) ? translation.html_safe : translation
    else
      # TODO: OVERRIDE
      translation = I18n.translate(scope_key_by_partial(key), options.merge(raise: i18n_raise))
    end
    
    i18n_wysiwyg_span(locale, scope_key_by_partial(key), translation.presence) # TODO: OVERRIDE
  rescue I18n::MissingTranslationData => e
    if remaining_defaults.present?
      translate remaining_defaults.shift, options.merge(default: remaining_defaults)
    else
      raise e if raise_error
      
      keys = I18n.normalize_keys(e.locale, e.key, e.options[:scope])
      title = "translation missing: #{keys.join('.')}"
      
      interpolations = options.except(:default, :scope)
      if interpolations.any?
        title << ", " << interpolations.map { |k, v| "#{k}: #{ERB::Util.html_escape(v)}" }.join(', ')
      end
      
      return title unless ActionView::Base.debug_missing_translation
      
      content_tag('span', keys.last.to_s.titleize, class: 'translation_missing', title: title)
      i18n_wysiwyg_span(e.locale, keys.join('.')) # TODO: OVERRIDE!
    end
  end
  
  # TODO: Generate specific span with ability to edit content and stored way to translation
  def i18n_wysiwyg_span(locale, key, translation = nil)
    prefix = 'i18n-wysiwyg'
    content_tag('span', translation || key, class: 'i18n-wysiwyg', contenteditable: true, 
                "data-#{prefix}" => [locale, key].join('.'), 
                "data-#{prefix}-original" => translation.presence)
  end
end
