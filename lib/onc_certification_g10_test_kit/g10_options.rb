module ONCCertificationG10TestKit
  module G10Options
    US_CORE_3 = 'us_core_3'.freeze
    US_CORE_4 = 'us_core_4'.freeze
    US_CORE_5 = 'us_core_5'.freeze
    US_CORE_6 = 'us_core_6'.freeze
    US_CORE_7 = 'us_core_7'.freeze

    US_CORE_VERSION_NUMBERS = {
      US_CORE_3 => '3.1.1',
      US_CORE_4 => '4.0.0',
      US_CORE_5 => '5.0.1',
      US_CORE_6 => '6.1.0',
      US_CORE_7 => '7.0.0'
    }.freeze

    BULK_DATA_1 = 'multi_patient_api_stu1'.freeze
    BULK_DATA_2 = 'multi_patient_api_stu2'.freeze

    SMART_1 = 'smart_app_launch_1'.freeze
    SMART_2 = 'smart_app_launch_2'.freeze
    SMART_2_2 = 'smart_app_launch_2_2'.freeze

    US_CORE_3_REQUIREMENT = { us_core_version: US_CORE_3 }.freeze
    US_CORE_4_REQUIREMENT = { us_core_version: US_CORE_4 }.freeze
    US_CORE_5_REQUIREMENT = { us_core_version: US_CORE_5 }.freeze
    US_CORE_6_REQUIREMENT = { us_core_version: US_CORE_6 }.freeze
    US_CORE_7_REQUIREMENT = { us_core_version: US_CORE_7 }.freeze

    BULK_DATA_1_REQUIREMENT = { multi_patient_version: BULK_DATA_1 }.freeze
    BULK_DATA_2_REQUIREMENT = { multi_patient_version: BULK_DATA_2 }.freeze

    SMART_1_REQUIREMENT = { smart_app_launch_version: SMART_1 }.freeze
    SMART_2_REQUIREMENT = { smart_app_launch_version: SMART_2 }.freeze
    SMART_2_2_REQUIREMENT = { smart_app_launch_version: SMART_2_2 }.freeze

    def us_core_version
      suite_options[:us_core_version]
    end

    def using_us_core_3?
      us_core_version == US_CORE_3
    end

    def using_us_core_4?
      us_core_version == US_CORE_4
    end

    def using_us_core_5?
      us_core_version == US_CORE_5
    end

    def using_us_core_6?
      us_core_version == US_CORE_6
    end

    def using_us_core_7?
      us_core_version == US_CORE_7
    end

    def us_core_7_and_above?
      us_core_version[-1].to_i > 6
    end

    def versioned_us_core_module
      case us_core_version
      when US_CORE_7
        USCoreTestKit::USCoreV700
      when US_CORE_6
        USCoreTestKit::USCoreV610
      when US_CORE_5
        USCoreTestKit::USCoreV501
      when US_CORE_4
        USCoreTestKit::USCoreV400
      else
        USCoreTestKit::USCoreV311
      end
    end
  end
end
