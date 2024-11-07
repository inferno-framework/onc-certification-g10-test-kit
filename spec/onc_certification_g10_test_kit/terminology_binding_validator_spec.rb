RSpec.describe ONCCertificationG10TestKit::TerminologyBindingValidator do
  let(:bad_code) { 'abc' }
  let(:good_code) { 'def' }
  let(:system_url) { 'http://example.com/system' }

  describe '.validate' do
    context 'with a code' do
      let(:resource) do
        FHIR::Observation.new(id: '123', status: bad_code)
      end
      let(:binding_definition) do
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/observation-status',
          path: 'status'
        }
      end

      it 'returns an error message if a code is invalid' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: bad_code
          ).and_return(false)
        )

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:type]).to eq('error')
        expect(result.first[:message]).to(
          match(%r{#{resource.resourceType}/#{resource.id}.*#{binding_definition[:path]}})
        )
        expect(result.first[:message]).to(
          match(/with code `#{bad_code}` is not in #{binding_definition[:system]}/)
        )
      end
    end

    context 'with a Quantity/Coding' do
      let(:resource) do
        FHIR::DocumentReference.new(
          id: '123',
          content: [
            {
              format: {
                code: bad_code,
                system: system_url
              }
            }
          ]
        )
      end
      let(:binding_definition) do
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/formatcodes',
          path: 'content.format'
        }
      end

      it 'returns an error message if the Coding is invalid' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: 'abc',
            system: system_url
          ).and_return(false)
        )

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:type]).to eq('error')
        expect(result.first[:message]).to(
          match(%r{#{resource.resourceType}/#{resource.id}.*#{binding_definition[:path]}})
        )
        expect(result.first[:message]).to(
          match(/with code `#{system_url}|#{bad_code}` is not in #{binding_definition[:system]}/)
        )
      end
    end

    context 'with a CodeableConcept' do
      let(:resource) do
        FHIR::Observation.new(
          id: '123',
          category: [
            {
              coding: [
                {
                  code: bad_code,
                  system: system_url
                }
              ]
            }
          ]
        )
      end
      let(:binding_definition) do
        {
          type: 'CodeableConcept',
          strength: 'preferred',
          system: 'http://hl7.org/fhir/ValueSet/observation-category',
          path: 'category'
        }
      end

      it 'returns an error message if none of the Codings are valid' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: bad_code,
            system: system_url
          ).and_return(false)
        )

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:type]).to eq('error')
        expect(result.first[:message]).to(
          match(%r{#{resource.resourceType}/#{resource.id}.*#{binding_definition[:path]}})
        )
        expect(result.first[:message]).to(
          match(/with code `#{system_url}|#{bad_code}` is not in #{binding_definition[:system]}/)
        )
      end

      it 'does not return an error message if any of the Codings are valid' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: bad_code,
            system: system_url
          ).and_return(false)
        )
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: good_code,
            system: system_url
          ).and_return(true)
        )

        resource.category.first.coding << FHIR::Coding.new(code: good_code, system: system_url)

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(0)
      end
    end

    context 'with extensions' do
      let(:resource) do
        FHIR::Patient.new(
          id: '123',
          extension: [
            {
              url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
              extension: [
                {
                  url: 'ombCategory',
                  valueCoding: {
                    code: bad_code,
                    system: system_url
                  }
                }
              ]
            }
          ]
        )
      end
      let(:binding_definition) do
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/omb-race-category',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
            'ombCategory'
          ]
        }
      end

      it 'returns an error message if a code is invalid' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: bad_code,
            system: system_url
          ).and_return(false)
        )

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:type]).to eq('error')
        expect(result.first[:message]).to(
          match(%r{#{resource.resourceType}/#{resource.id}.*#{binding_definition[:path]}})
        )
        expect(result.first[:message]).to(
          match(/with code `#{system_url}|#{bad_code}` is not in #{binding_definition[:system]}/)
        )
      end
    end

    context 'with required binding slicing' do
      let(:binding_definition) do
        {
          type: 'CodeableConcept',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-problem-or-health-concern',
          path: 'category',
          required_binding_slice: true
        }
      end

      let(:resource) do
        FHIR::Condition.new(
          id: '123',
          category: [
            {
              coding: [
                {
                  system: system_url,
                  code: good_code
                }
              ]
            },
            {
              coding: [
                {
                  system: system_url,
                  code: bad_code
                }
              ]
            }
          ]
        )
      end

      before do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: good_code,
            system: system_url
          ).and_return(true)
        )
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: bad_code,
            system: system_url
          ).and_return(false)
        )
      end

      it 'passes resource with both required binding code and non required binding code' do
        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(0)
      end

      it 'fails resource with non required binding code only' do
        resource.category.delete_at(0)
        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:message]).to include("does not contain a valid code from #{binding_definition[:system]}.")
      end

      it 'fails resource with both when required_binding_slice is not specified' do
        binding_definition.delete(:required_binding_slice)
        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:message]).to include(
          "with code `#{system_url}|#{bad_code}` is not in #{binding_definition[:system]}."
        )
      end
    end

    context 'with primitive extension' do
      let(:json_obj) do
        {
          resourceType: 'Patient',
          id: '123',
          gender: good_code,
          _gender: {
            extension: [
              {
                url: 'http://hl7.org/fhir/StructureDefinition/alternate-codes',
                valueCodeableConcept: {
                  coding: [
                    {
                      system: 'http://snomed.info/sct',
                      code: '248153007',
                      display: 'Male (finding)'
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      let(:resource) { FHIR.from_contents(json_obj.to_json) }
      let(:binding_definition) do
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/administrative-gender',
          path: 'gender'
        }
      end

      it 'does not return an error message' do
        allow_any_instance_of(described_class).to(
          receive(:validate_code).with(
            value_set_url: binding_definition[:system],
            code: good_code
          ).and_return(true)
        )

        result = described_class.validate(resource, binding_definition)

        expect(result).to be_an(Array)
        expect(result.length).to eq(0)
      end
    end
  end
end
