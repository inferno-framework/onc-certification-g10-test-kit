require_relative 'g10_options'

module ONCCertificationG10TestKit
  module ProfileSelector
    include G10Options

    def extract_profile(resource_type)
      case resource_type
      when 'Medication'
        return versioned_us_core_module.const_get('USCoreTestSuite').metadata.find do |meta|
                 meta.resource == resource_type
               end.profile_url
      when 'Location'
        return 'http://hl7.org/fhir/StructureDefinition/Location'
      end
      versioned_us_core_module.const_get("#{resource_type}Group").metadata.profile_url
    end

    def observation_contains_code?(observation_resource, code)
      observation_resource&.code&.coding&.any? { |coding| coding&.code == code }
    end

    def resource_contains_category?(resource, category_code, category_system = nil) # rubocop:disable Metrics/CyclomaticComplexity
      resource&.category&.any? do |category|
        category.coding&.any? do |coding|
          coding.code == category_code &&
            (category_system.blank? || coding.system.blank? || category_system == coding.system)
        end
      end
    end

    def select_profile(resource) # rubocop:disable Metrics/CyclomaticComplexity
      profiles = []

      case resource.resourceType
      when 'Condition'
        case us_core_version
        when US_CORE_5, US_CORE_6
          if resource_contains_category?(resource, 'encounter-diagnosis', 'http://terminology.hl7.org/CodeSystem/condition-category')
            profiles << extract_profile('ConditionEncounterDiagnosis')
          elsif resource_contains_category?(resource, 'problem-list-item',
                                           'http://terminology.hl7.org/CodeSystem/condition-category') ||
                resource_contains_category?(resource, 'health-concern', 'http://hl7.org/fhir/us/core/CodeSystem/condition-category')
            profiles << extract_profile('ConditionProblemsHealthConcerns')
          end
        else
          profiles << extract_profile(resource.resourceType)
        end
      when 'DiagnosticReport'
        profiles << if resource_contains_category?(resource, 'LAB', 'http://terminology.hl7.org/CodeSystem/v2-0074')
                      extract_profile('DiagnosticReportLab')
                    else
                      extract_profile('DiagnosticReportNote')
                    end
      when 'Observation'
        profiles << extract_profile('Smokingstatus') if observation_contains_code?(resource, '72166-2')

        profiles << extract_profile('ObservationLab') if resource_contains_category?(resource, 'laboratory', 'http://terminology.hl7.org/CodeSystem/observation-category')

        profiles << extract_profile('PediatricBmiForAge') if observation_contains_code?(resource, '59576-9')

        profiles << extract_profile('PediatricWeightForHeight') if observation_contains_code?(resource, '77606-2')

        profiles << extract_profile('PulseOximetry') if observation_contains_code?(resource, '59408-5')

        if observation_contains_code?(resource, '8289-1')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('HeadCircumference')
                      else
                        extract_profile('HeadCircumferencePercentile')
                      end
        end

        if observation_contains_code?(resource, '9843-4') && !using_us_core_3?
          profiles << extract_profile('HeadCircumference')
        end

        # FHIR Vital Signs profiles: https://www.hl7.org/fhir/observation-vitalsigns.html
        # Vital Signs Panel, Oxygen Saturation are not required by USCDI
        # Body Mass Index is replaced by :pediatric_bmi_age Profile
        # Systolic Blood Pressure, Diastolic Blood Pressure are covered by :blood_pressure Profile
        # Head Circumference is replaced by US Core Head Occipital-frontal Circumference Percentile Profile
        profiles << extract_profile('Bmi') if observation_contains_code?(resource, '39156-5') && !using_us_core_3?

        if observation_contains_code?(resource, '85354-9')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Bp')
                      else
                        extract_profile('BloodPressure')
                      end
        end

        if observation_contains_code?(resource, '8302-2')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Bodyheight')
                      else
                        extract_profile('BodyHeight')
                      end
        end

        if observation_contains_code?(resource, '8310-5')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Bodytemp')
                      else
                        extract_profile('BodyTemperature')
                      end
        end

        if observation_contains_code?(resource, '29463-7')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Bodyweight')
                      else
                        extract_profile('BodyWeight')
                      end
        end

        if observation_contains_code?(resource, '8867-4')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Heartrate')
                      else
                        extract_profile('HeartRate')
                      end
        end

        if observation_contains_code?(resource, '9279-1')
          profiles << case us_core_version
                      when US_CORE_3
                        extract_profile('Resprate')
                      else
                        extract_profile('RespiratoryRate')
                      end
        end

        if using_us_core_5? &&
           resource_contains_category?(
             resource, 'clinical-test', 'http://hl7.org/fhir/us/core/CodeSystem/us-core-observation-category'
           )
          profiles << extract_profile('ObservationClinicalTest')
        end

        if (using_us_core_5? || using_us_core_6?) && observation_contains_code?(resource, '76690-7')
          profiles << extract_profile('ObservationSexualOrientation')
        end

        if using_us_core_5? &&
           resource_contains_category?(resource, 'social-history',
                                      'http://terminology.hl7.org/CodeSystem/observation-category')
          profiles << extract_profile('ObservationSocialHistory')
        end

        if using_us_core_5? &&
           resource_contains_category?(resource, 'imaging',
                                      'http://terminology.hl7.org/CodeSystem/observation-category')
          profiles << extract_profile('ObservationImaging')
        end

        if resource_contains_category?(resource, 'survey',
                                       'http://terminology.hl7.org/CodeSystem/observation-category')
          if using_us_core_5?
            # We will simply match all Observations of category "survey" to SDOH,
            # and do not look at the category "sdoh".  US Core spec team says that
            # support for the "sdoh" category is limited, and the validation rules
            # allow for very generic surveys to validate against this profile.
            # And will not validate against the ObservationSurvey profile itself.
            # This may not be exactly precise but it works out the same

            # if we wanted to be more specific here, we would add:
            # `resource_contains_category?(resource, 'sdoh',
            #                                       'http://terminology.hl7.org/CodeSystem/observation-category') &&`
            # along with a specific extract_profile('ObservationSurvey') to catch non-sdoh.
            profiles << extract_profile('ObservationSdohAssessment')
          elsif using_us_core_6?
            profiles << extract_profile('ObservationScreeningAssessment')
          end
        end

        if using_us_core_6? && observation_contains_code?(resource, '11341-5')
          profiles << extract_profile('ObservationOccupation')
        end

        if using_us_core_6? && observation_contains_code?(resource, '86645-9')
          profiles << extract_profile('ObservationPregnancyintent')
        end

        if using_us_core_6? && observation_contains_code?(resource, '82810-3')
          profiles << extract_profile('ObservationPregnancystatus')
        end

        nil
      else
        profiles << extract_profile(resource.resourceType)
      end

      profiles
    rescue StandardError
      skip "Could not determine profile of \"#{resource.resourceType}\" resource."
    end
  end
end
