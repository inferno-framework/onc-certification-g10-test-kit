require_relative '../inferno/terminology/terminology_validation'
require_relative '../inferno/exceptions'

module ONCCertificationG10TestKit
  class TerminologyBindingValidator
    include USCoreTestKit::FHIRResourceNavigation
    include Inferno::Terminology::TerminologyValidation

    def self.validate(...)
      new(...).validate
    end

    attr_reader :resource, :binding_definition, :validation_messages

    def initialize(resource, binding_definition)
      @resource = resource
      @binding_definition = binding_definition
      @validation_messages = []
    end

    def validate
      # Handle special case due to required binding on a slice
      if binding_definition[:required_binding_slice]
        validate_required_binding_slice
      else
        add_error(element_with_invalid_binding) if element_with_invalid_binding.present? # rubocop:disable Style/IfInsideElse
      end

      validation_messages
    end

    def validate_required_binding_slice
      valid_binding =
        find_a_value_at(path_source, binding_definition[:path]) do |element|
          !invalid_binding?(element)
        end

      return if valid_binding.present?

      system = binding_definition[:system].presence || 'the declared Value Set'

      error_message = %(
        #{resource_type}/#{resource.id} at #{resource_type}.#{binding_definition[:path]}
        does not contain a valid code from #{system}.
      )

      validation_messages << {
        type: 'error',
        message: error_message
      }
    end

    def path_source
      return resource if binding_definition[:extensions].blank?

      binding_definition[:extensions].reduce(Array.wrap(resource)) do |elements, extension_url|
        elements.flat_map do |element|
          element.extension.select { |extension| extension.url == extension_url }
        end
      end
    end

    def element_with_invalid_binding
      @element_with_invalid_binding ||=
        find_a_value_at(path_source, binding_definition[:path]) do |element|
          if element.is_a? USCoreTestKit::PrimitiveType
            invalid_binding? element.value
          else
            invalid_binding? element
          end
        end
    end

    def add_error(element)
      validation_messages << {
        type: 'error',
        message: invalid_binding_message(element)
      }
    end

    def add_warning(message)
      validation_messages << {
        type: 'warning',
        message:
      }
    end

    def element_code(element)
      case element
      when FHIR::CodeableConcept
        element&.coding&.map do |coding|
          "`#{coding.system}|#{coding.code}`"
        end&.join(' or ')
      when FHIR::Coding, FHIR::Quantity
        "`#{element.system}|#{element.code}`"
      else
        "`#{element}`"
      end
    end

    def resource_type
      resource.resourceType
    end

    def invalid_binding_message(element)
      system = binding_definition[:system].presence || 'the declared CodeSystem'

      %(
        #{resource_type}/#{resource.id} at #{resource_type}.#{binding_definition[:path]}
        with code #{element_code(element)} is not in #{system}.
      )
    end

    def invalid_binding?(element)
      case binding_definition[:type]
      when 'CodeableConcept'
        invalid_codeable_concept? element
      when 'Quantity', 'Coding'
        invalid_coding? element
      when 'code'
        invalid_code? element
      end
    end

    def invalid_codeable_concept?(element)
      return unless element.is_a? FHIR::CodeableConcept

      if binding_definition[:system].present?
        element.coding.none? do |coding|
          validate_code(
            value_set_url: binding_definition[:system],
            code: coding.code,
            system: coding.system
          )
        rescue Inferno::ProhibitedSystemException => e
          add_warning(e.message)
          false
        end
      # If we're validating a codesystem (AKA if there's no 'system' URL)
      # We want all of the codes to be in their respective systems
      else
        el.coding.any? do |coding|
          !validate_code(
            value_set_url: nil,
            code: coding.code,
            system: coding.system
          )
        rescue Inferno::ProhibitedSystemException => e
          add_warning(e.message)
          false
        end
      end
    end

    def invalid_coding?(element)
      !validate_code(
        value_set_url: binding_definition[:system],
        code: element.code,
        system: element.system
      )
    rescue Inferno::ProhibitedSystemException => e
      add_warning(e.message)
      false
    end

    def invalid_code?(element)
      !validate_code(value_set_url: binding_definition[:system], code: element)
    end
  end
end
