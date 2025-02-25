module ONCCertificationG10TestKit
  module ScopeConstants
    STANDALONE_SMART_1_SCOPES =
      %(
        launch/patient openid fhirUser offline_access patient/Medication.read
        patient/AllergyIntolerance.read patient/CarePlan.read
        patient/CareTeam.read patient/Condition.read patient/Device.read
        patient/DiagnosticReport.read patient/DocumentReference.read
        patient/Encounter.read patient/Goal.read patient/Immunization.read
        patient/Location.read patient/MedicationRequest.read
        patient/Observation.read patient/Organization.read patient/Patient.read
        patient/Practitioner.read patient/Procedure.read patient/Provenance.read
        patient/PractitionerRole.read
      ).gsub(/\s{2,}/, ' ').strip.freeze

    STANDALONE_SMART_2_SCOPES =
      %(
        launch/patient openid fhirUser offline_access patient/Medication.rs
        patient/AllergyIntolerance.rs patient/CarePlan.rs patient/CareTeam.rs
        patient/Condition.rs patient/Device.rs patient/DiagnosticReport.rs
        patient/DocumentReference.rs patient/Encounter.rs patient/Goal.rs
        patient/Immunization.rs patient/Location.rs patient/MedicationRequest.rs
        patient/Observation.rs patient/Organization.rs patient/Patient.rs
        patient/Practitioner.rs patient/Procedure.rs patient/Provenance.rs
        patient/PractitionerRole.rs
      ).gsub(/\s{2,}/, ' ').strip.freeze

    EHR_SMART_1_SCOPES =
      %(
        launch openid fhirUser offline_access user/Medication.read
        user/AllergyIntolerance.read user/CarePlan.read user/CareTeam.read
        user/Condition.read user/Device.read user/DiagnosticReport.read
        user/DocumentReference.read user/Encounter.read user/Goal.read
        user/Immunization.read user/Location.read user/MedicationRequest.read
        user/Observation.read user/Organization.read user/Patient.read
        user/Practitioner.read user/Procedure.read user/Provenance.read
        user/PractitionerRole.read
      ).gsub(/\s{2,}/, ' ').strip.freeze

    EHR_SMART_2_SCOPES =
      %(
        launch openid fhirUser offline_access user/Medication.rs
        user/AllergyIntolerance.rs user/CarePlan.rs user/CareTeam.rs
        user/Condition.rs user/Device.rs user/DiagnosticReport.rs
        user/DocumentReference.rs user/Encounter.rs user/Goal.rs
        user/Immunization.rs user/Location.rs user/MedicationRequest.rs
        user/Observation.rs user/Organization.rs user/Patient.rs
        user/Practitioner.rs user/Procedure.rs user/Provenance.rs
        user/PractitionerRole.rs
      ).gsub(/\s{2,}/, ' ').strip.freeze
  end
end
