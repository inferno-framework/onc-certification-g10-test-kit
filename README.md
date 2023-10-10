# ONC Certification (g)(10) Standardized API Test Kit

The **ONC Certification (g)(10) Standardized API Test Kit** is a testing tool
for Health IT systems seeking to meet the requirements of the ONC [Standardized
API for Patient and Population Services criterion §
170.315(g)(10)](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
in the 2015 Edition Cures Update.

The **(g)(10) Standardized API Test Kit** behaves like an API consumer, making a
series of HTTP requests that mimic a real world client to ensure that the API
supports an approved version of each of the required standards:

* Health Level 7 (HL7®) Fast Healthcare Interoperability Resources (FHIR®) (v4.0.1)
* US Core Implementation Guide (v3.1.1, v4.0.0, v5.0.1, or v6.1.0)
* SMART Application Launch Framework Implementation Guide Release (v1.0.0, or
  v2.0.0)
* HL7 FHIR Bulk Data Access (Flat FHIR) (v1.0.1, or v2.0.0)

This test kit is [open source](#license) and freely available for use or
adoption by the health IT community including EHR vendors, health app
developers, and testing labs. It is an approved test method for the §
170.315(g)(10) certification criterion in the EHR Certification program by the
Office of the National Coordinator for Health IT (ONC).

The (g)(10) Standarized API Test Kit is built using the [Inferno
Framework](https://inferno-framework.github.io/).  The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

## Getting Started

ONC hosts a [public
instance](https://inferno.healthit.gov/suites/g10_certification) of this test
kit that developers and testers are welcome to use.  However, users are
encouraged to download and run this tool locally to allow testing within private
networks and to avoid being affected by downtime of this shared resource.
Please see the [Local Installation
Instructions](#local-installation-instructions) section below for more
information.

ONC hosts a [(g)(10) reference
server](https://inferno.healthit.gov/reference-server/) that can be used to
orient new users on these tests.  The [(g)(10) Standardized API Test Kit
Walkthrough](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/Walkthrough)
provides step-by-step instructions for running these tests against the reference
server.  This reference server is not a complete implementation and cannot be
used for production use.

## Reporting Issues

Please report any issues with this set of tests in the [GitHub
Issues](https://github.com/onc-healthit/onc-certification-g10-test-kit/issues)
section of this repository.  Common questions and answers are documented in the
[(g)(10) Test Kit Frequently Asked
Questions](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/FAQ).

## Local Installation Instructions

- [Download an official
  release](https://github.com/onc-healthit/onc-certification-g10-test-kit/releases)
- run `setup.sh`
- run `run.sh`
- navigate to `http://localhost`

### Multi-user Installations

The default configuration of this test kit uses SQLite for data persistence and
is optimized for running on a local machine with a single user.  For
installations on shared servers that may have multiple tests running
simultaniously, please [configure the installation to use
PostgreSQL](https://inferno-framework.github.io/inferno-core/deployment/database.html#postgresql)
to ensure stability in this type of environment.

### Terminology Support
#### Terminology prerequisites

In order to validate terminologies, Inferno must be loaded with files generated
from the Unified Medical Language System (UMLS).  The UMLS is distributed by the
National Library of Medicine (NLM) and requires an account to access.

Inferno provides some rake tasks which may make this process easier, as well as
a Dockerfile and docker-compose file that will create the validators in a
self-contained environment.

Prerequisites:

* A UMLS account
* A working Docker toolchain, which has been assigned at least 10GB of RAM (The
  Metathesaurus step requires 8GB of RAM for the Java process)
  * Note: the Docker terminology process will not run unless Docker has access
    to at least 10GB of RAM.
* At least 40 GB of free disk space on the Host OS, for
  downloading/unzipping/processing the terminology files.
  * Note: this space needs to be allocated on the host because Docker maps these
    files through to the Host, to allow for building in the dedicated
    terminology container.
* A copy of the Inferno repository, which contains the required Docker and Ruby
  files
* Run `setup.sh` to initialize Inferno's database

Once you have a UMLS account, you will have to add your UMLS API key to a file
named `.env` at the root of the inferno project. This API key is used to
authenticate the user to download the UMLS zip files. To find your UMLS API key,
sign into [the UTS homepage](https://uts.nlm.nih.gov/uts/), click on `My
Profile` in the top right, and copy the `API KEY` value from the `UMLS Licensee
Profile`.

The relevant entries in the `.env` file should look like this (replacing
`your_api_key` with your UMLS API key):

```shell
UMLS_API_KEY=your_api_key
CLEANUP=true
```

Note that _anything_ after the equals sign in `.env` will be considered part of
the variable, so don't wrap your API key in quotation marks.

Optionally: you can add a second environment variable, named `CLEANUP` and set
to `true`, to that same file. This tells the build system to delete the "build
files"--everything except for the finished databases--after the build.

Once that file exists, you can run the terminology creation task by using the
following command:

```shell
docker-compose -f terminology_compose.yml up --build
```

This will run the terminology creation steps in order. These tasks may take
several hours. If the creation task is cancelled in progress and restarted, it
will restart after the last _completed_ step. Intermediate files are saved to
`tmp/terminology` in the Inferno repository that the Docker Compose job is run
from, and the validators are saved to `resources/terminology/validators/bloom`,
where Inferno can use them for validation.

#### Cleanup

Once the terminology building is done, you should remove your UMLS API key from
the system.

Optionally, the files and folders in `tmp/terminology/` can be deleted after
terminology building to free up space, as they are several GB in size. If you
intend to re-run the terminology builder, these files can be left to speed up
building in the future, since the builder will be able to skip the initial
download/preprocessing steps.

#### Verifying a Successful Terminology Build

The following rake task will check that the built terminology contains the
expected number of codes for each system:

```shell
bundle exec rake terminology:check_built_terminology
```

#### Spot Checking the Terminology Files

You can use the following `rake` command to spot check the validators to make
sure they are installed correctly:

```shell
bundle exec rake "terminology:check_code[91935009,http://snomed.info/sct, http://hl7.org/fhir/us/core/ValueSet/us-core-allergy-substance]"
```

Should return:

```
X http://snomed.info/sct|91935009  is not in http://hl7.org/fhir/us/core/ValueSet/us-core-allergy-substance
```

And

```shell
bundle exec rake "terminology:check_code[91935009,http://snomed.info/sct]"
```

Should return:

```
✓ http://snomed.info/sct|91935009  is in http://snomed.info/sct
```

#### Restricting access to CodeSystems based on licensing terms

Running instances of Inferno can be configured to exclude terminology validation
for codes based on applicable categories of additional restrictions, as defined
by the [UMLS license
agreement](https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/release/license_agreement.html).

By default, Inferno will not restrict validation of codes. To configure an
instance of Inferno to exclude certain CodeSystems for validation, rename the
`resources/terminology/terminology_config.yml.example` to
`terminology_config.yml`, and update the file based on the example content.
Inferno will provide an informational message on the landing page that describes
which CodeSystems will not be validated in this running instance based on this
configuration file.  If Inferno tests receive a code from an excluded
CodeSystem, a warning indicating that Inferno cannot validate the code will be
provided along with the test result.

#### Manual build instructions

**TODO:** Update this section

If this Docker-based method does not work based on your architecture, manual
setup and creation of the terminology validators is documented [on this wiki
page](https://github.com/onc-healthit/inferno/wiki/Installing-Terminology-Validators#building-the-validators-without-docker)

#### UMLS Data Sources

Some material in the UMLS Metathesaurus is from copyrighted sources of the
respective copyright holders. Users of the UMLS Metathesaurus are solely
responsible for compliance with any copyright, patent or trademark restrictions
and are referred to the copyright, patent or trademark notices appearing in the
original sources, all of which are hereby incorporated by reference.

      Bodenreider O. The Unified Medical Language System (UMLS): integrating biomedical terminology.
      Nucleic Acids Res. 2004 Jan 1;32(Database issue):D267-70. doi: 10.1093/nar/gkh061.
      PubMed PMID: 14681409; PubMed Central PMCID: PMC308795.

## License
Copyright 2022 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
