module Spree
  module Admin
    module NavigationHelper
      # Creates a navigation item with optional icon
      # @param [String, SafeBuffer] label The text or HTML to use as the link content
      # @param [String] url The URL for the link
      # @param [String, nil] icon Optional icon name to prepend to the label
      # @param [Boolean, nil] active Whether the link should be marked as active
      # @return [SafeBuffer] The navigation item HTML
      def nav_item(label, url, icon: nil, active: nil)
        content_tag :li, class: 'nav-item', role: 'presentation' do
          label = icon(icon) + label if icon.present?
          active_link_to label, url, class: 'nav-link', active: active
        end
      end

      # the per_page_dropdown is used on index pages like orders, products, promotions etc.
      # this method generates the select_tag
      def per_page_dropdown
        per_page_default = if @products
                             Spree::Admin::RuntimeConfig.admin_products_per_page
                           elsif @orders
                             Spree::Admin::RuntimeConfig.admin_orders_per_page
                           else
                             Spree::Admin::RuntimeConfig.admin_records_per_page
                           end

        per_page_options = [
          per_page_default,
          per_page_default * 2,
          per_page_default * 4,
          per_page_default * 8
        ]

        selected_option = (params[:per_page].try(:to_i) || per_page_default).to_s

        selected_option += icon('chevron-down', class: 'ml-1 mr-0 arrow')

        content_tag :div, id: 'per-page-dropdown' do
          button_tag(raw(selected_option), class: 'btn btn-light btn-sm', data: { toggle: 'dropdown', expanded: false }) +
            content_tag(:div, class: 'dropdown-menu') do
              per_page_options.map do |option|
                link_to option, per_page_dropdown_params(option), class: "dropdown-item #{'active' if option == selected_option}"
              end.join.html_safe
            end
        end
      end

      # helper method to create proper url to apply per page ing
      # fixes https://github.com/spree/spree/issues/6888
      def per_page_dropdown_params(per_page)
        args = params.permit!.to_h.clone
        args.delete(:page)
        args.delete(:per_page)
        args.merge!(per_page: per_page)
        args
      end

      def link_to_edit(resource, options = {})
        url = options[:url] || edit_object_url(resource)
        options[:data] ||= {}
        options[:data][:action] ||= 'edit'
        options[:class] ||= 'btn btn-light btn-sm'
        link_to_with_icon('pencil', Spree.t(:edit), url, options) if can?(:update, resource)
      end

      def link_to_delete(resource, options = {})
        url = options[:url] || object_url(resource)
        name = options[:name] || Spree.t('actions.destroy')
        options[:class] ||= 'btn btn-danger btn-sm'
        options[:data] ||= { turbo_confirm: Spree.t(:are_you_sure), turbo_method: :delete }

        return unless can?(:destroy, resource)

        if options[:no_text]
          link_to_with_icon 'trash', name, url, options
        elsif options[:icon]
          link_to_with_icon options[:icon], name, url, options
        else
          link_to name, url, options
        end
      end

      def link_to_with_icon(icon_name, text, url, options = {})
        options[:class] ||= (options[:class].to_s + " with-tip").strip
        options[:title] ||= text if options[:no_text]
        no_text = options[:no_text]
        label = options[:no_text] ? '' : content_tag(:span, text)
        options.delete(:no_text)

        if icon_name
          icon = icon(icon_name, class: "icon icon-#{icon_name} #{text.blank? || no_text ? 'mr-0' : ''}")
          text = "#{icon} #{label}"
        end
        link_to(text.html_safe, url, options)
      end

      def active_link_to_with_icon(icon_name, text, url, options = {})
        options[:class] = (options[:class].to_s + " with-tip").strip
        options[:title] = text if options[:no_text]
        no_text = options[:no_text]
        label = options[:no_text] ? '' : content_tag(:span, text)
        options.delete(:no_text)

        if icon_name
          icon = icon(icon_name, class: "icon icon-#{icon_name}")
          text = "#{icon} #{label}"
        end
        active_link_to(text.html_safe, url, options)
      end

      # Override: Add disable_with option to prevent multiple request on consecutive clicks
      def button(text, icon_name = nil, button_type = 'submit', options = {})
        if icon_name
          text = "#{icon(icon_name, class: "icon icon-#{icon_name}")} #{text}"
        end

        css_classes = options[:class] || 'btn-primary'

        button_tag(
          text.html_safe,
          options.merge(
            type: button_type,
            class: "btn #{css_classes}",
            'data-turbo-submits-with' => content_tag(:span, '', class: 'spinner-border spinner-border-sm', role: 'status')
          )
        )
      end

      def button_link_to(text, url, html_options = {})
        Spree::Deprecation.warn("button_link_to is deprecated. Use standard link_to instead.")

        if html_options[:method] &&
            !html_options[:method].to_s.casecmp('get').zero? &&
            !html_options[:remote]

          html_options[:class] = html_options[:class] ? "btn #{html_options[:class]}" : 'btn btn-primary'

          form_tag(url, method: html_options.delete(:method)) do
            button(text, html_options.delete(:icon), nil, html_options)
          end
        else
          html_options[:class] = html_options[:class] ? "btn #{html_options[:class]}" : 'btn btn-light'

          if html_options[:icon]
            icon = icon(html_options[:icon], class: "icon icon-#{html_options[:icon]}")
            text = "#{icon} #{text}"
          end

          link_to(text.html_safe, url, html_options.except(:icon))
        end
      end

      def active_badge(condition, options = {})
        label = options[:label]
        label ||= condition ? Spree.t(:say_yes) : Spree.t(:say_no)
        label = icon('check') + label if condition

        css_class = condition ? 'badge-active' : 'badge-inactive'

        content_tag(:span, class: "badge  #{css_class}") do
          label
        end
      end

      def page_header_back_button(default_url, object = nil, label = nil)
        url = default_url

        if object.present?
          session_key = "#{object.class.to_s.demodulize.pluralize.downcase}_return_to".to_sym
          url = session[session_key] if session[session_key].present?
        end

        link_to url, class: 'd-flex align-items-center text-decoration-none' do
          content_tag(:span, icon('chevron-left', class: 'mr-0'), class: 'btn hover-gray px-2 d-flex align-items-center') +
            content_tag(:span, label, class: 'font-size-base text-black')
        end
      end

      def external_link_to(label, url, opts = {}, &block)
        opts[:target] ||= :blank
        opts[:rel] ||= :nofollow
        opts[:class] ||= "d-inline-flex align-items-center text-blue text-decoration-none"

        if block_given?
          link_to url, opts, &block
        else
          link_to url, opts do
            (label + icon('external-link', class: 'ml-1 mr-0 small')).html_safe
          end
        end
      end

      def help_bubble(text = '', placement = 'bottom', css: nil)
        css ||= 'text-muted'
        content_tag :small, icon('info-square-rounded', class: css), data: { placement: placement }, class: "with-tip #{css}", title: text
      end
    end
  end
end
