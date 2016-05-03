module Nuntius

  class Report

    module Dsl

      def self.included(base)
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods

        FILTER_TYPES = %i(check_box color date datetime email month number phone radio_button range search
                          select telephone text_area text url week)

        def filters
          @filters ||= []
        end

        def filter(name, type, args = {})
          fail "FilterType: [#{type}] not yet implemented." unless valid_filter_type?(type)

          filters << {
            name: name.to_sym,
            type: type,
            args: args
          }
        end

        protected

        def valid_filter_type?(type)
          FILTER_TYPES.include?(type.to_sym)
        end

      end

      module InstanceMethods

        def self.included(base)
          base.extend ClassMethods
        end

        def filters
          self.class.filters
        end

      end

    end

  end

end
