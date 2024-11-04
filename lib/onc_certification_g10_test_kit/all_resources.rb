require_relative 'g10_options'

module ONCCertificationG10TestKit
  module AllResources
=begin
      This list a list of all resource types mapped to USCDI data classes or elements,
      and shall be supported by certified server implementation:

      * AllergyIntolerance
      * CarePlan
      * CareTeam
      * Condition
      * Device
      * DiagnosticReport
      * DocumentReference
      * Encounter
      * Goal
      * Immunization
      * MedicationRequest
      * Observation
      * Organization
      * Patient
      * Practitioner
      * Procedure
      * Provenance

      For USCDI v2 / US Core v5.0.1, these resource types are added:
      * RelatedPerson
      * ServiceRequest

      For USCDI v3 / US Core v6.1.0, these resource types are added:
      * Coverage
      * MedicationDispense
      * Specimen

      For USCDI v4 / US Core v7.0.0, these resource types are added:
      * Location
=end

    ALL_RESOURCES =
      [
        'AllergyIntolerance',
        'CarePlan',
        'CareTeam',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
        'Encounter',
        'Goal',
        'Immunization',
        'MedicationRequest',
        'Observation',
        'Organization',
        'Procedure',
        'Patient',
        'Practitioner',
        'Provenance'
      ].freeze

    V5_ALL_RESOURCES = (ALL_RESOURCES + ['RelatedPerson', 'ServiceRequest']).freeze

    V6_ALL_RESOURCES = (V5_ALL_RESOURCES + ['Coverage', 'MedicationDispense', 'Specimen']).freeze

    V7_ALL_RESOURCES = (V6_ALL_RESOURCES + ['Location']).freeze

    def all_required_resources
      return V5_ALL_RESOURCES if using_us_core_5?

      return V6_ALL_RESOURCES if using_us_core_6?

      return V7_ALL_RESOURCES if using_us_core_7?

      ALL_RESOURCES
    end
  end
end
